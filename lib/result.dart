import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'History.dart';

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

  Future<void> _saveData(String email, String foodName, String sugarLevel) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Get the current data map or initialize it
      final dataMapString = prefs.getString(userFoodDataKey);
      final Map<String, dynamic> dataMap =
      dataMapString != null ? json.decode(dataMapString) : {};

      // Retrieve or initialize the list for the current user
      final List<dynamic> userList = dataMap[email] ?? [];
      final List<FoodSugarEntry> userEntries = userList
          .map((e) => FoodSugarEntry.fromMap(e as Map<String, dynamic>))
          .toList();

      // Add the new entry
      userEntries.insert(0, FoodSugarEntry(foodName: foodName, sugarLevel: sugarLevel));

      // Limit to 10 entries per user
      if (userEntries.length > 10) {
        userEntries.removeLast();
      }

      // Update the map and save it back to SharedPreferences
      dataMap[email] = userEntries.map((e) => e.toMap()).toList();
      await prefs.setString(userFoodDataKey, json.encode(dataMap));

      debugPrint('Data saved for $email: $foodName, $sugarLevel');
    } catch (e) {
      debugPrint('Error saving data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        title: Text('Result'),
        backgroundColor: Colors.purple,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Food: ${widget.foodName}',
              style: TextStyle(fontSize: 24, color: Colors.white),
            ),
            SizedBox(height: 20),
            Text(
              'Sugar Level: ${widget.sugarLevel}',
              style: TextStyle(fontSize: 24, color: Colors.white),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Navigate to History screen to view saved data
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => History(),
                  ),
                );
              },
              child: Text('View History'),
            ),
            const SizedBox(height: 16),
            Text(
              "Logged in as: ${user?.email ?? 'Unknown'}",
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}