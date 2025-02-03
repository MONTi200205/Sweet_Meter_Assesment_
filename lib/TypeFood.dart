import 'package:flutter/material.dart';
import 'ProcessingApi.dart';
import 'package:sweet_meter_assesment/utils/Darkmode.dart';
import 'home_screen.dart';

class TypeFood extends StatelessWidget {
  final TextEditingController _foodController = TextEditingController();

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
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: IconColor(context)),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
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
          ),
          body: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Title
                const Text(
                  'Enter the Food',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple,
                  ),
                ),
                Divider(color: Colors.purple, thickness: 1),

                // Input Field
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.06),
                  child: TextField(
                    controller: _foodController,
                    decoration: InputDecoration(
                      hintText: 'Type the food name...',
                      filled: true,
                      fillColor: Colors.transparent, // Background color for the input field
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide(color: Colors.purple, width: 2), // Border color
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide(color: Colors.purpleAccent, width: 2.5), // Highlight color when active
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide(color: Colors.purple, width: 1.5), // Border when inactive
                      ),
                      hintStyle: TextStyle(color: BlackText(context).withOpacity(0.5), fontSize: 16), // Set hint color
                    ),
                    style: TextStyle(color: BlackText(context), fontSize: 18), // Text field content style
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(height: screenHeight * 0.04),

                // Submit Button
                ElevatedButton(
                  onPressed: () {
                    final foodName = _foodController.text.trim();
                    if (foodName.isNotEmpty) {
                      // Navigate to Processing screen
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => Processing(foodName: foodName),
                        ),
                      );
                    } else {
                      // Show error message
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Please enter a food name'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: EdgeInsets.symmetric(
                      vertical: screenHeight * 0.02,
                      horizontal: screenWidth * 0.2,
                    ),
                  ),
                  child: Text(
                    'Submit',
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
