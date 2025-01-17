import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'ProcessingApi.dart';

class ScanFood extends StatefulWidget {
  @override
  _ScanFoodState createState() => _ScanFoodState();
}

class _ScanFoodState extends State<ScanFood> {
  final ImagePicker _picker = ImagePicker();
  File? _image;
  String _result = "Image recognition result will appear here.";
  final String apiKey = 'acc_52851fb94a70f06'; // Replace with your Imagga API key
  final String apiSecret = 'edd380e1dbd0b5d4c36e7000215e6285'; // Replace with your Imagga API secret

  Future<void> analyzeImage(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    String base64Image = base64Encode(bytes);

    final url = Uri.parse('https://api.imagga.com/v2/tags');
    final headers = {
      'Authorization': 'Basic ' + base64Encode(utf8.encode('$apiKey:$apiSecret')),
    };

    final request = http.MultipartRequest('POST', url)
      ..headers.addAll(headers)
      ..files.add(http.MultipartFile.fromBytes('image', bytes, filename: 'image.jpg'));

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
        _result = 'Failed to recognize the image. Status code: ${response.statusCode}';
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
    return Scaffold(
      appBar: AppBar(
        title: Text('Food Recognition with Imagga'),
        backgroundColor: Colors.purple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (_image != null)
              Column(
                children: [
                  Image.file(
                    _image!,
                    height: 200,
                    width: 200,
                    fit: BoxFit.cover,
                  ),
                  SizedBox(height: 10),
                ],
              ),
            Text(
              'Recognized Food: $_result',
              style: TextStyle(fontSize: 20, color: Colors.black),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _pickImage,
              icon: Icon(Icons.camera_alt),
              label: Text('Scan Food'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              ),
            ),
            SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                if (_result.isNotEmpty && _result != 'Recognizing...') {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Recognized Food: $_result')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Please scan a food item first')),
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
                padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
              ),
              child: Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }
}