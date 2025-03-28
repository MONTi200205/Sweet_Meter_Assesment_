import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'consumption_tracker.dart';
import 'utils/Darkmode.dart';
import 'History.dart';
import 'home_screen.dart';
import 'daily_sugar.dart';

/// Result screen that displays food sugar information
///
/// Shows detailed information about a food item's sugar content
/// and allows users to track consumption with quantity input.
/// Supports both portrait and landscape orientations.
class Result extends StatefulWidget {
  /// Name of the food item being displayed
  final String foodName;

  /// Sugar level of the food (e.g. "25%")
  final String sugarLevel;

  const Result({
    Key? key,
    required this.foodName,
    required this.sugarLevel
  }) : super(key: key);

  @override
  _ResultState createState() => _ResultState();
}

class _ResultState extends State<Result> with WidgetsBindingObserver {
  // Amount of food consumed in grams
  double _consumedAmount = 0.0;

  // Calculated sugar amount based on consumption
  double _calculatedSugar = 0.0;

  // Indicates if the user has calculated consumption
  bool _hasCalculated = false;

  @override
  void initState() {
    super.initState();
    // Register for orientation changes
    WidgetsBinding.instance.addObserver(this);

    // Save food entry to user's history
    _saveFoodEntry();
  }

  @override
  void dispose() {
    // Remove orientation change observer
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Handle orientation changes without reloading data
  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    // Just rebuild the UI without reinitializing data
  }

  /// Saves the current food entry to user's history
  ///
  /// Stores food information in both local storage and Firestore
  void _saveFoodEntry() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Save food entry using ConsumptionTracker
      await ConsumptionTracker.saveFoodEntry(
          user.email!,
          widget.foodName,
          widget.sugarLevel
      );
    }
  }

  /// Shows the consumption tracking dialog
  ///
  /// Displays a modal dialog where users can input consumption amount
  /// and receive calculated sugar content
  void _showConsumptionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return ConsumptionDialog(
          foodName: widget.foodName,
          sugarLevel: widget.sugarLevel,
          onCalculated: (amount, sugar) {
            setState(() {
              _consumedAmount = amount;
              _calculatedSugar = sugar;
              _hasCalculated = true;
            });
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    final user = FirebaseAuth.instance.currentUser;

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
            // Back navigation button
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: IconColor(context)),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              // Daily consumption badge showing today's intake
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: DailyConsumptionBadge(),
              ),
              // Home button for direct navigation
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
            elevation: 0,
          ),
          // Select layout based on orientation
          body: isLandscape
              ? _buildLandscapeLayout(context, size, user)
              : _buildPortraitLayout(context, size, user),
          // Floating action button for consumption tracking
          floatingActionButton: Padding(
            padding: EdgeInsets.only(bottom: 60), // Move up to avoid overlap
            child: FloatingActionButton(
              onPressed: _showConsumptionDialog,
              backgroundColor: Colors.purple,
              child: Icon(Icons.add, color: Colors.white),
              tooltip: 'Track Consumption',
            ),
          ),
        ),
      ],
    );
  }

  /// Builds portrait orientation layout
  ///
  /// Vertical layout with full-width components
  /// and prominent result card
  Widget _buildPortraitLayout(BuildContext context, Size size, User? user) {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: size.width * 0.05),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Screen title
            Text(
              'Results',
              style: TextStyle(
                fontSize: size.width * 0.08,
                color: Colors.purple,
                fontWeight: FontWeight.bold,
              ),
            ),
            Divider(color: Colors.purple, thickness: 2),
            SizedBox(height: size.height * 0.05),

            // Result card with food information
            Container(
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Food icon
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.purple.withOpacity(0.1),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.purple),
                    ),
                    child: Icon(
                      Icons.fastfood,
                      color: Colors.purple,
                      size: size.width * 0.1,
                    ),
                  ),

                  SizedBox(height: 16),

                  // Food name display
                  Text(
                    'Food:',
                    style: TextStyle(
                      fontSize: size.width * 0.05,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    widget.foodName,
                    style: TextStyle(
                      fontSize: size.width * 0.06,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  SizedBox(height: 24),

                  // Sugar level display
                  Text(
                    'Sugar Level:',
                    style: TextStyle(
                      fontSize: size.width * 0.05,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.purple.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: Colors.white,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      widget.sugarLevel,
                      style: TextStyle(
                        fontSize: size.width * 0.055,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  // Consumption summary if user has calculated intake
                  if (_hasCalculated)
                    ConsumptionSummary(
                      consumedAmount: _consumedAmount,
                      calculatedSugar: _calculatedSugar,
                    ),
                ],
              ),
            ),

            SizedBox(height: size.height * 0.05),

            // Navigation buttons
            // History button
            Container(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => History()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 3,
                ),
                icon: Icon(
                  Icons.history,
                  color: Colors.white,
                ),
                label: Text(
                  'View History',
                  style: TextStyle(
                    fontSize: size.width * 0.05,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            SizedBox(height: size.height * 0.02),

            // Daily sugar tracker button
            Container(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => DailySugarTracker()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.2),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                    side: BorderSide(color: Colors.white, width: 2),
                  ),
                  elevation: 0,
                ),
                icon: Icon(
                  Icons.calendar_today,
                  color: Colors.white,
                ),
                label: Text(
                  'Daily Sugar Tracker',
                  style: TextStyle(
                    fontSize: size.width * 0.045,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            // User email display
            SizedBox(height: size.height * 0.03),
            Text(
              "Logged in as: ${user?.email ?? 'Unknown'}",
              style: TextStyle(
                fontSize: size.width * 0.035,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: size.height * 0.02),
          ],
        ),
      ),
    );
  }

  /// Builds landscape orientation layout
  ///
  /// Two-column layout with results card on left
  /// and navigation options on right
  Widget _buildLandscapeLayout(BuildContext context, Size size, User? user) {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(size.width * 0.03),
        child: Column(
          children: [
            // Title and divider
            Text(
              'Results',
              style: TextStyle(
                fontSize: size.width * 0.05,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            Divider(color: Colors.white, thickness: 2),
            SizedBox(height: size.height * 0.03),

            // Main content row layout
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left side - Results card
                Expanded(
                  flex: 3,
                  child: Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white,
                        width: 2,
                      ),
                    ),
                    child: Row(
                      children: [
                        // Food information
                        Expanded(
                          child: Column(
                            children: [
                              // Food icon
                              Container(
                                padding: EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.purple.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.purple),
                                ),
                                child: Icon(
                                  Icons.fastfood,
                                  color: Colors.purple,
                                  size: size.width * 0.04,
                                ),
                              ),
                              SizedBox(height: 12),

                              // Food name
                              Text(
                                'Food:',
                                style: TextStyle(
                                  fontSize: size.width * 0.025,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                widget.foodName,
                                style: TextStyle(
                                  fontSize: size.width * 0.03,
                                  color: Colors.white,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: 16),

                              // Sugar level
                              Text(
                                'Sugar Level:',
                                style: TextStyle(
                                  fontSize: size.width * 0.025,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 8),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.purple.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  widget.sugarLevel,
                                  style: TextStyle(
                                    fontSize: size.width * 0.025,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Divider between food info and consumption data
                        if (_hasCalculated)
                          Container(
                            height: size.height * 0.2,
                            width: 1,
                            color: Colors.purple.withOpacity(0.3),
                            margin: EdgeInsets.symmetric(horizontal: 16),
                          ),

                        // Consumption summary if available
                        if (_hasCalculated)
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Consumption title with icon
                                Icon(
                                  Icons.analytics,
                                  color: Colors.purple,
                                  size: size.width * 0.04,
                                ),
                                SizedBox(height: 12),
                                Text(
                                  'Last Consumption:',
                                  style: TextStyle(
                                    fontSize: size.width * 0.025,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 16),

                                // Consumption metrics display
                                Row(
                                  children: [
                                    // Amount consumed
                                    Expanded(
                                      child: Column(
                                        children: [
                                          Text(
                                            'Amount',
                                            style: TextStyle(
                                              fontSize: size.width * 0.02,
                                              color: Colors.white,
                                            ),
                                          ),
                                          SizedBox(height: 8),
                                          Text(
                                            '${_consumedAmount.toStringAsFixed(1)}g',
                                            style: TextStyle(
                                              fontSize: size.width * 0.025,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Vertical divider
                                    Container(
                                      height: 40,
                                      width: 1,
                                      color: Colors.purple.withOpacity(0.3),
                                    ),

                                    // Sugar consumed
                                    Expanded(
                                      child: Column(
                                        children: [
                                          Text(
                                            'Sugar',
                                            style: TextStyle(
                                              fontSize: size.width * 0.02,
                                              color: Colors.white,
                                            ),
                                          ),
                                          SizedBox(height: 8),
                                          Text(
                                            '${_calculatedSugar.toStringAsFixed(1)}g',
                                            style: TextStyle(
                                              fontSize: size.width * 0.025,
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
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                SizedBox(width: size.width * 0.02),

                // Right side - Navigation buttons in column layout
                Expanded(
                  flex: 1,
                  child: Column(
                    children: [
                      // History button
                      Container(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => History()),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            padding: EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 16,
                            ),
                          ),
                          icon: Icon(
                            Icons.history,
                            color: Colors.white,
                            size: size.width * 0.02,
                          ),
                          label: Text(
                            'History',
                            style: TextStyle(
                              fontSize: size.width * 0.02,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: 12),

                      // Daily sugar tracker button
                      Container(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => DailySugarTracker()),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white.withOpacity(0.2),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: BorderSide(color: Colors.white, width: 1),
                            ),
                            padding: EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 16,
                            ),
                          ),
                          icon: Icon(
                            Icons.calendar_today,
                            color: Colors.white,
                            size: size.width * 0.02,
                          ),
                          label: Text(
                            'Daily',
                            style: TextStyle(
                              fontSize: size.width * 0.02,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: 16),

                      // User email info
                      Text(
                        "Logged in as: \n${user?.email ?? 'Unknown'}",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: size.width * 0.015,
                          color: Colors.grey,
                        ),
                      ),
                    ],
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