import 'package:flutter/material.dart';
import 'TypeFood.dart';
import 'ScanFood.dart';
import 'package:sweet_meter_assesment/utils/Darkmode.dart';

class ScanOrTypeScreen extends StatefulWidget {
  @override
  _ScanOrTypeScreenState createState() => _ScanOrTypeScreenState();
}

class _ScanOrTypeScreenState extends State<ScanOrTypeScreen> {
  bool isTypeSelected = true;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

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
          backgroundColor: Background(context),
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color:IconColor(context)),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "You can Either \n Scan or Type",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple,
                  ),
                ),
                SizedBox(height: screenHeight * 0.04),
                Divider(color: Colors.purple, thickness: 1),
                SizedBox(height: screenHeight * 0.04),
                ToggleButtons(
                  isSelected: [isTypeSelected, !isTypeSelected],
                  borderRadius: BorderRadius.circular(30),
                  selectedBorderColor: Colors.purple,
                  fillColor: Colors.purple,
                  selectedColor: Colors.white,
                  color: BlackText(context),
                  borderColor: Colors.purple,
                  onPressed: (int index) {
                    setState(() {
                      isTypeSelected = index == 0;
                    });
                  },
                  constraints: BoxConstraints(
                    minHeight: screenHeight * 0.07,
                    minWidth: screenWidth * 0.4,
                  ),
                  children: const [
                    Text("Type"),
                    Text("Scan"),
                  ],
                ),
                Spacer(),
                ElevatedButton(
                  onPressed: () {
                    if (isTypeSelected) {
                      // Navigate to Screen 1
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => TypeFood()),
                      );
                    } else if (!isTypeSelected) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => ScanFood()),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                    padding: EdgeInsets.symmetric(
                      vertical: screenHeight * 0.02,
                      horizontal: screenWidth * 0.2,
                    ),
                  ),
                  child: const Text(
                    "Next",
                    style: TextStyle(fontSize: 16,color:Colors.white),
                  ),
                ),
                SizedBox(height: screenHeight * 0.04),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
