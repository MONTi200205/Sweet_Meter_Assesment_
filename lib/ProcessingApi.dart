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
  bool isLoading = true;
  List<Product>? searchResults;
  String? errorMessage;

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
      // Standard search by food name - now gets results for selection
      fetchFoodSearchResults(widget.foodName);
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
      fetchFoodSearchResults(widget.foodName);

      // Alternative approach: If you have a barcode detection library that can
      // extract barcodes from images, you could implement that here and then call:
      // fetchProductDetails(detectedBarcode);
    } catch (e) {
      setState(() {
        errorMessage = 'Error processing image: $e';
        isLoading = false;
      });
    }
  }

  // New method to fetch search results for selection
  Future<void> fetchFoodSearchResults(String foodName, {int currentRetry = 0}) async {
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

      setState(() {
        if (searchResult.products != null && searchResult.products!.isNotEmpty) {
          searchResults = searchResult.products;
        } else {
          errorMessage = 'No products found for "${widget.foodName}".';
        }
        isLoading = false;
      });
    } catch (e) {
      // If we haven't hit our retry limit yet, try again
      if (currentRetry < maxRetries) {
        // Wait a bit before retrying to avoid potential rate limiting
        await Future.delayed(Duration(seconds: 1));
        return fetchFoodSearchResults(foodName, currentRetry: currentRetry + 1);
      }

      // If we've exhausted our retries or it's a permanent error, show error
      setState(() {
        errorMessage = 'An error occurred during the search: $e';
        isLoading = false;
      });
    }
  }

  // Process a selected product (either from search results or direct barcode)
  Future<void> processSelectedProduct(Product product) async {
    setState(() {
      isLoading = true;
    });

    if (product.nutriments != null) {
      processNutriments(product.nutriments!);
    } else if (product.barcode != null) {
      // If we don't have nutriment data, fetch by barcode
      await fetchProductDetails(product.barcode!);
    } else {
      setState(() {
        sugarLevel = 'No product information available.';
        isLoading = false;
      });
      navigateToResult(product.productName ?? widget.foodName);
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
          isLoading = false;
        });
        navigateToResult(widget.foodName);
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
        isLoading = false;
      });
      navigateToResult(widget.foodName);
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
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        sugarLevel = 'Error processing nutriment data: $e';
        isLoading = false;
      });
    }
  }

  void navigateToResult(String displayName) {
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
          backgroundColor: Colors.transparent,
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
          body: isLoading
              ? _buildLoadingView()
              : searchResults != null && !widget.isBarcode && !widget.isImage
              ? _buildSearchResultsList()
              : _buildErrorView(),
        ),
      ],
    );
  }

  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Colors.purple),
          SizedBox(height: 20),
          Text(
            widget.isBarcode
                ? 'Processing barcode ${widget.foodName}...'
                : widget.isImage
                ? 'Analyzing food image...'
                : 'Searching for ${widget.foodName}...',
            style: TextStyle(fontSize: 24, color: BlackText(context)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResultsList() {
    if (searchResults == null || searchResults!.isEmpty) {
      return Center(
        child: Text(
          errorMessage ?? 'No results found',
          style: TextStyle(fontSize: 18, color: BlackText(context)),
          textAlign: TextAlign.center,
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Select a product:',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: BlackText(context)),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: searchResults!.length,
            itemBuilder: (context, index) {
              final product = searchResults![index];
              return Card(
                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: product.imageFrontUrl != null && product.imageFrontUrl!.isNotEmpty
                      ? Image.network(
                    product.imageFrontUrl!,
                    width: 50,
                    height: 50,
                    errorBuilder: (context, error, stackTrace) =>
                        Icon(Icons.image_not_supported, size: 40),
                  )
                      : Icon(Icons.food_bank, size: 40),
                  title: Text(
                    product.productName ?? 'Unknown Product',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(product.brands ?? 'Unknown Brand'),
                  onTap: () {
                    // When a product is selected, process it
                    navigateToResult(product.productName ?? widget.foodName);
                    processSelectedProduct(product);
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 60, color: Colors.red),
            SizedBox(height: 16),
            Text(
              errorMessage ?? 'Connection Error!',
              style: TextStyle(fontSize: 20, color: BlackText(context)),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Go Back'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}