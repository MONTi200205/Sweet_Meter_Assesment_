import 'package:flutter/material.dart';
import 'History.dart';
import 'ScanOrTypeScreen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'Menu.dart';
import 'package:sweet_meter_assesment/utils/Darkmode.dart';
import 'OpenAi.dart';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'quotemanager.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:battery_plus/battery_plus.dart';
import 'dart:async';
import 'package:sweet_meter_assesment/utils/scaling_utils.dart';
import 'dart:math';
import 'daily_sugar.dart';

// Global variables for user profile data
String? userProfileImageUrl;
String currentUserEmail = FirebaseAuth.instance.currentUser?.email ?? '';

// Retrieves the most recent food entry from SharedPreferences for the current user
Future<Map<String, String>?> getLatestFoodEntry() async {
  final prefs = await SharedPreferences.getInstance();
  final dataMapString = prefs.getString('userFoodData');
  if (dataMapString == null) return null;

  final Map<String, dynamic> dataMap = json.decode(dataMapString);
  final email = FirebaseAuth.instance.currentUser?.email;

  if (email != null && dataMap.containsKey(email)) {
    final userFoodHistory = dataMap[email];
    if (userFoodHistory != null && userFoodHistory.isNotEmpty) {
      final latestEntry = userFoodHistory.first; // Get the most recent entry
      return {
        'foodName': latestEntry['foodName'] ?? 'Unknown',
        'sugarLevel': latestEntry['sugarLevel'] ?? '0%'
      };
    }
  }

  return null; // Return null if no entry is found
}

// Extracts the numeric percentage value from a sugar level string
double _extractPercentage(String sugarLevel) {
  final regex = RegExp(r'(\d+\.?\d*)');
  final match = regex.firstMatch(sugarLevel);
  if (match != null) {
    return double.tryParse(match.group(0) ?? '0') ?? 0;
  }
  return 0;
}

// Returns appropriate color based on sugar percentage level
Color _getColorForPercentage(double percentage) {
  if (percentage >= 0 && percentage <= 25) {
    return Colors.green; // Green for 0-25%
  } else if (percentage > 25 && percentage <= 50) {
    return Colors.orange; // Orange for 25-50%
  } else if (percentage > 50 && percentage <= 75) {
    return Colors.pinkAccent; // Light red for 50-75%
  } else {
    return Colors.red; // Dark red for 75-100%
  }
}

class HomeScreen extends StatefulWidget {
  HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final GlobalKey _menuKey = GlobalKey();
  String currentQuote = "";
  late QuoteManager _quoteManager;
  final OpenAIService _openAIService = OpenAIService();

  // State variables for food entry data
  Map<String, String>? latestFoodEntry;
  bool isLoadingFoodEntry = true;
  String? foodEntryError;

  // Sugar percentage visualization data
  double? sugarPercentage;
  Color? sugarColor;

  // Syncs food data from Firestore if local data is not available
  Future<void> _syncFoodDataFromFirestore() async {
    try {
      final email = FirebaseAuth.instance.currentUser?.email;
      if (email == null) return;

      // Get data from Firestore
      final doc =
      await FirebaseFirestore.instance.collection('users').doc(email).get();
      if (!doc.exists) return;

      final data = doc.data();
      if (data == null || !data.containsKey('foodEntries')) return;

      // Get local data
      final prefs = await SharedPreferences.getInstance();
      final dataMapString = prefs.getString('userFoodData');
      final Map<String, dynamic> dataMap =
      dataMapString != null ? json.decode(dataMapString) : {};

      // Skip if we already have local data for this user
      if (dataMap.containsKey(email) &&
          dataMap[email] is List &&
          dataMap[email].isNotEmpty) {
        return;
      }

      // If no local data, use Firestore data
      final List<dynamic> cloudEntries = data['foodEntries'];
      dataMap[email] = cloudEntries;

      // Save to SharedPreferences
      await prefs.setString('userFoodData', json.encode(dataMap));

      // Refresh UI with latest entry
      if (mounted) {
        _loadLatestFoodEntry();
      }

      print('✅ Initial data sync completed from Firestore for $email');
    } catch (e) {
      print('❌ Error during initial data sync: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _initPowerSavingDetection();
    _loadQuotes();
    loadUserProfile(currentUserEmail);

    // First sync with Firestore, then load the latest entry
    _syncFoodDataFromFirestore().then((_) {
      _loadLatestFoodEntry();
    });

    // Load scaling preference
    loadScalePreference().then((value) {
      if (mounted) {
        setState(() {
          globalScaleFactor = value;
        });
      }
    });
  }

  // Refresh data when app resumes from background
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadLatestFoodEntry();
    }
  }

  // Loads the latest food entry data and updates UI state
  Future<void> _loadLatestFoodEntry() async {
    if (!mounted) return;

    setState(() {
      isLoadingFoodEntry = true;
      foodEntryError = null;
    });

    try {
      final entry = await getLatestFoodEntry();

      if (mounted) {
        setState(() {
          latestFoodEntry = entry;
          isLoadingFoodEntry = false;

          // Calculate sugar percentage and color for visualization
          if (entry != null) {
            sugarPercentage = _extractPercentage(entry['sugarLevel'] ?? '0%');
            sugarColor = _getColorForPercentage(sugarPercentage!);
          }
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          foodEntryError = error.toString();
          isLoadingFoodEntry = false;
        });
      }
    }
  }

  final Battery _battery = Battery();
  StreamSubscription<BatteryState>? _batteryStateSubscription;

  // Loads user profile data including profile picture
  Future<void> loadUserProfile(String email) async {
    try {
      final userDoc =
      await FirebaseFirestore.instance.collection('users').doc(email).get();

      if (userDoc.exists && userDoc.data()!.containsKey('profilePictureUrl')) {
        if (mounted) {
          setState(() {
            userProfileImageUrl = userDoc.data()!['profilePictureUrl'];
          });
        }
      }
    } catch (e) {
      print('Error loading user profile: $e');
    }
  }

  // Initializes and loads motivational quotes
  Future<void> _loadQuotes() async {
    // Initialize QuoteManager with callback
    _quoteManager = QuoteManager(onQuoteChanged: (quote) {
      if (mounted) {
        setState(() {
          currentQuote = quote;
        });
      }
    });

    // Check battery state and pause in power save mode
    bool isInPowerSaveMode = await _battery.isInBatterySaveMode;
    if (isInPowerSaveMode) {
      _quoteManager.pause();
      return;
    }

    // Load quotes from OpenAI service or generate new ones if needed
    List<String> savedQuotes = await _openAIService.getSavedQuotes();
    if (savedQuotes.isEmpty) {
      if (mounted) {
        setState(() {
          currentQuote = "Loading quotes...";
        });
      }

      // Generate new quotes if none exist
      String result = await _openAIService.generateAndSaveQuotes(10);
      savedQuotes = await _openAIService.getSavedQuotes();
    }

    // Load quotes into the manager and update display
    _quoteManager.loadQuotes(savedQuotes);
    _quoteManager.forceQuoteUpdate();
  }

  // Clears and regenerates motivational quotes
  Future<void> _clearSavedQuotes() async {
    await _quoteManager.clearSavedQuotes();
    setState(() {
      currentQuote = "All saved quotes have been removed.";
    });

    String result = await _openAIService.generateAndSaveQuotes(10);
    List<String> newQuotes = await _openAIService.getSavedQuotes();

    setState(() {
      _quoteManager.loadQuotes(newQuotes);
    });
  }

  // Sets up battery state monitoring for power saving features
  void _initPowerSavingDetection() async {
    // Get initial power save mode state
    bool isInPowerSaveMode = await _battery.isInBatterySaveMode;
    _handlePowerSavingModeChanged(isInPowerSaveMode);

    // Listen for changes to power save mode
    _batteryStateSubscription =
        _battery.onBatteryStateChanged.listen((_) async {
          bool newPowerSaveMode = await _battery.isInBatterySaveMode;
          _handlePowerSavingModeChanged(newPowerSaveMode);
        });
  }

  // Handles changes to power saving mode
  void _handlePowerSavingModeChanged(bool isInPowerSaveMode) {
    if (mounted) {
      setState(() {
        if (isInPowerSaveMode) {
          if (_quoteManager != null) {
            _quoteManager.pause();
          }
        } else {
          if (_quoteManager != null) {
            _quoteManager.resume();
          }
        }
      });
    }
  }

  @override
  void dispose() {
    // Clean up resources
    WidgetsBinding.instance.removeObserver(this);
    _quoteManager.stop();
    _batteryStateSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final screenWidth = size.width;
    final screenHeight = size.height;
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return Stack(
      children: [
        // Background color
        Container(
          width: double.infinity,
          height: double.infinity,
          color: Background(context),
        ),
        // Background image with overlay
        Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage("assets/Background.png"),
              fit: BoxFit.cover,
              colorFilter: ColorFilter.mode(
                Colors.black.withOpacity(0.3),
                BlendMode.darken,
              ),
            ),
          ),
        ),

        // Main UI content
        Scaffold(
          backgroundColor: Colors.transparent,
          appBar: PreferredSize(
            preferredSize: Size.fromHeight(screenHeight * 0.1),
            child: Container(
              padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
              decoration: BoxDecoration(
                color: Colors.purple,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 6.0,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Menu button
                  IconButton(
                    icon: Icon(Icons.menu, color: IconColor(context)),
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (context) => Container(
                          height: MediaQuery.of(context).size.height * 0.85,
                          child: MenuScreen(
                            onProfileUpdated: (String url) {
                              setState(() {
                                userProfileImageUrl = url;
                              });
                            },
                          ),
                        ),
                      );
                    },
                  ),
                  // App title
                  Text(
                    "SWEET METER",
                    style: TextStyle(
                      fontFamily: 'Agbalumo',
                      fontSize: isLandscape
                          ? screenHeight * 0.05
                          : screenWidth * 0.06,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  // User profile picture
                  Container(
                    margin: EdgeInsets.only(right: screenWidth * 0.02),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: IconColor(context),
                        width: 2.0,
                      ),
                    ),
                    child: CircleAvatar(
                      backgroundImage: userProfileImageUrl != null
                          ? NetworkImage(userProfileImageUrl!)
                          : AssetImage('assets/profile_image.png')
                      as ImageProvider,
                      radius: isLandscape
                          ? screenHeight * 0.04
                          : screenWidth * 0.045,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Responsive layout based on orientation
          body: isLandscape
              ? _buildLandscapeLayout(context, size)
              : _buildPortraitLayout(context, size),
        ),
      ],
    );
  }

  // Portrait layout UI builder
  Widget _buildPortraitLayout(BuildContext context, Size size) {
    final screenWidth = size.width;
    final screenHeight = size.height;

    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(scaled(screenWidth * 0.04)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: scaled(screenHeight * 0.06)),

            // Latest Measurements Card
            GestureDetector(
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => History()),
                );
                // Refresh data when returning from History screen
                _loadLatestFoodEntry();
              },
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.fromLTRB(
                  scaled(screenWidth * 0.05),
                  scaled(screenWidth * 0.05),
                  scaled(screenWidth * 0.05),
                  scaled(screenWidth * 0.05 + 20),
                ),
                decoration: BoxDecoration(
                  color: BackgroundAppBar(context),
                  borderRadius:
                  BorderRadius.circular(scaled(screenWidth * 0.03)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.3),
                      blurRadius: scaled(screenWidth * 0.02),
                      offset: Offset(0, scaled(screenWidth * 0.01)),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "Latest Measurements",
                            style: TextStyle(
                              fontSize: scaled(screenWidth * 0.045),
                              fontWeight: FontWeight.bold,
                              color: Colors.purple,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: scaled(screenHeight * 0.01)),

                          // Food entry content section
                          if (isLoadingFoodEntry)
                            Container(
                              height: scaled(screenHeight * 0.08),
                              alignment: Alignment.center,
                              child: CircularProgressIndicator(),
                            )
                          else if (foodEntryError != null)
                            Container(
                              height: scaled(screenHeight * 0.08),
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Error: $foodEntryError',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            )
                          else if (latestFoodEntry != null)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    latestFoodEntry!['foodName'] ?? "Unknown",
                                    style: TextStyle(
                                      fontSize: scaled(screenWidth * 0.07),
                                      fontWeight: FontWeight.bold,
                                      color: BlackText(context),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  SizedBox(height: scaled(screenHeight * 0.005)),
                                  Text(
                                    "Sugar Content:",
                                    style: TextStyle(
                                      fontSize: scaled(screenWidth * 0.04),
                                      color: BlackText(context).withOpacity(0.54),
                                    ),
                                  ),
                                ],
                              )
                            else
                              Container(
                                height: scaled(screenHeight * 0.08),
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  "No history available",
                                  style: TextStyle(
                                    fontSize: scaled(screenWidth * 0.04),
                                    fontStyle: FontStyle.italic,
                                    color: BlackText(context).withOpacity(0.5),
                                  ),
                                ),
                              ),
                        ],
                      ),
                    ),

                    // Sugar percentage visualization
                    Container(
                      width: screenWidth * 0.25,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          if (!isLoadingFoodEntry &&
                              foodEntryError == null &&
                              latestFoodEntry != null &&
                              sugarPercentage != null)
                            Text(
                              "${sugarPercentage!.toStringAsFixed(1)}%",
                              style: TextStyle(
                                fontSize: scaled(screenWidth * 0.055),
                                fontWeight: FontWeight.bold,
                                color: sugarColor,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          if (!isLoadingFoodEntry &&
                              foodEntryError == null &&
                              latestFoodEntry != null &&
                              sugarPercentage != null)
                            Container(
                              margin: EdgeInsets.only(
                                  top: scaled(screenHeight * 0.005)),
                              width: scaled(screenWidth * 0.1),
                              height: scaled(screenWidth * 0.1),
                              child: CircularProgressIndicator(
                                value: sugarPercentage! / 100,
                                strokeWidth: scaled(screenWidth * 0.01),
                                backgroundColor: BlackText(context).withOpacity(0.3),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    sugarColor ?? Colors.purple),
                              ),
                            ),
                          if (isLoadingFoodEntry) CircularProgressIndicator(),
                          if (foodEntryError != null)
                            Text(
                              'Error',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          if (latestFoodEntry == null ||
                              sugarPercentage == null)
                            Text(
                              "No data",
                              style: TextStyle(
                                  color: BlackText(context)
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: scaled(screenHeight * 0.03)),

            // Track New Food Button
            Center(
              child: Container(
                width: screenWidth * 0.7,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(scaled(24)),
                  color: Colors.purple,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.purple.withOpacity(0.3),
                      blurRadius: scaled(8),
                      offset: Offset(0, scaled(4)),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => ScanOrTypeScreen()),
                    );
                    // Refresh data when returning
                    _loadLatestFoodEntry();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(scaled(24)),
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: scaled(screenWidth * 0.05),
                      vertical: scaled(screenHeight * 0.02),
                    ),
                  ),
                  child: Text(
                    "Track New Food",
                    style: TextStyle(
                      fontSize: scaled(screenWidth * 0.045),
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),

            SizedBox(height: scaled(screenHeight * 0.03)),

            // Daily Consumption Button
            Center(
              child: Container(
                width: screenWidth * 0.7,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(scaled(24)),
                  color: Colors.purple,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.purple.withOpacity(0.3),
                      blurRadius: scaled(8),
                      offset: Offset(0, scaled(4)),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => DailySugarTracker()),
                    );
                    // Refresh data when returning
                    _loadLatestFoodEntry();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(scaled(24)),
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: scaled(screenWidth * 0.05),
                      vertical: scaled(screenHeight * 0.02),
                    ),
                  ),
                  child: Text(
                    "My Daily consumption",
                    style: TextStyle(
                      fontSize: scaled(screenWidth * 0.045),
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),

            SizedBox(height: scaled(screenHeight * 0.03)),

            // Eat Healthy Section with motivational quotes
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(scaled(16)),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(scaled(12)),
                border: Border.all(
                  color: BlackText(context),
                  width: 1.0,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Eat Healthy",
                        style: TextStyle(
                          fontSize: scaled(screenWidth * 0.045),
                          fontWeight: FontWeight.bold,
                          color: BlackText(context),
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.refresh_rounded,
                          color: BlackText(context),
                          size: scaled(screenWidth * 0.05),
                        ),
                        padding: EdgeInsets.zero,
                        constraints: BoxConstraints(),
                        onPressed: () {
                          _clearSavedQuotes();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text("Quotes cleared successfully!")),
                          );
                        },
                      ),
                    ],
                  ),
                  SizedBox(height: scaled(screenHeight * 0.01)),
                  Container(
                    height: scaled(screenHeight * 0.25),
                    child: SingleChildScrollView(
                      physics: BouncingScrollPhysics(),
                      child: Text(
                        currentQuote,
                        style: TextStyle(
                          fontSize: scaled(screenWidth * 0.04),
                          fontStyle: FontStyle.italic,
                          color: BlackText(context),
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: scaled(16)),
          ],
        ),
      ),
    );
  }

  // Landscape layout UI builder
  Widget _buildLandscapeLayout(BuildContext context, Size size) {
    final screenWidth = size.width;
    final screenHeight = size.height;

    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(scaled(screenWidth * 0.03)),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left Column - Latest Measurements and Button
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: scaled(screenHeight * 0.02)),

                  // Latest Measurements Card
                  GestureDetector(
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => History()),
                        );
                        // Refresh data when returning
                        _loadLatestFoodEntry();
                      },
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.fromLTRB(
                          scaled(screenWidth * 0.03),
                          scaled(screenWidth * 0.03),
                          scaled(screenWidth * 0.03),
                          scaled(screenWidth * 0.03 + 20),
                        ),
                        decoration: BoxDecoration(
                          color: BackgroundAppBar(context),
                          borderRadius:
                          BorderRadius.circular(scaled(screenWidth * 0.02)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.3),
                              blurRadius: scaled(screenWidth * 0.02),
                              offset: Offset(0, scaled(screenWidth * 0.01)),
                            ),
                          ],
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    "Latest Measurements",
                                    style: TextStyle(
                                      fontSize: scaled(screenWidth * 0.02),
                                      fontWeight: FontWeight.bold,
                                      color: Colors.purple,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  SizedBox(height: scaled(screenHeight * 0.01)),

                                  // Food entry data display
                                  if (isLoadingFoodEntry)
                                    Container(
                                      height: scaled(screenHeight * 0.06),
                                      alignment: Alignment.center,
                                      child: CircularProgressIndicator(),
                                    )
                                  else if (foodEntryError != null)
                                    Container(
                                      height: scaled(screenHeight * 0.06),
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        'Error: $foodEntryError',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    )
                                  else if (latestFoodEntry != null)
                                      Column(
                                        crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            latestFoodEntry!['foodName'] ??
                                                "Unknown",
                                            style: TextStyle(
                                              fontSize:
                                              scaled(screenWidth * 0.035),
                                              fontWeight: FontWeight.bold,
                                              color: BlackText(context),
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          SizedBox(
                                              height:
                                              scaled(screenHeight * 0.005)),
                                          Text(
                                            "Sugar Content:",
                                            style: TextStyle(
                                              fontSize:
                                              scaled(screenWidth * 0.02),
                                              color: BlackText(context).withOpacity(0.54),
                                            ),
                                          ),
                                        ],
                                      )
                                    else
                                      Container(
                                        height: scaled(screenHeight * 0.06),
                                        alignment: Alignment.centerLeft,
                                        child: Text(
                                          "No history available",
                                          style: TextStyle(
                                            fontSize: scaled(screenWidth * 0.025),
                                            fontStyle: FontStyle.italic,
                                            color: BlackText(context).withOpacity(0.5),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                ],
                              ),
                            ),

                            // Sugar percentage visualization
                            Container(
                              width: screenWidth * 0.15,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  if (!isLoadingFoodEntry &&
                                      foodEntryError == null &&
                                      latestFoodEntry != null &&
                                      sugarPercentage != null)
                                    Text(
                                      "${sugarPercentage!.toStringAsFixed(1)}%",
                                      style: TextStyle(
                                        fontSize: scaled(screenWidth * 0.025),
                                        fontWeight: FontWeight.bold,
                                        color: sugarColor,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  if (!isLoadingFoodEntry &&
                                      foodEntryError == null &&
                                      latestFoodEntry != null &&
                                      sugarPercentage != null)
                                    Container(
                                      margin: EdgeInsets.only(
                                          top: scaled(screenHeight * 0.005)),
                                      width: scaled(screenWidth * 0.05),
                                      height: scaled(screenWidth * 0.05),
                                      child: CircularProgressIndicator(
                                        value: sugarPercentage! / 100,
                                        strokeWidth: scaled(screenWidth * 0.005),
                                        backgroundColor: BlackText(context).withOpacity(0.3),
                                        valueColor:
                                        AlwaysStoppedAnimation<Color>(
                                            sugarColor ?? Colors.purple),
                                      ),
                                    ),
                                  if (isLoadingFoodEntry)
                                    Container(
                                      height: scaled(screenHeight * 0.04),
                                      width: scaled(screenHeight * 0.04),
                                      child: CircularProgressIndicator(
                                        strokeWidth: scaled(screenWidth * 0.005),
                                      ),
                                    ),
                                  if (foodEntryError != null)
                                    Text(
                                      'Error',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(color: BlackText(context)),
                                    ),
                                  if (latestFoodEntry == null ||
                                      sugarPercentage == null)
                                    Text(
                                      "No data",
                                      style: TextStyle(color: BlackText(context)),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )),

                  SizedBox(height: scaled(screenHeight * 0.08)),

                  // Track New Food Button
                  Center(
                    child: Container(
                      width: (screenWidth / 2) * 0.7,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(scaled(50)),
                        color: Colors.purple,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.purple.withOpacity(0.3),
                            blurRadius: scaled(6),
                            offset: Offset(0, scaled(3)),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => ScanOrTypeScreen()),
                          );
                          // Refresh data when returning
                          _loadLatestFoodEntry();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(scaled(50)),
                          ),
                          padding: EdgeInsets.symmetric(
                            horizontal: scaled(screenWidth * 0.03),
                            vertical: scaled(screenHeight * 0.08),
                          ),
                        ),
                        child: Text(
                          "Track New Food",
                          style: TextStyle(
                            fontSize: scaled(screenWidth * 0.025),
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: scaled(screenHeight * 0.06)),

                  // Daily Sugar Consumption Button
                  Center(
                    child: Container(
                      width: (screenWidth / 2) * 0.7,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(scaled(50)),
                        color: Colors.purple,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.purple.withOpacity(0.3),
                            blurRadius: scaled(6),
                            offset: Offset(0, scaled(3)),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => DailySugarTracker()),
                          );
                          // Refresh data when returning
                          _loadLatestFoodEntry();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(scaled(50)),
                          ),
                          padding: EdgeInsets.symmetric(
                            horizontal: scaled(screenWidth * 0.03),
                            vertical: scaled(screenHeight * 0.08),
                          ),
                        ),
                        child: Text(
                          "My Daily consumption",
                          style: TextStyle(
                            fontSize: scaled(screenWidth * 0.025),
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(width: scaled(screenWidth * 0.02)),

            // Right Column - Eat Healthy Quote
            Expanded(
              child: Container(
                margin: EdgeInsets.only(top: scaled(screenHeight * 0.02)),
                height: screenHeight * 0.75,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(scaled(screenWidth * 0.02)),
                  border: Border.all(
                    color: BlackText(context),
                    width: 1.0,
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.all(scaled(screenWidth * 0.03)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Eat Healthy",
                            style: TextStyle(
                              fontSize: scaled(screenWidth * 0.03),
                              fontWeight: FontWeight.bold,
                              color: BlackText(context),
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.refresh_rounded,
                              color: BlackText(context),
                              size: scaled(screenWidth * 0.03),
                            ),
                            padding: EdgeInsets.zero,
                            constraints: BoxConstraints(),
                            onPressed: () {
                              _clearSavedQuotes();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text("Quotes cleared successfully!")),
                              );
                            },
                          ),
                        ],
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          physics: BouncingScrollPhysics(),
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                                vertical: scaled(screenHeight * 0.03)),
                            child: Text(
                              currentQuote,
                              style: TextStyle(
                                fontSize: scaled(screenWidth * 0.025),
                                fontStyle: FontStyle.italic,
                                color: BlackText(context),
                                height: 1.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}