import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'sugar_chart.dart';
import 'home_screen.dart';
import 'utils/Darkmode.dart';

/// Screen for tracking and visualizing daily sugar consumption
///
/// Displays a 7-day summary of sugar intake with charts and detailed breakdowns
/// of consumption by day and individual food items
class DailySugarTracker extends StatefulWidget {
  @override
  _DailySugarTrackerState createState() => _DailySugarTrackerState();
}

class _DailySugarTrackerState extends State<DailySugarTracker> {
  // Stream of daily consumption data from Firestore
  late Stream<QuerySnapshot> _dailyConsumptionStream;

  // Calculated total sugar consumption over the past 7 days
  double _sevenDayTotal = 0.0;

  // Processed data for chart visualization
  final List<Map<String, dynamic>> _dailyData = [];

  // Loading state tracker
  bool _isLoading = true;

  // Controller for list scrolling
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  @override
  void dispose() {
    // Clean up resources
    _scrollController.dispose();
    super.dispose();
  }

  /// Initializes data streams and calculates consumption totals
  ///
  /// Sets up Firestore stream for the last 7 days of consumption data
  /// and triggers calculation of the 7-day consumption total
  void _initializeData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final email = user.email!;
    final DateTime now = DateTime.now();

    // Calculate date range for the past 7 days
    final DateTime sevenDaysAgo = now.subtract(Duration(days: 7));
    final String startDateKey = '${sevenDaysAgo.year}-${sevenDaysAgo.month.toString().padLeft(2, '0')}-${sevenDaysAgo.day.toString().padLeft(2, '0')}';
    final String endDateKey = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    // Set up Firestore data stream with date filtering
    _dailyConsumptionStream = FirebaseFirestore.instance
        .collection('dailySugarConsumption')
        .doc(email)
        .collection('days')
        .where('date', isGreaterThanOrEqualTo: startDateKey)
        .where('date', isLessThanOrEqualTo: endDateKey)
        .orderBy('date', descending: true)
        .snapshots();

    // Calculate total consumption for the past 7 days
    await _calculateSevenDayTotal();

    setState(() {
      _isLoading = false;
    });
  }

  /// Safely converts any numeric value to double
  ///
  /// Handles int, double, and String types to prevent casting errors
  double _safeToDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }

  /// Calculates total sugar consumption over the past 7 days
  ///
  /// Fetches and processes consumption data from Firestore,
  /// calculating the total and preparing chart visualization data
  Future<void> _calculateSevenDayTotal() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final email = user.email!;
    final DateTime now = DateTime.now();
    final DateTime sevenDaysAgo = now.subtract(Duration(days: 7));

    // Format date keys for Firestore queries
    final String startDateKey = '${sevenDaysAgo.year}-${sevenDaysAgo.month.toString().padLeft(2, '0')}-${sevenDaysAgo.day.toString().padLeft(2, '0')}';
    final String endDateKey = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    try {
      // Fetch all consumption data for the past 7 days
      final querySnapshot = await FirebaseFirestore.instance
          .collection('dailySugarConsumption')
          .doc(email)
          .collection('days')
          .where('date', isGreaterThanOrEqualTo: startDateKey)
          .where('date', isLessThanOrEqualTo: endDateKey)
          .get();

      double total = 0.0;
      final List<Map<String, dynamic>> dailyData = [];

      // Process each day's data
      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        // Use safe conversion to double instead of direct casting
        final double dailyTotal = _safeToDouble(data['totalSugar']);
        total += dailyTotal; // Add to running total

        // Format the date for display
        final String dateStr = data['date'] as String;
        final parts = dateStr.split('-');
        final displayDate = '${parts[2]}/${parts[1]}';

        // Add to chart data
        dailyData.add({
          'date': data['date'],
          'displayDate': displayDate,
          'totalSugar': dailyTotal,
        });
      }

      // Sort data chronologically for chart display
      dailyData.sort((a, b) => a['date'].compareTo(b['date']));

      // Ensure all 7 days have data points (filling gaps with zeros)
      final filledData = _fillMissingDays(dailyData, sevenDaysAgo, now);

      setState(() {
        _sevenDayTotal = total;
        _dailyData.clear();
        _dailyData.addAll(filledData);
      });

      debugPrint('✅ 7-day total calculated: $_sevenDayTotal g');
    } catch (e) {
      debugPrint('❌ Error calculating 7-day total: $e');
    }
  }

  /// Ensures all days in the selected range have data points
  ///
  /// Creates placeholder data with zero values for days without consumption records
  /// to maintain consistent chart visualization
  ///
  /// @param data Existing data points from database
  /// @param startDate Beginning of the date range
  /// @param endDate End of the date range
  /// @return Complete list with all days represented
  List<Map<String, dynamic>> _fillMissingDays(
      List<Map<String, dynamic>> data, DateTime startDate, DateTime endDate) {
    final Map<String, Map<String, dynamic>> dateMap = {};

    // Initialize all dates with zero values
    for (int i = 0; i <= 7; i++) {
      final date = startDate.add(Duration(days: i));
      final String dateKey =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final String displayDate = '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';

      dateMap[dateKey] = {
        'date': dateKey,
        'displayDate': displayDate,
        'totalSugar': 0.0,
      };
    }

    // Replace placeholder data with actual values where available
    for (var item in data) {
      dateMap[item['date']] = item;
    }

    // Convert back to list and sort chronologically
    final result = dateMap.values.toList();
    result.sort((a, b) => a['date'].compareTo(b['date']));

    return result;
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    return Stack(
      children: [
        // Background color layer
        Container(
          width: double.infinity,
          height: double.infinity,
          color: Background(context),
        ),

        // Background image with overlay for visual effect
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

        // Main content scaffold
        Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: Text(
              'Sugar Consumption Tracker',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            // Back navigation button
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: IconColor(context)),
              onPressed: () => Navigator.pop(context),
            ),
            // Home navigation button
            actions: [
              IconButton(
                icon: Icon(Icons.home, color: IconColor(context)),
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => HomeScreen()),
                  );
                },
              ),
            ],
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
          // Responsive layout selection based on orientation
          body: _isLoading
              ? Center(child: CircularProgressIndicator(color: Colors.purple))
              : isLandscape
              ? _buildLandscapeLayout(context, size)
              : _buildPortraitLayout(context, size),
        ),
      ],
    );
  }

  /// Builds the portrait orientation layout
  ///
  /// Vertical layout with summary at top, chart in middle,
  /// and scrollable daily breakdown list at bottom
  Widget _buildPortraitLayout(BuildContext context, Size size) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Summary section - fixed height container
        Container(
          padding: EdgeInsets.symmetric(horizontal: size.width * 0.05),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: size.height * 0.02),

              // 7-day total summary card
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white.withOpacity(0.5)),
                ),
                child: Column(
                  children: [
                    Text(
                      '7-Day Total Sugar Consumption',
                      style: TextStyle(
                        fontSize: size.width * 0.045,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '${_sevenDayTotal.toStringAsFixed(1)} g',
                      style: TextStyle(
                        fontSize: size.width * 0.08,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: size.height * 0.03),

              // Chart section title
              Text(
                'Last 7 Days Trend',
                style: TextStyle(
                  fontSize: size.width * 0.05,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),

              SizedBox(height: size.height * 0.02),

              // Sugar consumption trend chart
              Container(
                height: size.height * 0.2,
                child: SugarChart(
                  dailyData: _dailyData,
                  chartHeight: size.height * 0.2,
                  chartWidth: size.width * 0.9,
                ),
              ),

              SizedBox(height: size.height * 0.03),

              // Daily breakdown section title
              Text(
                'Daily Breakdown',
                style: TextStyle(
                  fontSize: size.width * 0.05,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),

              SizedBox(height: size.height * 0.02),
            ],
          ),
        ),

        // Daily consumption stream - scrollable list of daily records
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _dailyConsumptionStream,
            builder: (context, snapshot) {
              // Error handling
              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Error: ${snapshot.error}',
                    style: TextStyle(color: Colors.white),
                  ),
                );
              }

              // Loading state
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: CircularProgressIndicator(color: Colors.purple),
                );
              }

              // Empty data handling
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(
                  child: Text(
                    'No consumption data yet.',
                    style: TextStyle(color: Colors.white),
                  ),
                );
              }

              // Build list of daily records
              return Padding(
                padding: EdgeInsets.symmetric(horizontal: size.width * 0.05),
                child: ListView.builder(
                  controller: _scrollController,
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final doc = snapshot.data!.docs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final String dateStr = data['date'] as String;
                    // Safe conversion instead of casting
                    final double totalSugar = _safeToDouble(data['totalSugar']);

                    // Format date for display (DD/MM/YYYY)
                    final parts = dateStr.split('-');
                    final displayDate = '${parts[2]}/${parts[1]}/${parts[0]}';

                    // Daily consumption card
                    return Card(
                      color: Colors.white.withOpacity(0.1),
                      elevation: 2,
                      margin: EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(color: Colors.white.withOpacity(0.3)),
                      ),
                      child: ListTile(
                        title: Text(
                          displayDate,
                          style: TextStyle(
                            fontSize: size.width * 0.04,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        subtitle: Text(
                          'Items consumed: ${(data['items'] as List<dynamic>?)?.length ?? 0}',
                          style: TextStyle(
                            fontSize: size.width * 0.035,
                            color: Colors.white.withOpacity(0.7),
                          ),
                        ),
                        trailing: Text(
                          '${totalSugar.toStringAsFixed(1)} g',
                          style: TextStyle(
                            fontSize: size.width * 0.045,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        onTap: () {
                          _showDayDetails(context, data, dateStr);
                        },
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  /// Builds the landscape orientation layout
  ///
  /// Two-column layout with chart on left and daily list on right,
  /// optimized for wider screen dimensions
  Widget _buildLandscapeLayout(BuildContext context, Size size) {
    return Padding(
      padding: EdgeInsets.all(size.width * 0.03),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 7-day total summary bar - horizontal layout
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.purple.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white.withOpacity(0.5)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '7-Day Total Sugar Consumption:',
                  style: TextStyle(
                    fontSize: size.width * 0.03,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(width: 16),
                Text(
                  '${_sevenDayTotal.toStringAsFixed(1)} g',
                  style: TextStyle(
                    fontSize: size.width * 0.05,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: size.height * 0.03),

          // Main content section with two columns
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left column - Chart visualization
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Last 7 Days Trend',
                        style: TextStyle(
                          fontSize: size.width * 0.03,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: size.height * 0.02),
                      // Larger chart in landscape mode
                      Expanded(
                        child: SugarChart(
                          dailyData: _dailyData,
                          chartHeight: size.height * 0.5,
                          chartWidth: size.width * 0.6,
                          isLandscape: true,
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(width: size.width * 0.02),

                // Right column - Daily breakdown list
                Expanded(
                  flex: 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Daily Breakdown',
                        style: TextStyle(
                          fontSize: size.width * 0.03,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: size.height * 0.02),
                      // List of daily records
                      Expanded(
                        child: StreamBuilder<QuerySnapshot>(
                          stream: _dailyConsumptionStream,
                          builder: (context, snapshot) {
                            // Error handling
                            if (snapshot.hasError) {
                              return Center(
                                child: Text(
                                  'Error: ${snapshot.error}',
                                  style: TextStyle(color: Colors.white),
                                ),
                              );
                            }

                            // Loading state
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return Center(
                                child: CircularProgressIndicator(color: Colors.purple),
                              );
                            }

                            // Empty data handling
                            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                              return Center(
                                child: Text(
                                  'No consumption data yet.',
                                  style: TextStyle(color: Colors.white),
                                ),
                              );
                            }

                            // Build compact list for landscape mode
                            return ListView.builder(
                              controller: _scrollController,
                              itemCount: snapshot.data!.docs.length,
                              itemBuilder: (context, index) {
                                final doc = snapshot.data!.docs[index];
                                final data = doc.data() as Map<String, dynamic>;
                                final String dateStr = data['date'] as String;
                                // Safe conversion instead of casting
                                final double totalSugar = _safeToDouble(data['totalSugar']);

                                // Format date for display
                                final parts = dateStr.split('-');
                                final displayDate = '${parts[2]}/${parts[1]}/${parts[0]}';

                                // Compact daily card for landscape
                                return Card(
                                  color: Colors.white.withOpacity(0.1),
                                  elevation: 2,
                                  margin: EdgeInsets.only(bottom: 10),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    side: BorderSide(color: Colors.white.withOpacity(0.3)),
                                  ),
                                  child: ListTile(
                                    title: Text(
                                      displayDate,
                                      style: TextStyle(
                                        fontSize: size.width * 0.025,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    subtitle: Text(
                                      'Items: ${(data['items'] as List<dynamic>?)?.length ?? 0}',
                                      style: TextStyle(
                                        fontSize: size.width * 0.02,
                                        color: Colors.white.withOpacity(0.7),
                                      ),
                                    ),
                                    trailing: Text(
                                      '${totalSugar.toStringAsFixed(1)} g',
                                      style: TextStyle(
                                        fontSize: size.width * 0.025,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    onTap: () {
                                      _showDayDetails(context, data, dateStr);
                                    },
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Shows detailed breakdown of a specific day's consumption
  ///
  /// Displays a modal dialog with all food items consumed on the selected day,
  /// their individual sugar amounts, and consumption times
  ///
  /// @param context Current build context
  /// @param data Day's consumption data map
  /// @param dateStr Date string in YYYY-MM-DD format
  void _showDayDetails(BuildContext context, Map<String, dynamic> data, String dateStr) {
    final size = MediaQuery.of(context).size;

    // Format date for display (DD/MM/YYYY)
    final parts = dateStr.split('-');
    final displayDate = '${parts[2]}/${parts[1]}/${parts[0]}';

    // Get list of consumption items
    final items = data['items'] as List<dynamic>? ?? [];

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: size.width * 0.8,
          constraints: BoxConstraints(maxHeight: size.height * 0.8), // Limit maximum height
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Background(context),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white, width: 2),
            image: DecorationImage(
              image: AssetImage("assets/Background.png"),
              fit: BoxFit.cover,
              colorFilter: ColorFilter.mode(
                Colors.black.withOpacity(0.2),
                BlendMode.darken,
              ),
            ),
          ),
          child: SingleChildScrollView( // Make entire content scrollable
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Dialog title with date
                Text(
                  'Sugar Consumption on $displayDate',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: size.width * 0.05,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                Divider(color: Colors.white.withOpacity(0.5)),
                SizedBox(height: 10),

                // Day's total sugar consumption
                Text(
                  'Total Sugar: ${_safeToDouble(data['totalSugar']).toStringAsFixed(1)} g',
                  style: TextStyle(
                    fontSize: size.width * 0.04,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 16),

                // List of individual consumption items
                Container(
                  // Use constraints instead of fixed height for better scrolling
                  constraints: BoxConstraints(
                    maxHeight: size.height * 0.4,
                  ),
                  child: ListView.builder(
                    shrinkWrap: true, // Important for nested scroll views
                    physics: ClampingScrollPhysics(), // Better scrolling behavior for nested lists
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index] as Map<String, dynamic>;

                      // Format timestamp to readable time
                      final timestamp = item['timestamp'] as Timestamp;
                      final time = DateFormat('HH:mm').format(timestamp.toDate());

                      // Food item card
                      return Container(
                        margin: EdgeInsets.only(bottom: 8),
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            // Food details
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item['foodName'] as String,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: size.width * 0.035,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    '$time • ${_safeToDouble(item['amountInGrams']).toStringAsFixed(1)} g consumed',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.7),
                                      fontSize: size.width * 0.03,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Sugar amount badge
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.purple.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.white.withOpacity(0.3)),
                              ),
                              child: Text(
                                '${_safeToDouble(item['sugarAmount']).toStringAsFixed(1)} g',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(height: 16),

                // Close button
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: Text(
                      'Close',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: size.width * 0.04,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}