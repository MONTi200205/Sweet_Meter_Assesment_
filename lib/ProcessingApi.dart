import 'package:flutter/material.dart';
import 'dart:async'; // For delay
import 'dart:convert'; // For JSON parsing
import 'package:http/http.dart' as http;
import 'result.dart'; // Import Result screen

class Processing extends StatefulWidget {
  final String foodName;

  Processing({required this.foodName});

  @override
  _ProcessingState createState() => _ProcessingState();
}

class _ProcessingState extends State<Processing> {
  String? sugarLevel; // Variable to hold sugar level information

  @override
  void initState() {
    super.initState();
    fetchFoodData(widget.foodName);
  }

  Future<void> fetchFoodData(String foodName) async {
    final String searchApiUrl =
        'https://world.openfoodfacts.org/cgi/search.pl?search_terms=$foodName&search_simple=1&json=1';

    try {
      // Step 1: Search for the product name to get the barcode
      final searchResponse = await http.get(Uri.parse(searchApiUrl));

      if (searchResponse.statusCode == 200) {
        final searchData = json.decode(searchResponse.body);
        final List products = searchData['products'];

        if (products.isNotEmpty) {
          final barcode = products[0]['code']; // Get the first product's barcode

          // Step 2: Use the barcode to fetch detailed product information
          await fetchProductDetails(barcode);
        } else {
          setState(() {
            sugarLevel = 'No products found for "$foodName".';
          });
        }
      } else {
        setState(() {
          sugarLevel = 'Failed to search for products. Error: ${searchResponse.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        sugarLevel = 'An error occurred during the search: $e';
      });
    }
  }

  Future<void> fetchProductDetails(String barcode) async {
    final String productApiUrl = 'https://world.openfoodfacts.org/api/v0/product/$barcode.json';

    try {
      final productResponse = await http.get(Uri.parse(productApiUrl));

      if (productResponse.statusCode == 200) {
        final productData = json.decode(productResponse.body);

        if (productData['status'] == 1) {
          final product = productData['product'];
          final sugarContent = product['nutriments']?['sugars_100g'];

          setState(() {
            sugarLevel = sugarContent != null
                ? sugarContent.toString() + 'g per 100g'
                : 'No sugar information available.';
          });
        } else {
          setState(() {
            sugarLevel = 'Product not found in the database.';
          });
        }
      } else {
        setState(() {
          sugarLevel = 'Failed to fetch product details. Error: ${productResponse.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        sugarLevel = 'An error occurred while fetching product details: $e';
      });
    }

    // Navigate to Result screen after fetching product details
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => Result(
          foodName: widget.foodName,
          sugarLevel: sugarLevel ?? 'Unknown',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        title: Text('Processing'),
        backgroundColor: Colors.purple,
      ),
      body: Center(
        child: sugarLevel == null
            ? Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.purple),
            SizedBox(height: 20),
            Text(
              'Processing ${widget.foodName}...',
              style: TextStyle(fontSize: 24, color: Colors.white),
              textAlign: TextAlign.center,
            ),
          ],
        )
            : Text(
          'Processing complete!',
          style: TextStyle(fontSize: 24, color: Colors.white),
        ),
      ),
    );
  }
}