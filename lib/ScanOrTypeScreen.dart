import 'package:flutter/material.dart';
import 'TypeFood.dart';
import 'ScanFood.dart';
import 'BarcodeScanner.dart'; // Import the new BarcodeScanner file
import 'package:sweet_meter_assesment/utils/Darkmode.dart';

class ScanOrTypeScreen extends StatefulWidget {
  @override
  _ScanOrTypeScreenState createState() => _ScanOrTypeScreenState();
}

class _ScanOrTypeScreenState extends State<ScanOrTypeScreen> {
  // 0 = Type, 1 = Scan, 2 = Barcode
  int selectedOption = 0;

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
              fit: BoxFit.cover,
              colorFilter: ColorFilter.mode(
                Colors.black.withOpacity(0.3),
                BlendMode.darken,
              ),
            ),
          ),
        ),

        Scaffold(
          backgroundColor: Background(context),
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: IconColor(context)),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "You can Either \n Type, Scan or Use Barcode",
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
                  isSelected: [
                    selectedOption == 0,
                    selectedOption == 1,
                    selectedOption == 2
                  ],
                  borderRadius: BorderRadius.circular(30),
                  selectedBorderColor: Colors.purple,
                  fillColor: Colors.purple,
                  selectedColor: Colors.white,
                  color: BlackText(context),
                  borderColor: Colors.purple,
                  onPressed: (int index) {
                    setState(() {
                      selectedOption = index;
                    });
                  },
                  constraints: BoxConstraints(
                    minHeight: screenHeight * 0.07,
                    minWidth: screenWidth * 0.27,
                  ),
                  children: const [
                    Text("Type"),
                    Text("Scan"),
                    Text("Barcode"),
                  ],
                ),
                Spacer(),
                ElevatedButton(
                  onPressed: () {
                    if (selectedOption == 0) {
                      // Navigate to Type Food screen
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => TypeFood()),
                      );
                    } else if (selectedOption == 1) {
                      // Navigate to Scan Food screen
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => ScanFood()),
                      );
                    } else if (selectedOption == 2) {
                      // Navigate to Barcode Scanner screen
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => BarcodeScanner()),
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
                    style: TextStyle(fontSize: 16, color: Colors.white),
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