import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

  const Result({Key? key, required this.foodName, required this.sugarLevel}) : super(key: key);

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

  // Function to save data in SharedPreferences
  Future<void> _saveData(String email, String foodName, String sugarLevel) async {
    final prefs = await SharedPreferences.getInstance();
    final String key = '$userFoodDataKey-$email';

    List<String> savedEntries = prefs.getStringList(key) ?? [];

    // Create a new entry
    FoodSugarEntry newEntry = FoodSugarEntry(foodName: foodName, sugarLevel: sugarLevel);

    // Append new entry
    savedEntries.add(jsonEncode(newEntry.toMap()));

    // Save updated list
    await prefs.setStringList(key, savedEntries);
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        title: const Text('Result'),
        backgroundColor: Colors.purple,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Food: ${widget.foodName}',
              style: const TextStyle(fontSize: 24, color: Colors.white),
            ),
            const SizedBox(height: 20),
            Text(
              'Sugar Level: ${widget.sugarLevel}',
              style: const TextStyle(fontSize: 24, color: Colors.white),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Navigate to History screen (assuming History screen exists)
                Navigator.pushNamed(context, '/history');
              },
              child: const Text('View History'),
            ),
            const SizedBox(height: 16),
            Text(
              "Logged in as: ${user?.email ?? 'Unknown'}",
              style: const TextStyle(fontSize: 16, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}