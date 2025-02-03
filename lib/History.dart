import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sweet_meter_assesment/utils/Darkmode.dart';
import 'home_screen.dart';

// FoodSugarEntry class definition
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

class History extends StatelessWidget {
  // Fetch food history for the current user
  Future<List<FoodSugarEntry>> getFoodHistory(String email) async {
    final prefs = await SharedPreferences.getInstance();
    final dataMapString = prefs.getString('userFoodData');
    if (dataMapString == null) return [];

    final Map<String, dynamic> dataMap = json.decode(dataMapString);
    final List<dynamic>? userList = dataMap[email];

    if (userList == null) return [];
    return userList
        .map((e) => FoodSugarEntry.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      // Handle the case where the user is not logged in
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
            body: Center(
              child: Text('No user logged in. Please log in to view history.'),
            ),
          ),
        ],
      );
    }

    final email =
        user.email!; // Safe to use `!` because null was already handled

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
          appBar: AppBar(
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: IconColor(context)),
              onPressed: () => Navigator.pop(context),
            ),
            title: Center(
              child: Text(
                'History', // The history text
                style: TextStyle(
                  color: Colors.purple,
                  fontSize: 20, // You can adjust the font size as needed
                  fontWeight: FontWeight.bold,
                ),
              ),
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
          body: FutureBuilder<List<FoodSugarEntry>>(
            future: getFoodHistory(
                email), // Fetch food history for the current user

            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              if (snapshot.hasData) {
                final foodList = snapshot.data!;
                if (foodList.isEmpty) {
                  return Center(child: Text('No history available.'));
                }

                return ListView.builder(
                  itemCount: foodList.length,
                  itemBuilder: (context, index) {
                    final entry = foodList[index];
                    return ListTile(
                      title: Text(
                        entry.foodName,
                        style: TextStyle(
                          color: BlackText(context), // Set color for title
                          fontWeight: FontWeight.bold, // Optional: make title bold
                        ),
                      ),
                      subtitle: Text(
                        'Sugar Level: ${entry.sugarLevel}',
                        style: TextStyle(
                          color: BlackText(context).withOpacity(0.5), // Set color for subtitle (e.g., grey for a subtler look)
                        ),
                      ),
                    );
                  },
                );
              }

              return Center(child: Text('No data available.'));
            },
          ),
        ),
      ],
    );
  }
}
