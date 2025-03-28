/// TypeFood.dart
///
/// A screen that allows users to manually enter food names for sugar content analysis.
/// This screen provides a simple input interface with validation and navigation
/// to the processing screen when a food name is submitted.

import 'package:flutter/material.dart';
import 'ProcessingApi.dart';
import 'package:sweet_meter_assesment/utils/Darkmode.dart';
import 'home_screen.dart';

/// A screen widget that provides a text input interface for entering food names.
///
/// This widget creates a visually appealing input screen with a styled text field
/// and validation to ensure users provide a food name before proceeding to the
/// processing screen.
class TypeFood extends StatelessWidget {
  /// Controller for the food name input field.
  /// Manages the text input and enables validation before submission.
  final TextEditingController _foodController = TextEditingController();

  /// Builds the TypeFood screen UI.
  ///
  /// Creates a layered UI with background styling, navigation options,
  /// and an input field for entering food names.
  ///
  /// @param context The build context for this widget
  /// @return A widget containing the complete food input screen
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    return Stack(
      children: [
        // Background Color layer
        Container(
          width: double.infinity,
          height: double.infinity,
          color: Background(context),
        ),

        // Background Image Overlay with translucent darkening effect
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

        // Main Scaffold containing the app UI elements
        Scaffold(
          backgroundColor: Background(context),
          appBar: AppBar(
            // Back button for navigation to previous screen
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: IconColor(context)),
              onPressed: () => Navigator.pop(context),
            ),
            // Home button for direct navigation to home screen
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
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Screen title indicating purpose
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

                  // Food name input field with styled border
                  Padding(
                    padding:
                    EdgeInsets.symmetric(horizontal: screenWidth * 0.06),
                    child: TextField(
                      controller: _foodController,
                      decoration: InputDecoration(
                        hintText: 'Type the food name...',
                        filled: true,
                        fillColor: Colors.transparent,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide(
                              color: Colors.purple, width: 2),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide(
                              color: Colors.purpleAccent,
                              width: 2.5), // Highlight color when active
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide(
                              color: Colors.purple,
                              width: 1.5), // Border when inactive
                        ),
                        hintStyle: TextStyle(
                            color: BlackText(context).withOpacity(0.5),
                            fontSize: 16), // Hint text styling
                      ),
                      style: TextStyle(
                          color: BlackText(context),
                          fontSize: 18), // Input text styling
                      textAlign: TextAlign.center,
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.04),

                  // Submit button with validation and navigation logic
                  ElevatedButton(
                    onPressed: () {
                      final foodName = _foodController.text.trim();
                      // Validate that a food name was entered before proceeding
                      if (foodName.isNotEmpty) {
                        // Navigate to Processing screen with the food name
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                Processing(foodName: foodName),
                          ),
                        );
                      } else {
                        // Show error message if no food name was entered
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
        ),
      ],
    );
  }
}