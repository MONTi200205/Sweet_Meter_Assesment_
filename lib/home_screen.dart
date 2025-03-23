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

// Add global variables here
String? userProfileImageUrl;
String currentUserEmail = FirebaseAuth.instance.currentUser?.email ?? '';

// Function to fetch food history from SharedPreferences
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

// Function to extract the numeric percentage value from the sugar level string
double _extractPercentage(String sugarLevel) {
  final regex = RegExp(
      r'(\d+\.?\d*)'); // Regex to extract numbers (handles integers and decimals)
  final match = regex.firstMatch(sugarLevel);
  if (match != null) {
    return double.tryParse(match.group(0) ?? '0') ??
        0; // Extract and parse the percentage
  }
  return 0;
}

// Function to return the appropriate color based on the percentage
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

  // Add state variables to store the latest food entry data
  Map<String, String>? latestFoodEntry;
  bool isLoadingFoodEntry = true;
  String? foodEntryError;

  // Variables for sugar percentage and color
  double? sugarPercentage;
  Color? sugarColor;

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

      // Check if we already have data locally for this user
      if (dataMap.containsKey(email) &&
          dataMap[email] is List &&
          dataMap[email].isNotEmpty) {
        // We already have local data, don't overwrite
        return;
      }

      // If no local data, use Firestore data
      final List<dynamic> cloudEntries = data['foodEntries'];
      dataMap[email] = cloudEntries;

      // Save to SharedPreferences
      await prefs.setString('userFoodData', json.encode(dataMap));

      // Refresh UI to show the latest entry
      if (mounted) {
        _loadLatestFoodEntry();
      }

      print('✅ Initial data sync completed from Firestore for $email');
    } catch (e) {
      print('❌ Error during initial data sync: $e');
    }
  }

// Modify your initState to call this function when the screen loads
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

  // When app resumes from background, refresh data
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // App came back to foreground, refresh data
      _loadLatestFoodEntry();
    }
  }

  // Load the food entry data once and store in state
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

          // Calculate sugar percentage and color once
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

  // Existing functions stay the same...
  final Battery _battery = Battery();
  StreamSubscription<BatteryState>? _batteryStateSubscription;

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

  Future<void> _loadQuotes() async {
    // Initialize QuoteManager with callback
    _quoteManager = QuoteManager(onQuoteChanged: (quote) {
      if (mounted) {
        setState(() {
          currentQuote = quote;
        });
      }
    });

    // Check battery state first
    bool isInPowerSaveMode = await _battery.isInBatterySaveMode;
    if (isInPowerSaveMode) {
      _quoteManager.pause();
      return;
    }

    // Load quotes from OpenAI service
    List<String> savedQuotes = await _openAIService.getSavedQuotes();
    if (savedQuotes.isEmpty) {
      // Show loading message while generating quotes
      if (mounted) {
        setState(() {
          currentQuote = "Loading quotes...";
        });
      }

      // Generate new quotes if none exist
      String result = await _openAIService.generateAndSaveQuotes(10);
      savedQuotes = await _openAIService.getSavedQuotes();
    }

    // Load quotes into the manager
    _quoteManager.loadQuotes(savedQuotes);

    // Force a quote update to ensure display after login
    _quoteManager.forceQuoteUpdate();
  }

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
    // Clean up observers when disposing
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
        // Background Color & Image Overlay (no change)
        Container(
          width: double.infinity,
          height: double.infinity,
          color: Background(context),
        ),
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

        Scaffold(
          backgroundColor: Colors.transparent,
          // Updated AppBar in HomeScreen's build method
          // Replace this code in your HomeScreen.dart file
// Specifically in the AppBar section of the build method

          // REPLACE THE ENTIRE APPBAR SECTION with this clean implementation:

          appBar: PreferredSize(
            preferredSize: Size.fromHeight(screenHeight * 0.1),
            child: Container(
              padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
              decoration: BoxDecoration(
                color: Colors.purple, // Solid purple to match login screen
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
                  // Simple menu button - no more references to the old Menu class
                  IconButton(
                    icon: Icon(Icons.menu, color: Colors.white),
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
                  Container(
                    margin: EdgeInsets.only(right: screenWidth * 0.02),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
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
          body: isLandscape
              ? _buildLandscapeLayout(context, size)
              : _buildPortraitLayout(context, size),
        ),
      ],
    );
  }

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
              child: // Precise fix for the overflowing Latest Measurements card
// Replace just the relevant portion of the _buildPortraitLayout method

// Inside the GestureDetector that wraps the Latest Measurements card:
                  Container(
                width: double.infinity,
                // Add padding bottom to ensure space for the overflow
                padding: EdgeInsets.fromLTRB(
                  scaled(screenWidth * 0.05),
                  scaled(screenWidth * 0.05),
                  scaled(screenWidth * 0.05),
                  scaled(screenWidth * 0.05 +
                      20), // Add extra 20 pixels to bottom padding
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
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
                  crossAxisAlignment: CrossAxisAlignment.start, // Align to top
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

                          // Content for food name and sugar content label
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
                                    color: Colors.black,
                                  ),
                                  maxLines:
                                      1, // Limit to 1 line to save vertical space
                                  overflow: TextOverflow.ellipsis,
                                ),
                                SizedBox(height: scaled(screenHeight * 0.005)),
                                Text(
                                  "Sugar Content:",
                                  style: TextStyle(
                                    fontSize: scaled(screenWidth * 0.04),
                                    color: Colors.black54,
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
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                    // Percentage indicator section
                    Container(
                      width: screenWidth * 0.25,
                      child: Column(
                        mainAxisSize:
                            MainAxisSize.min, // Use minimum space needed
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
                              width: scaled(screenWidth * 0.1), // Smaller size
                              height: scaled(screenWidth * 0.1), // Smaller size
                              child: CircularProgressIndicator(
                                value: sugarPercentage! / 100,
                                strokeWidth: scaled(
                                    screenWidth * 0.01), // Thinner stroke
                                backgroundColor: Colors.grey.withOpacity(0.3),
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
                            Text("No data"),
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
                    // Refresh data when returning from ScanOrTypeScreen
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

            // Eat Healthy Section (no change needed)
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(scaled(16)),
              decoration: BoxDecoration(
                color: Colors.transparent, // Made transparent
                borderRadius: BorderRadius.circular(scaled(12)),
                border: Border.all(
                  color: Colors.white,
                  width: 1.0, // Tiny white border
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
                          color: Colors.white,
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.refresh_rounded,
                          color: Colors.white,
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
                          fontSize: scaled(screenWidth *
                              0.04), // Slightly smaller to prevent overflow
                          fontStyle: FontStyle.italic,
                          color: Colors.white,
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
                        // Refresh data when returning from History screen
                        _loadLatestFoodEntry();
                      },
                      child: Container(
                        width: double.infinity,
                        // Add extra padding at the bottom to prevent overflow
                        padding: EdgeInsets.fromLTRB(
                          scaled(screenWidth * 0.03),
                          scaled(screenWidth * 0.03),
                          scaled(screenWidth * 0.03),
                          scaled(screenWidth * 0.03 +
                              20), // Add extra 20 pixels to bottom padding
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
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
                          crossAxisAlignment:
                              CrossAxisAlignment.start, // Align to top
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

                                  // Use stored state
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
                                            color: Colors.black,
                                          ),
                                          maxLines:
                                              1, // Limit to 1 line to save space
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
                                            color: Colors.black54,
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
                                          color: Colors.grey,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                ],
                              ),
                            ),

                            // Percentage indicator section - fixed
                            Container(
                              width: screenWidth * 0.15, // Fixed width
                              child: Column(
                                mainAxisSize: MainAxisSize
                                    .min, // Use minimum vertical space
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
                                      width: scaled(screenWidth *
                                          0.05), // Smaller for landscape
                                      height: scaled(screenWidth *
                                          0.05), // Smaller for landscape
                                      child: CircularProgressIndicator(
                                        value: sugarPercentage! / 100,
                                        strokeWidth: scaled(screenWidth *
                                            0.005), // Thinner stroke
                                        backgroundColor:
                                            Colors.grey.withOpacity(0.3),
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
                                        strokeWidth:
                                            scaled(screenWidth * 0.005),
                                      ),
                                    ),
                                  if (foodEntryError != null)
                                    Text(
                                      'Error',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  if (latestFoodEntry == null ||
                                      sugarPercentage == null)
                                    Text("No data"),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )),

                  SizedBox(height: scaled(screenHeight * 0.03)),

                  // Track New Food Button
                  Center(
                    child: Container(
                      width: (screenWidth / 2) * 0.7,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(scaled(20)),
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
                            borderRadius: BorderRadius.circular(scaled(20)),
                          ),
                          padding: EdgeInsets.symmetric(
                            horizontal: scaled(screenWidth * 0.03),
                            vertical: scaled(screenHeight * 0.02),
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
                  color: Colors.transparent,
                  borderRadius:
                      BorderRadius.circular(scaled(screenWidth * 0.02)),
                  border: Border.all(
                    color: Colors.white,
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
                              color: Colors.white,
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.refresh_rounded,
                              color: Colors.white,
                              size: scaled(screenWidth * 0.03),
                            ),
                            padding: EdgeInsets.zero,
                            constraints: BoxConstraints(),
                            onPressed: () {
                              _clearSavedQuotes();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content:
                                        Text("Quotes cleared successfully!")),
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
                                color: Colors.white,
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
