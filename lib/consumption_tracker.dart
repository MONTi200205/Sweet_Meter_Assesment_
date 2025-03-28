import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'utils/Darkmode.dart';
import 'daily_sugar.dart';

/// Data model for storing food entries with their sugar information
///
/// Represents a single food item entry with its sugar content data
/// and optional consumption tracking information
class FoodSugarEntry {
  final String foodName; // Name of the food item
  final String sugarLevel; // Sugar level as a string (e.g., "25%")
  final double? amountConsumed; // Optional amount consumed in grams
  final double?
      calculatedSugar; // Optional calculated sugar based on consumption

  FoodSugarEntry({
    required this.foodName,
    required this.sugarLevel,
    this.amountConsumed,
    this.calculatedSugar,
  });

  /// Converts the object to a map for JSON serialization and database storage
  Map<String, dynamic> toMap() {
    return {
      'foodName': foodName,
      'sugarLevel': sugarLevel,
      'amountConsumed': amountConsumed,
      'calculatedSugar': calculatedSugar
    };
  }

  /// Creates a FoodSugarEntry object from a map/JSON data
  ///
  /// Used when retrieving data from storage or database
  factory FoodSugarEntry.fromMap(Map<String, dynamic> map) {
    return FoodSugarEntry(
      foodName: map['foodName'],
      sugarLevel: map['sugarLevel'],
      amountConsumed: map['amountConsumed'],
      calculatedSugar: map['calculatedSugar'],
    );
  }
}

/// Manages food consumption tracking and sugar calculations
///
/// Provides functionality for saving, retrieving, and calculating
/// sugar consumption data both locally and in the cloud
class ConsumptionTracker {
  // Storage key for shared preferences
  static const String userFoodDataKey = 'userFoodData';

  /// Saves new food entry data locally and syncs with Firestore
  ///
  /// @param email User's email to identify their data
  /// @param foodName Name of the food item
  /// @param sugarLevel Sugar content as a string (e.g., "25%")
  static Future<void> saveFoodEntry(
      String email, String foodName, String sugarLevel) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Get any data from Firestore to ensure we're in sync
      final userDataMap = await _syncWithFirestore(email);

      // Load existing local data or initialize empty map
      final dataMapString = prefs.getString(userFoodDataKey);
      final Map<String, dynamic> dataMap =
          dataMapString != null ? json.decode(dataMapString) : {};

      // Retrieve or initialize the user's entries list from available sources
      final List<dynamic> userList = dataMap[email] ?? userDataMap[email] ?? [];
      final List<FoodSugarEntry> userEntries = userList
          .map((e) => FoodSugarEntry.fromMap(e as Map<String, dynamic>))
          .toList();

      // Add new entry at the beginning of the list (most recent first)
      userEntries.insert(
          0, FoodSugarEntry(foodName: foodName, sugarLevel: sugarLevel));

      // Keep only the 10 most recent entries to manage storage size
      if (userEntries.length > 10) {
        userEntries.removeLast();
      }

      // Save updated list to local storage
      dataMap[email] = userEntries.map((e) => e.toMap()).toList();
      await prefs.setString(userFoodDataKey, json.encode(dataMap));

      debugPrint('✅ Data saved locally for $email');

      // Upload updated data to Firestore for cloud backup and sync
      await FirebaseFirestore.instance
          .collection('users')
          .doc(email)
          .set({'foodEntries': userEntries.map((e) => e.toMap()).toList()});

      debugPrint('✅ Data uploaded to Firestore for $email');
    } catch (e) {
      debugPrint('❌ Error saving data: $e');
    }
  }

  /// Fetches user data from Firestore to ensure local data is in sync
  ///
  /// @param email User's email to identify their data
  /// @return Map of user data from Firestore or empty map if no data exists
  static Future<Map<String, dynamic>> _syncWithFirestore(String email) async {
    try {
      final doc =
          await FirebaseFirestore.instance.collection('users').doc(email).get();
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

  /// Calculates actual sugar amount based on consumption quantity
  ///
  /// @param sugarLevel Sugar percentage as a string (e.g., "25%")
  /// @param consumedAmount Amount consumed in grams
  /// @return Calculated sugar amount in grams
  static double calculateSugarAmount(String sugarLevel, double consumedAmount) {
    // Extract numeric percentage value from sugar level string
    RegExp regex = RegExp(r'(\d+(\.\d+)?)');
    final match = regex.firstMatch(sugarLevel);

    double baseSugarValue = 0.0;
    if (match != null) {
      baseSugarValue = double.tryParse(match.group(1) ?? '0') ?? 0.0;
    }

    // Calculate sugar based on consumption amount (per 100g standard)
    return (baseSugarValue * consumedAmount) / 100.0;
  }

  /// Saves consumption data to daily tracking collection in Firestore
  ///
  /// @param foodName Name of the consumed food
  /// @param amount Amount consumed in grams
  /// @param sugarAmount Calculated sugar amount in grams
  static Future<void> saveDailyConsumption(
      String foodName, double amount, double sugarAmount) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final email = user.email!;
    // Create date key in format YYYY-MM-DD for daily tracking
    final DateTime now = DateTime.now();
    final String dateKey =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    try {
      // Get reference to user's daily consumption document for current date
      final docRef = FirebaseFirestore.instance
          .collection('dailySugarConsumption')
          .doc(email)
          .collection('days')
          .doc(dateKey);

      // Check if document for today already exists
      final doc = await docRef.get();

      if (doc.exists) {
        // Update existing document with new consumption data
        final data = doc.data() as Map<String, dynamic>;
        final currentTotal = data['totalSugar'] as double? ?? 0.0;
        final List<dynamic> consumptionList =
            data['items'] as List<dynamic>? ?? [];

        // Add new consumption item to the list
        consumptionList.add({
          'timestamp': Timestamp.now(),
          'foodName': foodName,
          'amountInGrams': amount,
          'sugarAmount': sugarAmount,
        });

        // Update the document with new total and item list
        await docRef.update({
          'totalSugar': currentTotal + sugarAmount,
          'items': consumptionList,
          'lastUpdated': Timestamp.now(),
        });
      } else {
        // Create new document for today's date
        await docRef.set({
          'date': dateKey,
          'totalSugar': sugarAmount,
          'items': [
            {
              'timestamp': Timestamp.now(),
              'foodName': foodName,
              'amountInGrams': amount,
              'sugarAmount': sugarAmount,
            }
          ],
          'lastUpdated': Timestamp.now(),
        });
      }

      debugPrint('✅ Daily consumption saved for $email on $dateKey');
    } catch (e) {
      debugPrint('❌ Error saving daily consumption: $e');
    }
  }

  /// Retrieves user's consumption data for the current day
  ///
  /// @return Map containing today's consumption data or null if no data exists
  static Future<Map<String, dynamic>?> getTodayConsumption() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    final email = user.email!;
    // Create date key in format YYYY-MM-DD for today
    final DateTime now = DateTime.now();
    final String dateKey =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    try {
      // Fetch today's consumption document
      final doc = await FirebaseFirestore.instance
          .collection('dailySugarConsumption')
          .doc(email)
          .collection('days')
          .doc(dateKey)
          .get();

      if (doc.exists) {
        return doc.data();
      }
    } catch (e) {
      debugPrint('❌ Error getting today consumption: $e');
    }
    return null;
  }
}

/// Dialog widget for entering food consumption amount
///
/// Displays a modal dialog for the user to input consumption quantity
/// and calculates the resulting sugar amount
class ConsumptionDialog extends StatefulWidget {
  final String foodName; // Name of the food item
  final String sugarLevel; // Sugar level as a string (e.g., "25%")
  final Function(double, double) onCalculated; // Callback for calculated values

  const ConsumptionDialog({
    Key? key,
    required this.foodName,
    required this.sugarLevel,
    required this.onCalculated,
  }) : super(key: key);

  @override
  _ConsumptionDialogState createState() => _ConsumptionDialogState();
}

class _ConsumptionDialogState extends State<ConsumptionDialog> {
  final TextEditingController _amountController = TextEditingController();

  void _calculateSugarAmount() {
    if (_amountController.text.isEmpty) return;

    final consumedAmount = double.tryParse(_amountController.text) ?? 0.0;
    final calculatedSugar = ConsumptionTracker.calculateSugarAmount(
        widget.sugarLevel, consumedAmount);

    ConsumptionTracker.saveDailyConsumption(
        widget.foodName, consumedAmount, calculatedSugar);

    widget.onCalculated(consumedAmount, calculatedSugar);

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Background(context),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.7), width: 1.5),
          image: DecorationImage(
            image: AssetImage("assets/Background.png"),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Tinting(context),
              BlendMode.overlay,
            ),
            opacity: 0.85,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Dialog title
            Text(
              'Track Your Consumption',
              style: TextStyle(
                fontSize: size.width * 0.06,
                color: BlackText(context),
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),

            Divider(color: Colors.white.withOpacity(0.7), thickness: 1),
            SizedBox(height: 16),

            // Food name display
            Text(
              widget.foodName,
              style: TextStyle(
                fontSize: size.width * 0.05,
                fontWeight: FontWeight.bold,
                color: BlackText(context),
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),

            // Sugar level badge
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: Colors.purple.withOpacity(0.2),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.white.withOpacity(0.8)),
              ),
              child: Text(
                widget.sugarLevel,
                style: TextStyle(
                  color: Colors.white, // Keep as white
                  fontWeight: FontWeight.w600,
                  fontSize: size.width * 0.04,
                ),
              ),
            ),

            SizedBox(height: 24),

            // Amount input field
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: BlackText(context)),
              ),
              child: TextField(
                controller: _amountController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: BlackText(context),
                  fontSize: size.width * 0.045,
                ),
                decoration: InputDecoration(
                  labelText: 'Amount consumed (grams)',
                  labelStyle: TextStyle(
                    color: BlackText(context),
                  ),
                  prefixIcon: Icon(Icons.scale,
                      color: BlackText(context)),
                  border: InputBorder.none,
                  contentPadding:
                      EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                ),
                onSubmitted: (_) => _calculateSugarAmount(),
              ),
            ),

            SizedBox(height: 24),

            // Action buttons
            Row(
              children: [
                // Cancel button
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white, // Keep as white
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        fontSize: size.width * 0.04,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 16),
                // Calculate button
                Expanded(
                  child: ElevatedButton(
                    onPressed: _calculateSugarAmount,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple.withOpacity(0.8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      'Calculate',
                      style: TextStyle(
                        fontSize: size.width * 0.04,
                        color: Colors.white, // Keep as white
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget that displays a summary of the user's consumption
///
/// Shows the amount consumed and calculated sugar in a formatted display
class ConsumptionSummary extends StatelessWidget {
  final double consumedAmount; // Amount consumed in grams
  final double calculatedSugar; // Calculated sugar amount in grams

  const ConsumptionSummary({
    Key? key,
    required this.consumedAmount,
    required this.calculatedSugar,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Column(
      children: [
        SizedBox(height: 24),
        Divider(color: Colors.purple.withOpacity(0.3)),
        SizedBox(height: 16),

        // Section title
        Text(
          'Last Consumption',
          style: TextStyle(
            fontSize: size.width * 0.05,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 16),

        // Consumption metrics display
        Row(
          children: [
            // Amount consumed column
            Expanded(
              child: Column(
                children: [
                  Text(
                    'Amount',
                    style: TextStyle(
                      fontSize: size.width * 0.04,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '${consumedAmount.toStringAsFixed(1)}g',
                    style: TextStyle(
                      fontSize: size.width * 0.05,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),

            // Divider between metrics
            Container(
              height: 40,
              width: 1,
              color: Colors.purple.withOpacity(0.3),
            ),

            // Sugar consumed column
            Expanded(
              child: Column(
                children: [
                  Text(
                    'Sugar',
                    style: TextStyle(
                      fontSize: size.width * 0.04,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '${calculatedSugar.toStringAsFixed(1)}g',
                    style: TextStyle(
                      fontSize: size.width * 0.05,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Widget that displays a badge with current day's consumption summary
///
/// Shows total sugar and number of items consumed today
/// Acts as a navigation link to the daily sugar tracker screen
class DailyConsumptionBadge extends StatefulWidget {
  const DailyConsumptionBadge({Key? key}) : super(key: key);

  @override
  _DailyConsumptionBadgeState createState() => _DailyConsumptionBadgeState();
}

class _DailyConsumptionBadgeState extends State<DailyConsumptionBadge> {
  Map<String, dynamic>? _todayData; // Today's consumption data
  bool _isLoading = true; // Loading state indicator

  @override
  void initState() {
    super.initState();
    _loadTodayData();
  }

  /// Loads today's consumption data from Firestore
  Future<void> _loadTodayData() async {
    setState(() {
      _isLoading = true;
    });

    final data = await ConsumptionTracker.getTodayConsumption();

    setState(() {
      _todayData = data;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Show loading indicator while fetching data
    if (_isLoading) {
      return SizedBox(
        height: 30,
        width: 30,
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.purple),
          strokeWidth: 2,
        ),
      );
    }

    // Hide badge if no data exists for today
    if (_todayData == null) {
      return SizedBox.shrink();
    }

    // Extract consumption data
    final totalSugar = _todayData!['totalSugar'] as double? ?? 0.0;
    final items = _todayData!['items'] as List<dynamic>? ?? [];

    // Badge with navigation to detailed view
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => DailySugarTracker()),
        );
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.purple,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Total sugar consumed today
            Text(
              '${totalSugar.toStringAsFixed(1)}g',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            // Number of consumption items
            Text(
              '${items.length} items',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
