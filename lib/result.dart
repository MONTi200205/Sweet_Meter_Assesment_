// Result Screen - Updated with ConsumptionTracker
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'consumption_tracker.dart';
import 'utils/Darkmode.dart';
import 'History.dart';
import 'home_screen.dart';
import 'daily_sugar.dart';

class Result extends StatefulWidget {
  final String foodName;
  final String sugarLevel;

  Result({required this.foodName, required this.sugarLevel});

  @override
  _ResultState createState() => _ResultState();
}

class _ResultState extends State<Result> {
  double _consumedAmount = 0.0;
  double _calculatedSugar = 0.0;
  bool _hasCalculated = false;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Save food entry using ConsumptionTracker
      ConsumptionTracker.saveFoodEntry(user.email!, widget.foodName, widget.sugarLevel);
    }
  }

  // Show the consumption tracking popup - Using ConsumptionDialog
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
              // Daily consumption badge
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: DailyConsumptionBadge(),
              ),
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
          body: isLandscape
              ? _buildLandscapeLayout(context, size, user)
              : _buildPortraitLayout(context, size, user),
          floatingActionButton: Padding(
            padding: EdgeInsets.only(bottom: 60), // Move the FAB up to avoid overlapping
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

  Widget _buildPortraitLayout(BuildContext context, Size size, User? user) {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: size.width * 0.05),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
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

            // Result card
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

                  // Food name
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

                  // Sugar level
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

                  // Calculated result if available
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

            // Content in row layout
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Results card
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
                        // Left column - Food info
                        Expanded(
                          child: Column(
                            children: [
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

                        // Add vertical divider if calculation was performed
                        if (_hasCalculated)
                          Container(
                            height: size.height * 0.2,
                            width: 1,
                            color: Colors.purple.withOpacity(0.3),
                            margin: EdgeInsets.symmetric(horizontal: 16),
                          ),

                        // Consumption results if available
                        if (_hasCalculated)
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
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

                // Navigation buttons (vertical in landscape)
                Expanded(
                  flex: 1,
                  child: Column(
                    children: [
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