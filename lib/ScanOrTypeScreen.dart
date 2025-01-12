import 'package:flutter/material.dart';
import 'TypeFood.dart';

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

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "You can Either Scan\nor Type",
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
              color: Colors.black,
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
            const Spacer(), // ✅ Correct use of Spacer
            ElevatedButton(
              onPressed: () {
                if (isTypeSelected) {
                  // Navigate to TypeFood screen
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => TypeFood()),
                  );
                } else {
                  // ✅ Fix: Add a valid destination screen here
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            Container()), // Replace with actual Scan screen
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
                  horizontal: screenWidth * 0.1,
                ),
              ),
              child: const Text(
                "Next",
                style: TextStyle(fontSize: 16),
              ),
            ),
            SizedBox(height: screenHeight * 0.04),
          ],
        ),
      ),
    );
  }
}