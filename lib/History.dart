import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
      return Scaffold(
        appBar: AppBar(
          title: Text('History'),
          backgroundColor: Colors.purple,
        ),
        body: Center(
          child: Text('No user logged in. Please log in to view history.'),
        ),
      );
    }

    final email = user.email!; // Safe to use `!` because null was already handled

    return Scaffold(
      appBar: AppBar(
        title: Text('History'),
        backgroundColor: Colors.purple,
      ),
      body: FutureBuilder<List<FoodSugarEntry>>(
        future: getFoodHistory(email), // Fetch food history for the current user
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
                  title: Text(entry.foodName),
                  subtitle: Text('Sugar Level: ${entry.sugarLevel}'),
                );
              },
            );
          }

          return Center(child: Text('No data available.'));
        },
      ),
    );
  }
}