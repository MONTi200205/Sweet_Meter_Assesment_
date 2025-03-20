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

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey _menuKey = GlobalKey();
  String currentQuote = "";
  late QuoteManager _quoteManager;
  final OpenAIService _openAIService = OpenAIService();


  @override
  void initState() {
    super.initState();
    _initPowerSavingDetection();
    _loadQuotes();
    loadUserProfile(currentUserEmail);
  }
  final Battery _battery = Battery();//see if its power save
  StreamSubscription<BatteryState>? _batteryStateSubscription;
  //  loadUserProfile function here within the state class
  Future<void> loadUserProfile(String email) async {
    try {
      final userDoc =
          await FirebaseFirestore.instance.collection('users').doc(email).get();

      if (userDoc.exists && userDoc.data()!.containsKey('profilePictureUrl')) {
        if (mounted) {
          // Check if widget is still mounted
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
    _quoteManager = QuoteManager(onQuoteChanged: (quote) {
      if (mounted) {
        setState(() {
          currentQuote = quote;
        });
      }
    });

    // Check power saving mode first
    bool isInPowerSaveMode = await _battery.isInBatterySaveMode;
    if (isInPowerSaveMode) {
      _quoteManager.pause();
      return;
    }

    List<String> savedQuotes = await _openAIService.getSavedQuotes();
    if (savedQuotes.isEmpty) {
      String result = await _openAIService.generateAndSaveQuotes(10);
      savedQuotes = await _openAIService.getSavedQuotes();
    }
    _quoteManager.loadQuotes(savedQuotes);
  }

  Future<void> _clearSavedQuotes() async {
    await _quoteManager.clearSavedQuotes(); // Clear existing quotes
    setState(() {
      currentQuote = "All saved quotes have been removed.";
    });

    // Generate new quotes and reload them
    String result = await _openAIService.generateAndSaveQuotes(10);
    List<String> newQuotes = await _openAIService.getSavedQuotes();

    setState(() {
      _quoteManager.loadQuotes(newQuotes);
    });
  }
  void _initPowerSavingDetection() async {
    // Check initial power saving state
    bool isInPowerSaveMode = await _battery.isInBatterySaveMode;
    _handlePowerSavingModeChanged(isInPowerSaveMode);

    // Listen for changes in power saving mode
    _batteryStateSubscription = _battery.onBatteryStateChanged.listen((_) async {
      bool isInPowerSaveMode = await _battery.isInBatterySaveMode;
      _handlePowerSavingModeChanged(isInPowerSaveMode);
    });
  }

  void _handlePowerSavingModeChanged(bool isInPowerSaveMode) {
    if (isInPowerSaveMode) {
      // Device is in power saving mode, pause quote manager
      if (_quoteManager != null) {
        _quoteManager.pause();
      }
    } else {
      // Device exited power saving mode, resume quote manager
      if (_quoteManager != null) {
        _quoteManager.resume();
      }
    }
  }
  @override
  void dispose() {
    _quoteManager.stop();
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
        // Background Color
        Container(
          width: double.infinity,
          height: double.infinity,
          color: Background(context), // Light purple background
        ),

        // Background Image Overlay
        Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage("assets/Background.png"),
              fit: BoxFit.cover, // Cover the entire screen
              colorFilter: ColorFilter.mode(
                Colors.black.withOpacity(0.3), // Adjust the overlay darkness
                BlendMode.darken, // Blends with background color
              ),
            ),
          ),
        ),

        Scaffold(
          backgroundColor: Colors.transparent,
          appBar: PreferredSize(
            preferredSize: Size.fromHeight(screenHeight * 0.1),
            child: Container(
              padding: EdgeInsets.only(top: screenHeight * 0.03),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  SizedBox(height: screenHeight * 0.4),
                  Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
                    child: CircleAvatar(
                      backgroundImage: userProfileImageUrl != null
                          ? NetworkImage(userProfileImageUrl!)
                          : AssetImage('assets/profile_image.png')
                              as ImageProvider,
                      radius: isLandscape
                          ? screenHeight * 0.05
                          : screenWidth * 0.05,
                    ),
                  ),
                  Text(
                    "SWEET METER",
                    style: TextStyle(
                      fontFamily: 'Agbalumo',
                      fontSize: isLandscape
                          ? screenHeight * 0.05
                          : screenWidth * 0.07,
                      fontWeight: FontWeight.bold,
                      color: Colors.purple,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.menu, color: IconColor(context)),
                    key: _menuKey,
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) {
                          return Builder(
                            builder: (context) {
                              // Change this line to pass the callback
                              Menu(_menuKey, onProfileUpdated: (String url) {
                                setState(() {
                                  userProfileImageUrl = url;
                                });
                              }).showMenu(context);
                              return SizedBox.shrink();
                            },
                          );
                        },
                      );
                    },
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
        padding: EdgeInsets.all(screenWidth * 0.04),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Shift everything down
            SizedBox(height: screenHeight * 0.05),

            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => History()),
                );
              },
              child: Container(
                width: double.infinity,
                height:
                    screenHeight * 0.15, // Fixed height based on screen size
                padding: EdgeInsets.all(screenWidth * 0.05),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(screenWidth * 0.03),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.3),
                      blurRadius: screenWidth * 0.02,
                      offset: Offset(0, screenWidth * 0.01),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min, // Use minimal space
                        children: [
                          Text(
                            "Latest Measurements",
                            style: TextStyle(
                              fontSize: screenWidth * 0.045,
                              fontWeight: FontWeight.bold,
                              color: Colors.black54,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis, // Handles overflow
                          ),
                          SizedBox(height: screenHeight * 0.01),
                          Expanded(
                            child: FutureBuilder<Map<String, String>?>(
                              future: getLatestFoodEntry(),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return Center(
                                      child: CircularProgressIndicator());
                                }
                                if (snapshot.hasError) {
                                  return Text(
                                    'Error: ${snapshot.error}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  );
                                }
                                if (snapshot.hasData && snapshot.data != null) {
                                  return Text(
                                    snapshot.data!['foodName'] ?? "Unknown",
                                    style: TextStyle(
                                      fontSize: screenWidth * 0.07,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow
                                        .ellipsis, // Handles overflow
                                  );
                                }
                                return Text("No history available");
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          FutureBuilder<Map<String, String>?>(
                            future: getLatestFoodEntry(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return CircularProgressIndicator();
                              }
                              if (snapshot.hasError) {
                                return Text(
                                  'Error',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                );
                              }
                              if (snapshot.hasData && snapshot.data != null) {
                                double sugarPercentage = _extractPercentage(
                                    snapshot.data!['sugarLevel'] ?? '0');
                                return Column(
                                  mainAxisSize:
                                      MainAxisSize.min, // Use minimal space
                                  children: [
                                    Text(
                                      "$sugarPercentage%",
                                      style: TextStyle(
                                        fontSize: screenWidth * 0.05,
                                        fontWeight: FontWeight.bold,
                                        color: _getColorForPercentage(
                                            sugarPercentage),
                                      ),
                                      maxLines: 1,
                                    ),
                                    SizedBox(height: screenHeight * 0.005),
                                    Icon(
                                      Icons.circle,
                                      color: _getColorForPercentage(
                                          sugarPercentage),
                                      size: screenWidth * 0.12,
                                    ),
                                  ],
                                );
                              }
                              return Text("No data");
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: screenHeight * 0.03),

            // Track New Food Button
            Center(
              child: ElevatedButton(
                onPressed: () {
                  // Navigate to ScanOrTypeScreen
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ScanOrTypeScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  padding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.1,
                    vertical: screenHeight * 0.02,
                  ),
                ),
                child: Text(
                  "Track New Food",
                  style: TextStyle(
                    fontSize: screenWidth * 0.045,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

            SizedBox(height: screenHeight * 0.03),

            // Eat Healthy Section
            SizedBox(height: screenHeight * 0.01),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Eat Healthy,",
                  style: TextStyle(
                    fontSize: screenWidth * 0.045,
                    fontWeight: FontWeight.bold,
                    color: BlackText(context),
                  ),
                ),
                Builder(
                  builder: (context) => IconButton(
                    icon:
                        Icon(Icons.refresh_rounded, color: IconColor(context)),
                    onPressed: () {
                      _clearSavedQuotes();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Quotes cleared successfully!")),
                      );
                    },
                  ),
                ),
              ],
            ),

            SizedBox(height: screenHeight * 0.01),
            Center(
              child: SizedBox(
                width: screenWidth * 0.8,
                height: screenHeight * 0.3,
                child: Center(
                  child: Center(
                    child: Text(
                      currentQuote,
                      style: TextStyle(
                        fontSize: screenWidth * 0.06,
                        fontStyle: FontStyle.italic,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
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
        padding: EdgeInsets.all(screenWidth * 0.03),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left Column - Latest Measurements and Button
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: screenHeight * 0.02),

                  // Latest Measurements Card
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => History()),
                      );
                    },
                    child: Container(
                      width: double.infinity,
                      height: screenHeight *
                          0.60, // Taller height for landscape mode
                      padding: EdgeInsets.all(screenWidth * 0.03),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(screenWidth * 0.02),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.3),
                            blurRadius: screenWidth * 0.02,
                            offset: Offset(0, screenWidth * 0.01),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize:
                                  MainAxisSize.min, // Use minimal space
                              children: [
                                Text(
                                  "Latest Measurements",
                                  style: TextStyle(
                                    fontSize: screenWidth * 0.02,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black54,
                                  ),
                                  maxLines: 1,
                                  overflow:
                                      TextOverflow.ellipsis, // Handles overflow
                                ),
                                SizedBox(height: screenHeight * 0.01),
                                Expanded(
                                  child: FutureBuilder<Map<String, String>?>(
                                    future: getLatestFoodEntry(),
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState ==
                                          ConnectionState.waiting) {
                                        return Center(
                                            child: CircularProgressIndicator());
                                      }
                                      if (snapshot.hasError) {
                                        return Text(
                                          'Error: ${snapshot.error}',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        );
                                      }
                                      if (snapshot.hasData &&
                                          snapshot.data != null) {
                                        return Text(
                                          snapshot.data!['foodName'] ??
                                              "Unknown",
                                          style: TextStyle(
                                            fontSize: screenWidth * 0.035,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow
                                              .ellipsis, // Handles overflow
                                        );
                                      }
                                      return Text(
                                        "No history available",
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment
                                  .center, // Center content vertically
                              mainAxisSize:
                                  MainAxisSize.min, // Use minimal space
                              children: [
                                FutureBuilder<Map<String, String>?>(
                                  future: getLatestFoodEntry(),
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      return CircularProgressIndicator();
                                    }
                                    if (snapshot.hasError) {
                                      return Text(
                                        'Error',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      );
                                    }
                                    if (snapshot.hasData &&
                                        snapshot.data != null) {
                                      double sugarPercentage =
                                          _extractPercentage(
                                              snapshot.data!['sugarLevel'] ??
                                                  '0');
                                      return Column(
                                        mainAxisSize: MainAxisSize
                                            .min, // Use minimal space
                                        children: [
                                          Text(
                                            "$sugarPercentage%",
                                            style: TextStyle(
                                              fontSize: screenWidth * 0.03,
                                              fontWeight: FontWeight.bold,
                                              color: _getColorForPercentage(
                                                  sugarPercentage),
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          SizedBox(
                                              height: screenHeight * 0.005),
                                          Icon(
                                            Icons.circle,
                                            color: _getColorForPercentage(
                                                sugarPercentage),
                                            size: screenWidth * 0.06,
                                          ),
                                        ],
                                      );
                                    }
                                    return Text(
                                      "No data",
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: screenHeight * 0.03),

                  // Track New Food Button
                  Center(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => ScanOrTypeScreen()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        padding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.05,
                          vertical: screenHeight * 0.025,
                        ),
                      ),
                      child: Text(
                        "Track New Food",
                        style: TextStyle(
                          fontSize: screenWidth * 0.025,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(width: screenWidth * 0.02),

            // Right Column - Eat Healthy Quote
            Expanded(
              child: Container(
                margin: EdgeInsets.only(top: screenHeight * 0.02),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(screenWidth * 0.02),
                ),
                child: Padding(
                  padding: EdgeInsets.all(screenWidth * 0.03),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Eat Healthy,",
                            style: TextStyle(
                              fontSize: screenWidth * 0.03,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.refresh_rounded,
                                color: Colors.white),
                            onPressed: () {
                              _clearSavedQuotes();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content:
                                        Text("Quotes cleared successfully!")),
                              );
                            },
                            iconSize: screenWidth * 0.03,
                          ),
                        ],
                      ),
                      SizedBox(height: screenHeight * 0.02),
                      Container(
                        height: screenHeight * 0.4,
                        alignment: Alignment.center,
                        child: SingleChildScrollView(
                          child: Text(
                            currentQuote,
                            style: TextStyle(
                              fontSize: screenWidth * 0.03,
                              fontStyle: FontStyle.italic,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
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
