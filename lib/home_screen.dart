import 'package:flutter/material.dart';
import 'ScanOrTypeScreen.dart';

class HomeScreen extends StatelessWidget {
  HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      // Transparent AppBar
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(screenHeight * 0.1),
        child: Container(
          color: Colors.transparent,
          padding: EdgeInsets.only(top: screenHeight * 0.03),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              SizedBox(height: screenHeight * 0.4),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
                child: CircleAvatar(
                  backgroundImage: AssetImage(
                      'assets/profile_image.png'), // Replace with your asset
                  radius: screenWidth * 0.05,
                ),
              ),
              Text(
                "SWEET METER",
                style: TextStyle(
                  fontFamily: 'Agbalumo', // Replace with your font
                  fontSize: screenWidth * 0.07,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple,
                ),
              ),
              IconButton(
                icon: Icon(Icons.menu, color: Colors.black),
                onPressed: () {
                  // Add functionality if needed
                }, // ✅ Removed the incorrect `);`
              ),
            ],
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(screenWidth * 0.04),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Shift everything down
              SizedBox(height: screenHeight * 0.05),

              // Latest Measurements Card (Button)
              GestureDetector(
                onTap: () {

                },
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(screenWidth * 0.05),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(screenWidth * 0.03),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.3),
                        blurRadius: screenWidth * 0.02,
                        offset: Offset(0, screenWidth * 0.01),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Latest Measurements",
                              style: TextStyle(
                                fontSize: screenWidth * 0.045,
                                fontWeight: FontWeight.bold,
                                color: Colors.black54,
                              ),
                            ),
                            SizedBox(height: screenHeight * 0.01),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: screenHeight * 0.03),

              // Track New Food Button
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    // Navigate to ScanOrTypeScreen
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => ScanOrTypeScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.1,
                      vertical: screenHeight * 0.02,
                    ),
                  ),
                  child: Text(
                    "Track New Food",
                    style: TextStyle(
                      fontSize: screenWidth * 0.045,
                      color: Colors.white, // Changed the text color to white
                    ),
                  ),
                ),
              ),

              SizedBox(height: screenHeight * 0.03),

              // Eat Healthy Section
              SizedBox(height: screenHeight * 0.01),
              Text(
                "Eat Healthy,",
                style: TextStyle(
                  fontSize: screenWidth * 0.045,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: screenHeight * 0.01),
            ],
          ),
        ),
      ),
    );
  }
}