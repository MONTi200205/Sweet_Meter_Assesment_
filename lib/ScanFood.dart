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

  final String openAiApiKey = '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';

  Future<void> analyzeImage(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    String base64Image = base64Encode(bytes);

    final url = Uri.parse('https://api.openai.com/v1/chat/completions');
    final headers = {
      'Authorization': 'Bearer $openAiApiKey',
      'Content-Type': 'application/json',
    };

    final body = jsonEncode({
      "model": "gpt-4-vision-preview",
      "messages": [
        {
          "role": "system",
          "content": "You are a food recognition assistant. Identify the food item in the given image."
        },
        {
          "role": "user",
          "content": [
            {"type": "text", "text": "What food is in this image? Provide only the name."},
            {"type": "image_url", "image_url": "data:image/jpeg;base64,$base64Image"}
          ]
        }
      ],
      "max_tokens": 50
    });

    final response = await http.post(url, headers: headers, body: body);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['choices'] != null && data['choices'][0]['message']['content'] != null) {
        setState(() {
          _result = data['choices'][0]['message']['content'].trim();
        });
      } else {
        setState(() {
          _result = 'No food items detected.';
        });
      }
    } else {
      setState(() {
        _result = 'Failed to recognize the image. Try again.';
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
                          borderRadius: BorderRadius.circular(15),
                          child: Image.file(
                            _image!,
                            height: screenHeight * 0.2,
                            width: screenWidth * 0.5,
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
                        color: BlackText(context)),
                    textAlign: TextAlign.center,
                  ),
                  Divider(color: Colors.purple, thickness: 1),
                  SizedBox(height: screenHeight * 0.02),
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