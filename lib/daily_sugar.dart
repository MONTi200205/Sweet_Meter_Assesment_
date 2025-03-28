import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'sugar_chart.dart';
import 'home_screen.dart';
import 'utils/Darkmode.dart';

class DailySugarTracker extends StatefulWidget {
  @override
  _DailySugarTrackerState createState() => _DailySugarTrackerState();
}

class _DailySugarTrackerState extends State<DailySugarTracker> {
  // Data storage - cached data to prevent reloading
  List<Map<String, dynamic>> _consumptionData = [];
  List<Map<String, dynamic>> _chartData = [];
  double _sevenDayTotal = 0.0;

  // Loading state indicators
  bool _isInitialLoading = true;
  String _errorMessage = '';

  // Scroll controller
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// Load all data once and cache it
  Future<void> _loadAllData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _isInitialLoading = false;
          _errorMessage = 'User not logged in';
        });
        return;
      }

      final email = user.email!;
      final DateTime now = DateTime.now();
      final DateTime sevenDaysAgo = now.subtract(Duration(days: 7));

      // Format date keys
      final String startDateKey = '${sevenDaysAgo.year}-${sevenDaysAgo.month.toString().padLeft(2, '0')}-${sevenDaysAgo.day.toString().padLeft(2, '0')}';
      final String endDateKey = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      // Fetch ALL consumption data at once
      final querySnapshot = await FirebaseFirestore.instance
          .collection('dailySugarConsumption')
          .doc(email)
          .collection('days')
          .where('date', isGreaterThanOrEqualTo: startDateKey)
          .where('date', isLessThanOrEqualTo: endDateKey)
          .orderBy('date', descending: true)
          .get();

      // Process into list of maps
      final List<Map<String, dynamic>> consumptionData = [];
      final List<Map<String, dynamic>> chartData = [];
      double total = 0.0;

      // Process each document
      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        final String dateStr = data['date'] as String? ?? '';

        // Only process valid records
        if (dateStr.isNotEmpty) {
          // Calculate sugar amount
          final double sugarAmount = _safeToDouble(data['totalSugar']);
          total += sugarAmount;

          // Format date for display
          final parts = dateStr.split('-');
          if (parts.length >= 3) {
            final String displayDate = '${parts[2]}/${parts[1]}';
            final String fullDisplayDate = '${parts[2]}/${parts[1]}/${parts[0]}';

            // Add to consumption data
            consumptionData.add({
              'date': dateStr,
              'displayDate': fullDisplayDate,
              'totalSugar': sugarAmount,
              'items': data['items'] ?? [],
            });

            // Add to chart data
            chartData.add({
              'date': dateStr,
              'displayDate': displayDate,
              'totalSugar': sugarAmount,
            });
          }
        }
      }

      // Sort chart data chronologically
      chartData.sort((a, b) => (a['date'] as String).compareTo(b['date'] as String));

      // Fill missing days in chart
      final filledChartData = _fillMissingDays(chartData, sevenDaysAgo, now);

      // Update state with all fetched data
      if (mounted) {
        setState(() {
          _consumptionData = consumptionData;
          _chartData = filledChartData;
          _sevenDayTotal = total;
          _isInitialLoading = false;
        });
      }
    } catch (e) {
      print('Error loading data: $e');
      if (mounted) {
        setState(() {
          _isInitialLoading = false;
          _errorMessage = 'Error loading data: $e';
        });
      }
    }
  }

  /// Safely converts any value to double
  double _safeToDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  /// Fills missing days in chart data
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

    // Replace placeholder data with actual values
    for (var item in data) {
      final dateKey = item['date'] as String?;
      if (dateKey != null && dateKey.isNotEmpty) {
        dateMap[dateKey] = item;
      }
    }

    // Convert to list and sort
    final result = dateMap.values.toList();
    result.sort((a, b) => (a['date'] as String).compareTo(b['date'] as String));

    return result;
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    return Stack(
      children: [
        // Background
        Container(
          width: double.infinity,
          height: double.infinity,
          color: Background(context),
        ),

        // Background image
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

        // Main content
        Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: Text(
              'Sugar Consumption Tracker',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: IconColor(context)),
              onPressed: () => Navigator.pop(context),
            ),
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
          body: _isInitialLoading
              ? Center(child: CircularProgressIndicator(color: Colors.purple))
              : _errorMessage.isNotEmpty
              ? Center(child: Text(_errorMessage, style: TextStyle(color: Colors.white)))
              : isLandscape
              ? _buildLandscapeLayout(context, size)
              : _buildPortraitLayout(context, size),
        ),
      ],
    );
  }

  /// Portrait layout
  Widget _buildPortraitLayout(BuildContext context, Size size) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Summary section
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
                  dailyData: _chartData,
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

        // Daily consumption list - scrollable
        Expanded(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: size.width * 0.05),
            child: _buildDailyList(size, false),
          ),
        ),
      ],
    );
  }

  /// Landscape layout
  Widget _buildLandscapeLayout(BuildContext context, Size size) {
    return Padding(
      padding: EdgeInsets.all(size.width * 0.03),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 7-day total summary bar
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

          // Main content - two columns
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left column - Chart
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
                      Expanded(
                        child: SugarChart(
                          dailyData: _chartData,
                          chartHeight: size.height * 0.5,
                          chartWidth: size.width * 0.6,
                          isLandscape: true,
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(width: size.width * 0.02),

                // Right column - Daily breakdown
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
                      Expanded(
                        child: _buildDailyList(size, true),
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

  /// Build the daily list with cached data
  Widget _buildDailyList(Size size, bool isLandscape) {
    // Show empty message if no data
    if (_consumptionData.isEmpty) {
      return Center(
        child: Text(
          'No consumption data available',
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    // Font sizes for different orientations
    final double titleSize = isLandscape ? size.width * 0.025 : size.width * 0.04;
    final double subtitleSize = isLandscape ? size.width * 0.02 : size.width * 0.035;
    final double valueSize = isLandscape ? size.width * 0.025 : size.width * 0.045;

    // Build list from cached data - no more StreamBuilder
    return ListView.builder(
      key: PageStorageKey('daily_list'),
      controller: _scrollController,
      itemCount: _consumptionData.length,
      itemBuilder: (context, index) {
        final item = _consumptionData[index];
        final String displayDate = item['displayDate'] as String? ?? '';
        final double totalSugar = _safeToDouble(item['totalSugar']);
        final List<dynamic> items = item['items'] as List<dynamic>? ?? [];

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
                fontSize: titleSize,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            subtitle: Text(
              'Items consumed: ${items.length}',
              style: TextStyle(
                fontSize: subtitleSize,
                color: Colors.white.withOpacity(0.7),
              ),
            ),
            trailing: Text(
              '${totalSugar.toStringAsFixed(1)} g',
              style: TextStyle(
                fontSize: valueSize,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            onTap: () {
              _showDayDetails(context, item, item['date'] as String? ?? '');
            },
          ),
        );
      },
    );
  }

  /// Show day details dialog
  void _showDayDetails(BuildContext context, Map<String, dynamic> data, String dateStr) {
    final size = MediaQuery.of(context).size;
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    // Size adjustments
    final double titleSize = isLandscape ? size.width * 0.03 : size.width * 0.05;
    final double contentSize = isLandscape ? size.width * 0.025 : size.width * 0.04;
    final double itemSize = isLandscape ? size.width * 0.02 : size.width * 0.035;

    // Get display date
    final String displayDate = data['displayDate'] as String? ?? dateStr;

    // Get items
    final items = data['items'] as List<dynamic>? ?? [];

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: isLandscape ? size.width * 0.6 : size.width * 0.8,
            constraints: BoxConstraints(maxHeight: size.height * 0.8),
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Title
                Text(
                  'Sugar Consumption on $displayDate',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: titleSize,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                Divider(color: Colors.white.withOpacity(0.5)),
                SizedBox(height: 10),

                // Total
                Text(
                  'Total Sugar: ${_safeToDouble(data['totalSugar']).toStringAsFixed(1)} g',
                  style: TextStyle(
                    fontSize: contentSize,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 16),

                // Items list
                items.isEmpty
                    ? Text(
                  'No items recorded for this day',
                  style: TextStyle(color: Colors.white),
                )
                    : Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index] as Map<String, dynamic>? ?? {};

                      // Format time
                      String time = "--:--";
                      try {
                        final timestamp = item['timestamp'] as Timestamp?;
                        if (timestamp != null) {
                          time = DateFormat('HH:mm').format(timestamp.toDate());
                        }
                      } catch (e) {
                        print('Error formatting time: $e');
                      }

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
                                    item['foodName'] as String? ?? 'Unknown Food',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: itemSize,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    '$time • ${_safeToDouble(item['amountInGrams']).toStringAsFixed(1)} g consumed',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.7),
                                      fontSize: itemSize * 0.85,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Sugar badge
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
                                  fontSize: itemSize * 0.9,
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
                        fontSize: contentSize,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}