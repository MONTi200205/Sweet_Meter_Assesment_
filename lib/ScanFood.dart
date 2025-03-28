import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'ProcessingApi.dart';
import 'package:sweet_meter_assesment/utils/Darkmode.dart';
import 'home_screen.dart';

/// Screen for scanning and recognizing food items using the device camera
///
/// Allows users to take photos of food items and uses the Imagga image
/// recognition API to identify the food, then passes the identification
/// to the processing screen for nutritional lookup.
class ScanFood extends StatefulWidget {
  @override
  _ScanFoodState createState() => _ScanFoodState();
}

/// State class for the ScanFood screen
///
/// Manages camera interaction, image processing, API communication,
/// and UI state for food recognition functionality
class _ScanFoodState extends State<ScanFood> {
  /// Image picker instance for camera access
  final ImagePicker _picker = ImagePicker();

  /// The captured food image file
  File? _image;

  /// Recognition result or status message
  String _result = "Image recognition result will appear here.";

  /// Imagga API key for authentication
  final String apiKey = 'acc_52851fb94a70f06';

  /// Imagga API secret for authentication
  final String apiSecret = 'edd380e1dbd0b5d4c36e7000215e6285';

  /// Analyzes a food image using the Imagga API
  ///
  /// Sends the image to the Imagga API and processes the response
  /// to extract food item tags and update the UI with recognition results
  ///
  /// @param imageFile The captured image file to analyze
  /// @return Future that completes when analysis is done
  Future<void> analyzeImage(File imageFile) async {
    // Read the image file as bytes
    final bytes = await imageFile.readAsBytes();
    String base64Image = base64Encode(bytes);

    // Set up the API request
    final url = Uri.parse('https://api.imagga.com/v2/tags');
    final headers = {
      'Authorization':
      'Basic ' + base64Encode(utf8.encode('$apiKey:$apiSecret')),
    };

    // Create multipart request with image data
    final request = http.MultipartRequest('POST', url)
      ..headers.addAll(headers)
      ..files.add(
          http.MultipartFile.fromBytes('image', bytes, filename: 'image.jpg'));

    // Send the request
    final response = await request.send();

    // Process the response
    if (response.statusCode == 200) {
      final responseData = await http.Response.fromStream(response);
      final data = json.decode(responseData.body);

      // Extract tag data from the response
      if (data['result'] != null && data['result']['tags'] != null) {
        final tags = data['result']['tags'];
        final topTag = tags[0]['tag']['en']; // Get the top result
        setState(() {
          _result = topTag; // Display only the top tag
        });
      } else {
        setState(() {
          _result = 'No food items detected.';
        });
      }
    } else {
      // Handle API error
      setState(() {
        _result =
        'Failed to recognize the image. Status code: ${response.statusCode}';
      });
    }
  }

  /// Opens the camera to capture a food image
  ///
  /// Uses the device camera to take a photo, then sends it for
  /// analysis and updates the UI state to show the captured image
  ///
  /// @return Future that completes when image capture and processing is done
  Future<void> _pickImage() async {
    // Open camera to capture image
    final pickedFile = await _picker.pickImage(source: ImageSource.camera);

    // Process the captured image if available
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
        _result = 'Recognizing...';
      });

      // Send the image for analysis
      await analyzeImage(File(pickedFile.path));
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get responsive dimensions
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;

    return Stack(
      children: [
        // Background color layer
        Container(
          width: double.infinity,
          height: double.infinity,
          color: Background(context), // Uses theme-aware background color
        ),

        // Background image with overlay
        Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage("assets/Background.png"),
              fit: BoxFit.cover,
              colorFilter: ColorFilter.mode(
                Colors.black.withOpacity(0.3), // Semi-transparent overlay
                BlendMode.darken,
              ),
            ),
          ),
        ),

        // Main content scaffold
        Scaffold(
          backgroundColor: Colors.transparent, // Transparent to show background layers
          appBar: AppBar(
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
            padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.06),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  // Image preview section - only shown when an image is captured
                  if (_image != null)
                    Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: Image.file(
                            _image!,
                            height: screenHeight * 0.2, // Responsive height
                            width: screenWidth * 0.5,   // Responsive width
                            fit: BoxFit.cover,
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.01),
                      ],
                    ),

                  // Recognition result display
                  Text(
                    'Recognized Food: \n $_result\n\n(Warning : Scanning AI can make mistakes)',
                    style: TextStyle(
                        fontSize: screenHeight * 0.025,
                        color: BlackText(context)), // Theme-aware text color
                    textAlign: TextAlign.center,
                  ),

                  // Section divider
                  Divider(color: Colors.purple, thickness: 1),
                  SizedBox(height: screenHeight * 0.02),

                  // Camera button to capture food image
                  ElevatedButton.icon(
                    onPressed: _pickImage,
                    icon: Icon(Icons.camera_alt, color: Colors.white),
                    label: Text(
                      'Scan Food',
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      padding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.1,
                          vertical: screenHeight * 0.025),
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.03),

                  // Submit button to proceed with the recognized food
                  ElevatedButton(
                    onPressed: () {
                      // Validate that we have a recognition result
                      if (_result.isNotEmpty && _result != 'Recognizing...') {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Recognized Food: $_result')),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text('Please scan a food item first')),
                        );
                      }

                      // Navigate to processing screen with the result
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => Processing(foodName: _result),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: EdgeInsets.symmetric(
                        vertical: screenHeight * 0.02,
                        horizontal: screenWidth * 0.16,
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