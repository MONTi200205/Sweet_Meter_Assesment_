import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'History.dart';
import 'home_screen.dart';
import 'package:sweet_meter_assesment/utils/Darkmode.dart';

class FoodSugarEntry {
  final String foodName;
  final String sugarLevel;

  FoodSugarEntry({required this.foodName, required this.sugarLevel});

  // Convert the object to a map for JSON serialization
  Map<String, dynamic> toMap() {
    return {'foodName': foodName, 'sugarLevel': sugarLevel};
  }

  // Convert a map to a FoodSugarEntry object
  factory FoodSugarEntry.fromMap(Map<String, dynamic> map) {
    return FoodSugarEntry(
      foodName: map['foodName'],
      sugarLevel: map['sugarLevel'],
    );
  }
}

class Result extends StatefulWidget {
  final String foodName;
  final String sugarLevel;

  Result({required this.foodName, required this.sugarLevel});

  @override
  _ResultState createState() => _ResultState();
}

class _ResultState extends State<Result> {
  static const String userFoodDataKey = 'userFoodData';

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _saveData(user.email!, widget.foodName, widget.sugarLevel);
    }
  }

  /// Save Data Locally & Sync to Firestore
  Future<void> _saveData(String email, String foodName, String sugarLevel) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userDataMap = await _syncWithFirestore(email);

      // Load existing local data
      final dataMapString = prefs.getString(userFoodDataKey);
      final Map<String, dynamic> dataMap = dataMapString != null ? json.decode(dataMapString) : {};

      // Retrieve or initialize the user's data list from local storage or Firestore
      final List<dynamic> userList = dataMap[email] ?? userDataMap[email] ?? [];
      final List<FoodSugarEntry> userEntries = userList
          .map((e) => FoodSugarEntry.fromMap(e as Map<String, dynamic>))
          .toList();

      // Add new entry
      userEntries.insert(0, FoodSugarEntry(foodName: foodName, sugarLevel: sugarLevel));

      // Limit to 10 entries per user
      if (userEntries.length > 10) {
        userEntries.removeLast();
      }

      // Save updated list to local storage
      dataMap[email] = userEntries.map((e) => e.toMap()).toList();
      await prefs.setString(userFoodDataKey, json.encode(dataMap));

      debugPrint('✅ Data saved locally for $email');

      // 🔥 Upload updated data to Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(email)
          .set({'foodEntries': userEntries.map((e) => e.toMap()).toList()});

      debugPrint('✅ Data uploaded to Firestore for $email');
    } catch (e) {
      debugPrint('❌ Error saving data: $e');
    }
  }

  /// Fetch data from Firestore & return it for merging
  Future<Map<String, dynamic>> _syncWithFirestore(String email) async {
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(email).get();
      if (doc.exists) {
        final data = doc.data();
        if (data != null && data.containsKey('foodEntries')) {
          final List<dynamic> cloudEntries = data['foodEntries'];
          return {email: cloudEntries};
        }
      }
    } catch (e) {
      debugPrint('❌ Error syncing with Firestore: $e');
    }
    return {};
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    final user = FirebaseAuth.instance.currentUser;

    return Stack(
      children: [
        // Background Color
        Container(
          width: double.infinity,
          height: double.infinity,
          color: Background(context),
        ),

        // Background Image Overlay
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
          appBar: AppBar(
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: IconColor(context)),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.home, color: IconColor(context)),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => HomeScreen()),
                  );
                },
              ),
            ],
            backgroundColor: Colors.transparent,
          ),
          body: isLandscape
              ? _buildLandscapeLayout(context, size, user)
              : _buildPortraitLayout(context, size, user),
        ),
      ],
    );
  }

  Widget _buildPortraitLayout(BuildContext context, Size size, User? user) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: size.width * 0.05),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Text(
            'Results',
            style: TextStyle(fontSize: size.width * 0.06, color: Colors.purple),
          ),
          Divider(color: Colors.purple, thickness: 1),
          SizedBox(height: size.height * 0.1),
          Text(
            'Food: ${widget.foodName}',
            style: TextStyle(fontSize: size.width * 0.06, color: BlackText(context)),
          ),
          SizedBox(height: size.height * 0.02),
          Text(
            'Sugar Level: \n${widget.sugarLevel}',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: size.width * 0.06, color: BlackText(context)),
          ),
          SizedBox(height: size.height * 0.02),
          ElevatedButton(
            onPressed: () {
              // Navigate to History screen
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => History(),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              padding: EdgeInsets.symmetric(
                horizontal: size.width * 0.1,
                vertical: size.height * 0.015,
              ),
            ),
            child: Text(
              'View History',
              style: TextStyle(fontSize: size.width * 0.04, color: Colors.white),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "Logged in as: ${user?.email ?? 'Unknown'}",
            style: TextStyle(fontSize: size.width * 0.03, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildLandscapeLayout(BuildContext context, Size size, User? user) {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(size.width * 0.03),
        child: Column(
          children: [
            // Title and divider
            Text(
              'Results',
              style: TextStyle(fontSize: size.width * 0.04, color: Colors.purple),
            ),
            Divider(color: Colors.purple, thickness: 1),
            SizedBox(height: size.height * 0.02),

            // Content in row layout
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Left side - Food info
                Expanded(
                  child: Container(
                    padding: EdgeInsets.all(size.width * 0.02),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Food:',
                          style: TextStyle(
                            fontSize: size.width * 0.03,
                            color: BlackText(context),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: size.height * 0.01),
                        Text(
                          widget.foodName,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: size.width * 0.04,
                            color: BlackText(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(width: size.width * 0.03),

                // Right side - Sugar level
                Expanded(
                  child: Container(
                    padding: EdgeInsets.all(size.width * 0.02),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Sugar Level:',
                          style: TextStyle(
                            fontSize: size.width * 0.03,
                            color: BlackText(context),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: size.height * 0.01),
                        Text(
                          widget.sugarLevel,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: size.width * 0.04,
                            color: BlackText(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: size.height * 0.05),

            // Button and user info
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => History()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                padding: EdgeInsets.symmetric(
                  horizontal: size.width * 0.05,
                  vertical: size.height * 0.02,
                ),
              ),
              child: Text(
                'View History',
                style: TextStyle(fontSize: size.width * 0.025, color: Colors.white),
              ),
            ),
            SizedBox(height: size.height * 0.02),
            Text(
              "Logged in as: ${user?.email ?? 'Unknown'}",
              style: TextStyle(fontSize: size.width * 0.02, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}