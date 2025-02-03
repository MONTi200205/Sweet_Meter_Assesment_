import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'ProcessingApi.dart';
import 'package:sweet_meter_assesment/utils/Darkmode.dart';
import 'home_screen.dart';

class ScanFood extends StatefulWidget {
  @override
  _ScanFoodState createState() => _ScanFoodState();
}

class _ScanFoodState extends State<ScanFood> {
  final ImagePicker _picker = ImagePicker();
  File? _image;
  String _result = "Image recognition result will appear here.";
  final String apiKey = 'acc_52851fb94a70f06'; // Imagga API key
  final String apiSecret =
      'edd380e1dbd0b5d4c36e7000215e6285'; // r Imagga API secret

  Future<void> analyzeImage(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    String base64Image = base64Encode(bytes);

    final url = Uri.parse('https://api.imagga.com/v2/tags');
    final headers = {
      'Authorization':
          'Basic ' + base64Encode(utf8.encode('$apiKey:$apiSecret')),
    };

    final request = http.MultipartRequest('POST', url)
      ..headers.addAll(headers)
      ..files.add(
          http.MultipartFile.fromBytes('image', bytes, filename: 'image.jpg'));

    final response = await request.send();

    if (response.statusCode == 200) {
      final responseData = await http.Response.fromStream(response);
      final data = json.decode(responseData.body);

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
      setState(() {
        _result =
            'Failed to recognize the image. Status code: ${response.statusCode}';
      });
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.camera);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
        _result = 'Recognizing...';
      });

      await analyzeImage(File(pickedFile.path));
    }
  }

  @override
  Widget build(BuildContext context) {
    // Fetch screen width and height
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;

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
            padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.06),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  if (_image != null)
                    Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(
                              15), // Set the border radius here
                          child: Image.file(
                            _image!,
                            height: screenHeight * 0.2, // Dynamic height
                            width: screenWidth * 0.5, // Dynamic width
                            fit: BoxFit.cover,
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.01),
                      ],
                    ),
                  Text(
                    'Recognized Food: \n $_result',
                    style: TextStyle(
                        fontSize: screenHeight * 0.025,
                        color: BlackText(context)), // Dynamic font size
                    textAlign: TextAlign.center,
                  ),
                  Divider(color: Colors.purple, thickness: 1),
                  SizedBox(height: screenHeight * 0.02),
                  ElevatedButton.icon(
                    onPressed: _pickImage,
                    icon: Icon(Icons.camera_alt,color:Colors.white,),
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
                  ElevatedButton(
                    onPressed: () {
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
