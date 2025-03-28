import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sweet_meter_assesment/utils/Darkmode.dart';
import 'home_screen.dart';

/// Data model for storing food entries with their sugar information
///
/// Represents a single food item entry with its sugar content data
/// for display in the history screen
class FoodSugarEntry {
  /// Name of the food item
  final String foodName;

  /// Sugar level as a string (e.g., "25%")
  final String sugarLevel;

  /// Creates a new food sugar entry
  ///
  /// @param foodName The name of the food item
  /// @param sugarLevel The sugar level as a string (e.g., "25%")
  FoodSugarEntry({
    required this.foodName,
    required this.sugarLevel
  });

  /// Converts the object to a map for JSON serialization and storage
  ///
  /// @return Map containing the object's properties in key-value format
  Map<String, dynamic> toMap() {
    return {
      'foodName': foodName,
      'sugarLevel': sugarLevel
    };
  }

  /// Creates a FoodSugarEntry object from a map/JSON data
  ///
  /// Used when retrieving data from storage
  ///
  /// @param map Map containing food and sugar data
  /// @return A new FoodSugarEntry instance populated with the map data
  factory FoodSugarEntry.fromMap(Map<String, dynamic> map) {
    return FoodSugarEntry(
      foodName: map['foodName'],
      sugarLevel: map['sugarLevel'],
    );
  }
}

/// Screen for displaying user's food consumption history
///
/// Retrieves and displays the history of food entries with their
/// sugar levels from the local storage (SharedPreferences)
class History extends StatelessWidget {
  /// Retrieves the food history for a specific user
  ///
  /// Fetches stored food entries from SharedPreferences and converts
  /// them to a list of FoodSugarEntry objects
  ///
  /// @param email User's email to identify their data
  /// @return List of FoodSugarEntry objects representing the user's food history
  Future<List<FoodSugarEntry>> getFoodHistory(String email) async {
    // Get instance of SharedPreferences
    final prefs = await SharedPreferences.getInstance();

    // Retrieve JSON string of user food data
    final dataMapString = prefs.getString('userFoodData');
    if (dataMapString == null) return [];

    // Parse JSON string to Map
    final Map<String, dynamic> dataMap = json.decode(dataMapString);

    // Get the specific user's data list
    final List<dynamic>? userList = dataMap[email];

    // If no data exists for this user, return empty list
    if (userList == null) return [];

    // Convert each map in the list to a FoodSugarEntry object
    return userList
        .map((e) => FoodSugarEntry.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    // Get current authenticated user
    final user = FirebaseAuth.instance.currentUser;

    // Handle case where no user is logged in
    if (user == null) {
      return _buildUnauthenticatedView(context);
    }

    // User is authenticated, proceed with showing their history
    final email = user.email!; // Safe to use `!` because null was already handled

    return _buildAuthenticatedView(context, email);
  }

  /// Builds the UI for unauthenticated users
  ///
  /// @param context Current build context
  /// @return Widget showing login message
  Widget _buildUnauthenticatedView(BuildContext context) {
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
          body: Center(
            child: Text(
              'No user logged in. Please log in to view history.',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  /// Builds the UI for authenticated users with their history data
  ///
  /// @param context Current build context
  /// @param email User's email to fetch their history data
  /// @return Widget displaying the user's food history
  Widget _buildAuthenticatedView(BuildContext context, String email) {
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
          backgroundColor: Colors.transparent,
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
            future: getFoodHistory(email), // Fetch food history for the current user

            builder: (context, snapshot) {
              // Show loading indicator while fetching data
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator(color: Colors.purple));
              }

              // Handle errors during data fetch
              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Error: ${snapshot.error}',
                    style: TextStyle(color: Colors.white),
                  ),
                );
              }

              // Data loaded successfully
              if (snapshot.hasData) {
                final foodList = snapshot.data!;

                // Handle empty history
                if (foodList.isEmpty) {
                  return Center(
                    child: Text(
                      'No history available.',
                      style: TextStyle(color: Colors.white),
                    ),
                  );
                }

                // Build list of food entries
                return ListView.builder(
                  itemCount: foodList.length,
                  itemBuilder: (context, index) {
                    final entry = foodList[index];

                    // Each food entry as a list tile
                    return Card(
                      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      color: Colors.white.withOpacity(0.1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(color: Colors.white.withOpacity(0.3)),
                      ),
                      child: ListTile(
                        title: Text(
                          entry.foodName,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          'Sugar Level: ${entry.sugarLevel}',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                          ),
                        ),
                        // Optional: Add an icon to represent the food item
                        leading: Icon(
                          Icons.food_bank_outlined,
                          color: Colors.purple,
                        ),
                      ),
                    );
                  },
                );
              }

              // Fallback for unexpected state
              return Center(
                child: Text(
                  'No data available.',
                  style: TextStyle(color: Colors.white),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}