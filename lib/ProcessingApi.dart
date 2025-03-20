import 'package:flutter/material.dart';
import 'dart:async';
import 'package:openfoodfacts/openfoodfacts.dart';
import 'result.dart';
import 'home_screen.dart';
import 'package:sweet_meter_assesment/utils/Darkmode.dart';

class Processing extends StatefulWidget {
  final String foodName;
  final bool isBarcode; // Indicates if input is a barcode
  final bool isImage; // Indicates if input is an image
  final String? imagePath; // Path to the image file if using image analysis

  Processing({
    required this.foodName,
    this.isBarcode = false,
    this.isImage = false,
    this.imagePath,
  });

  @override
  _ProcessingState createState() => _ProcessingState();
}

class _ProcessingState extends State<Processing> {
  String? sugarLevel;
  int retryCount = 0;
  final int maxRetries = 2;

  @override
  void initState() {
    super.initState();
    // Set up the OpenFoodFacts configuration
    OpenFoodAPIConfiguration.userAgent = UserAgent(
      name: 'Sweet Meter Assessment',
    );

    // Process based on input type
    if (widget.isBarcode) {
      // Directly fetch product details by barcode
      fetchProductDetails(widget.foodName);
    } else if (widget.isImage && widget.imagePath != null) {
      // Process the food image
      processImageData(widget.imagePath!);
    } else {
      // Standard search by food name
      fetchFoodData(widget.foodName);
    }
  }

  Future<void> processImageData(String imagePath) async {
    try {
      // Here you would implement image analysis logic
      // For now, we'll demonstrate with a mock implementation

      // Simulate processing time
      await Future.delayed(Duration(seconds: 2));

      // For demonstration purposes, we'll just conduct a search based on the food name
      // In a real implementation, you would use image recognition to identify the food
      fetchFoodData(widget.foodName);

      // Alternative approach: If you have a barcode detection library that can
      // extract barcodes from images, you could implement that here and then call:
      // fetchProductDetails(detectedBarcode);
    } catch (e) {
      setState(() {
        sugarLevel = 'Error processing image: $e';
      });
      navigateToResult();
    }
  }

  Future<void> fetchFoodData(String foodName, {int currentRetry = 0}) async {
    try {
      // Create parameters for the search
      final parameters = <Parameter>[
        SearchTerms(terms: [foodName]),
      ];

      // Create the search configuration
      final configuration = ProductSearchQueryConfiguration(
        parametersList: parameters,
        fields: [ProductField.ALL],
        language: OpenFoodFactsLanguage.ENGLISH,
        version: ProductQueryVersion.v3,
      );

      // Search for products with parameters in the correct order
      final searchResult = await OpenFoodAPIClient.searchProducts(
        null, // First parameter is User? which can be null
        configuration, // Second parameter is the query configuration
      );

      if (searchResult.products != null && searchResult.products!.isNotEmpty) {
        final product = searchResult.products![0];

        // If we already have nutriments data from the search, use it
        if (product.nutriments != null) {
          processNutriments(product.nutriments!);
        } else if (product.barcode != null) {
          // Otherwise fetch detailed product info by barcode
          await fetchProductDetails(product.barcode!);
        } else {
          setState(() {
            sugarLevel = 'No product information available.';
          });
          navigateToResult();
        }
      } else {
        // No products found but request was successful
        setState(() {
          sugarLevel = 'No products found for "${widget.foodName}".';
        });
        navigateToResult();
      }
    } catch (e) {
      // If we haven't hit our retry limit yet, try again
      if (currentRetry < maxRetries) {
        // Wait a bit before retrying to avoid potential rate limiting
        await Future.delayed(Duration(seconds: 1));
        return fetchFoodData(foodName, currentRetry: currentRetry + 1);
      }

      // If we've exhausted our retries or it's a permanent error, show error
      setState(() {
        sugarLevel = 'An error occurred during the search: $e';
      });
      navigateToResult();
    }
  }

  Future<void> fetchProductDetails(String barcode, {int currentRetry = 0}) async {
    try {
      // Get product by barcode
      final productQueryConfiguration = ProductQueryConfiguration(
        barcode,
        version: ProductQueryVersion.v3,
        language: OpenFoodFactsLanguage.ENGLISH,
        fields: [ProductField.NUTRIMENTS],
      );

      // Call with correct parameter order
      final productResult = await OpenFoodAPIClient.getProductV3(
        productQueryConfiguration,
      );

      if (productResult.product != null && productResult.product!.nutriments != null) {
        processNutriments(productResult.product!.nutriments!);
      } else {
        setState(() {
          sugarLevel = 'No sugar information available for this product.';
        });
        navigateToResult();
      }
    } catch (e) {
      // If we haven't hit our retry limit yet, try again
      if (currentRetry < maxRetries) {
        // Wait a bit before retrying
        await Future.delayed(Duration(seconds: 1));
        return fetchProductDetails(barcode, currentRetry: currentRetry + 1);
      }

      setState(() {
        sugarLevel = 'An error occurred while fetching product details: $e';
      });
      navigateToResult();
    }
  }

  void processNutriments(Nutriments nutriments) {
    try {
      // Try to get sugar content using various approaches
      double? sugarsValue;

      // Try to get sugars using the standard method
      try {
        sugarsValue = nutriments.getValue(Nutrient.sugars, PerSize.oneHundredGrams);
      } catch (e) {
        // If that fails, try to access the value directly from the map
        final Map<String, dynamic>? nutrientsMap = nutriments.toJson();
        if (nutrientsMap != null) {
          // Try various potential key names for sugar content
          final possibleSugarKeys = [
            'sugars_100g',
            'sugars',
            'sugar_100g',
            'sugar'
          ];

          for (final key in possibleSugarKeys) {
            if (nutrientsMap.containsKey(key) && nutrientsMap[key] != null) {
              final value = nutrientsMap[key];
              if (value is num) {
                sugarsValue = value.toDouble();
                break;
              } else if (value is String) {
                sugarsValue = double.tryParse(value);
                if (sugarsValue != null) break;
              }
            }
          }
        }
      }

      setState(() {
        if (sugarsValue != null) {
          sugarLevel = '${sugarsValue.toString()}g per 100g';
        } else {
          sugarLevel = 'No sugar information available.';
        }
      });
    } catch (e) {
      setState(() {
        sugarLevel = 'Error processing nutriment data: $e';
      });
    }
    navigateToResult();
  }

  void navigateToResult() {
    String displayName;

    if (widget.isBarcode) {
      displayName = "Product with barcode: ${widget.foodName}";
    } else if (widget.isImage) {
      displayName = "Analyzed food image: ${widget.foodName}";
    } else {
      displayName = widget.foodName;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => Result(
          foodName: displayName,
          sugarLevel: sugarLevel ?? 'Unknown',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
          body: Center(
            child: sugarLevel == null
                ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: Colors.purple),
                SizedBox(height: 20),
                Text(
                  widget.isBarcode
                      ? 'Processing barcode ${widget.foodName}...'
                      : widget.isImage
                      ? 'Analyzing food image...'
                      : 'Processing ${widget.foodName}...',
                  style: TextStyle(fontSize: 24, color: BlackText(context)),
                  textAlign: TextAlign.center,
                ),
              ],
            )
                : Text(
              'Connection Error !',
              style: TextStyle(fontSize: 24, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}