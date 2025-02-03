import 'package:flutter/material.dart';
import 'History.dart';
import 'ScanOrTypeScreen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'Menu.dart';
import 'package:sweet_meter_assesment/utils/Darkmode.dart';
import 'OpenAi.dart';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';

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
      final latestEntry = userFoodHistory.first;  // Get the most recent entry
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

class HomeScreen extends StatelessWidget {
  HomeScreen({Key? key}) : super(key: key);
  final GlobalKey _menuKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

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
              image:
                  AssetImage("assets/Background.png"),
              fit: BoxFit.cover, // Cover the entire screen
              colorFilter: ColorFilter.mode(
                Colors.black.withOpacity(0.3), // Adjust the overlay darkness
                BlendMode.darken, // Blends with background color
              ),
            ),
          ),
        ),

        Scaffold(
          backgroundColor: Background(context),
          appBar: PreferredSize(
            preferredSize: Size.fromHeight(screenHeight * 0.1),
            child: Container(
              //color: BackgroundAppBar(context),
              padding: EdgeInsets.only(top: screenHeight * 0.03),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  SizedBox(height: screenHeight * 0.4),
                  Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
                    child: CircleAvatar(
                      backgroundImage: AssetImage('assets/profile_image.png'),
                      radius: screenWidth * 0.05,
                    ),
                  ),
                  Text(
                    "SWEET METER",
                    style: TextStyle(
                      fontFamily: 'Agbalumo', // Replace with your font
                      fontSize: screenWidth * 0.07,
                      fontWeight: FontWeight.bold,
                      color: Colors.purple,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.menu, color: IconColor(context)),
                    key: _menuKey,
                    onPressed: () {
                      // Use Builder widget to resolve context properly
                      showDialog(
                        context: context,
                        builder: (context) {
                          return Builder(
                            builder: (context) {
                              Menu(_menuKey).showMenu(
                                  context); // Show the menu when the button is pressed
                              return SizedBox
                                  .shrink(); // Return an empty widget as the builder
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
          body: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(screenWidth * 0.04),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Shift everything down
                  SizedBox(height: screenHeight * 0.05),

                  // Latest Measurements Card (Button)
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => History()),
                      );
                    },
                    child: Container(
                      width: double.infinity,
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
                              children: [
                                Text(
                                  "Latest Measurements",
                                  style: TextStyle(
                                    fontSize: screenWidth * 0.045,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black54,
                                  ),
                                ),
                                SizedBox(height: screenHeight * 0.01),
                                FutureBuilder<Map<String, String>?>(
                                  future: getLatestFoodEntry(),
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState == ConnectionState.waiting) {
                                      return CircularProgressIndicator();
                                    }
                                    if (snapshot.hasError) {
                                      return Text('Error: ${snapshot.error}');
                                    }
                                    if (snapshot.hasData && snapshot.data != null) {
                                      return Text(
                                        snapshot.data!['foodName'] ?? "Unknown",
                                        style: TextStyle(
                                          fontSize: screenWidth * 0.07,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black,
                                        ),
                                      );
                                    }
                                    return Text("No history available");
                                  },
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Column(
                              children: [
                                SizedBox(height: screenHeight * 0.01),
                                FutureBuilder<Map<String, String>?>(
                                  future: getLatestFoodEntry(),
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState == ConnectionState.waiting) {
                                      return CircularProgressIndicator();
                                    }
                                    if (snapshot.hasError) {
                                      return Text('Error: ${snapshot.error}');
                                    }
                                    if (snapshot.hasData && snapshot.data != null) {
                                      double sugarPercentage = _extractPercentage(snapshot.data!['sugarLevel'] ?? '0');
                                      return Column(
                                        children: [
                                          Text(
                                            "$sugarPercentage%",
                                            style: TextStyle(
                                              fontSize: screenWidth * 0.05,
                                              fontWeight: FontWeight.bold,
                                              color: _getColorForPercentage(sugarPercentage),
                                            ),
                                          ),
                                          SizedBox(height: screenHeight * 0.005),
                                          Icon(
                                            Icons.circle,
                                            color: _getColorForPercentage(sugarPercentage),
                                            size: screenWidth * 0.12,
                                          ),
                                        ],
                                      );
                                    }
                                    return Text("No sugar level available");
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
                          MaterialPageRoute(
                              builder: (context) => ScanOrTypeScreen()),
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
                          color:
                              Colors.white, // Changed the text color to white
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: screenHeight * 0.03),

                  // Eat Healthy Section
                  SizedBox(height: screenHeight * 0.01),
                  Text(
                    "Eat Healthy,",
                    style: TextStyle(
                      fontSize: screenWidth * 0.045,
                      fontWeight: FontWeight.bold,
                      color: BlackText(context),
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.01),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
