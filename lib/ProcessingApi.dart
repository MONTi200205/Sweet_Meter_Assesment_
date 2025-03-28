import 'package:flutter/material.dart';
import 'dart:async';
import 'package:openfoodfacts/openfoodfacts.dart';
import 'result.dart';
import 'home_screen.dart';
import 'package:sweet_meter_assesment/utils/Darkmode.dart';

/// Screen for processing food search queries and retrieving nutritional information
///
/// This widget handles different input methods (text search, barcode scanning, image analysis)
/// to retrieve sugar content information from the OpenFoodFacts database.
/// It shows appropriate loading states, search results, or error messages based on
/// the search outcome.
class Processing extends StatefulWidget {
  /// Name of the food item to search for
  final String foodName;

  /// Whether the input is a barcode scan
  final bool isBarcode;

  /// Whether the input is from an image analysis
  final bool isImage;

  /// File path to the analyzed image (if applicable)
  final String? imagePath;

  /// Creates a Processing screen instance
  ///
  /// @param foodName The name or barcode of the food to process
  /// @param isBarcode Whether the input is a barcode instead of a food name
  /// @param isImage Whether the input is coming from an image analysis
  /// @param imagePath Path to the image file if using image analysis
  Processing({
    required this.foodName,
    this.isBarcode = false,
    this.isImage = false,
    this.imagePath,
  });

  @override
  _ProcessingState createState() => _ProcessingState();
}

/// State class for the Processing screen
///
/// Manages API calls, search processing, and UI state transitions
class _ProcessingState extends State<Processing> {
  /// Sugar content information retrieved from API
  String? sugarLevel;

  /// Number of API call attempts made
  int retryCount = 0;

  /// Maximum number of retry attempts for API calls
  final int maxRetries = 2;

  /// Whether the screen is in a loading state
  bool isLoading = true;

  /// List of search results from OpenFoodFacts
  List<Product>? searchResults;

  /// Error message to display if something goes wrong
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    // Set up the OpenFoodFacts configuration with app identifier
    OpenFoodAPIConfiguration.userAgent = UserAgent(
      name: 'Sweet Meter Assessment',
    );

    // Choose processing method based on input type
    if (widget.isBarcode) {
      // Directly fetch product details by barcode
      fetchProductDetails(widget.foodName);
    } else if (widget.isImage && widget.imagePath != null) {
      // Process the food image
      processImageData(widget.imagePath!);
    } else {
      // Standard search by food name - returns results for selection
      fetchFoodSearchResults(widget.foodName);
    }
  }

  /// Processes an image to identify food items
  ///
  /// Currently a placeholder implementation that defaults to text search
  /// In a real implementation, this would use image recognition to identify food
  ///
  /// @param imagePath Path to the image file to process
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

  /// Fetches search results from OpenFoodFacts based on food name
  ///
  /// Searches the OpenFoodFacts database for matching products and
  /// updates the UI with the results or an error message
  ///
  /// @param foodName The name of the food to search for
  /// @param currentRetry Current retry attempt number for handling failures
  Future<void> fetchFoodSearchResults(String foodName, {int currentRetry = 0}) async {
    try {
      // Create parameters for the search query
      final parameters = <Parameter>[
        SearchTerms(terms: [foodName]), // Search terms parameter
      ];

      // Create the search configuration with fields and language
      final configuration = ProductSearchQueryConfiguration(
        parametersList: parameters,
        fields: [ProductField.ALL], // Request all fields for comprehensive data
        language: OpenFoodFactsLanguage.ENGLISH,
        version: ProductQueryVersion.v3,
      );

      // Search for products with the specified parameters
      final searchResult = await OpenFoodAPIClient.searchProducts(
        null, // First parameter is User? which can be null
        configuration, // Second parameter is the query configuration
      );

      // Update UI state with search results
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

  /// Processes a product selected from search results
  ///
  /// Extracts nutritional information from the selected product
  /// or fetches additional details if needed
  ///
  /// @param product The selected OpenFoodFacts product
  Future<void> processSelectedProduct(Product product) async {
    setState(() {
      isLoading = true; // Show loading indicator while processing
    });

    if (product.nutriments != null) {
      // If the product already has nutriment data, process it directly
      processNutriments(product.nutriments!);
    } else if (product.barcode != null) {
      // If we don't have nutriment data but have a barcode, fetch by barcode
      await fetchProductDetails(product.barcode!);
    } else {
      // If we can't get any nutriment data, show a message
      setState(() {
        sugarLevel = 'No product information available.';
        isLoading = false;
      });
      navigateToResult(product.productName ?? widget.foodName);
    }
  }

  /// Fetches detailed product information by barcode
  ///
  /// Makes an API request to retrieve complete product details
  /// and extracts nutrient information
  ///
  /// @param barcode The product barcode to look up
  /// @param currentRetry Current retry attempt number
  Future<void> fetchProductDetails(String barcode, {int currentRetry = 0}) async {
    try {
      // Configure product query with the barcode
      final productQueryConfiguration = ProductQueryConfiguration(
        barcode,
        version: ProductQueryVersion.v3,
        language: OpenFoodFactsLanguage.ENGLISH,
        fields: [ProductField.NUTRIMENTS], // Request nutriment data specifically
      );

      // Fetch product details from the API
      final productResult = await OpenFoodAPIClient.getProductV3(
        productQueryConfiguration,
      );

      // Extract and process nutriment data if available
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
      // Retry logic for transient failures
      if (currentRetry < maxRetries) {
        // Wait before retrying to avoid overwhelming the API
        await Future.delayed(Duration(seconds: 1));
        return fetchProductDetails(barcode, currentRetry: currentRetry + 1);
      }

      // Update UI with error message after exhausting retries
      setState(() {
        sugarLevel = 'An error occurred while fetching product details: $e';
        isLoading = false;
      });
      navigateToResult(widget.foodName);
    }
  }

  /// Extracts sugar content information from nutriment data
  ///
  /// Attempts to find sugar content using various approaches
  /// to handle different data formats in the OpenFoodFacts API
  ///
  /// @param nutriments The nutriment data from the OpenFoodFacts API
  void processNutriments(Nutriments nutriments) {
    try {
      // Try to get sugar content using various approaches
      double? sugarsValue;

      // Try to get sugars using the standard method first
      try {
        sugarsValue = nutriments.getValue(Nutrient.sugars, PerSize.oneHundredGrams);
      } catch (e) {
        // If standard method fails, try to access the value directly from the map
        final Map<String, dynamic>? nutrientsMap = nutriments.toJson();
        if (nutrientsMap != null) {
          // Try various potential key names for sugar content
          // OpenFoodFacts data can be inconsistent in naming
          final possibleSugarKeys = [
            'sugars_100g',
            'sugars',
            'sugar_100g',
            'sugar'
          ];

          // Check each possible key until we find a valid sugar value
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

      // Update the UI with the sugar information
      setState(() {
        if (sugarsValue != null) {
          sugarLevel = '${sugarsValue.toString()}g per 100g';
        } else {
          sugarLevel = 'No sugar information available.';
        }
        isLoading = false;
      });
    } catch (e) {
      // Handle any errors during nutriment processing
      setState(() {
        sugarLevel = 'Error processing nutriment data: $e';
        isLoading = false;
      });
    }
  }

  /// Navigates to the result screen with the processed information
  ///
  /// @param displayName The name of the food to display on the result screen
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
        // Background color layer
        Container(
          width: double.infinity,
          height: double.infinity,
          color: Background(context), // Uses the theme-aware background color
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
                Colors.black.withOpacity(0.3),
                BlendMode.darken,
              ),
            ),
          ),
        ),

        // Main UI content
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
          // Conditional UI based on current state
          body: isLoading
              ? _buildLoadingView() // Show loading spinner during API requests
              : searchResults != null && !widget.isBarcode && !widget.isImage
              ? _buildSearchResultsList() // Show search results if available
              : _buildErrorView(), // Show error view if something went wrong
        ),
      ],
    );
  }

  /// Builds the loading state view with appropriate message
  ///
  /// Shows a spinner and contextual loading message based on input type
  ///
  /// @return Widget displaying the loading state
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

  /// Builds the search results list view
  ///
  /// Shows a scrollable list of food products matching the search
  /// with images and selectable items
  ///
  /// @return Widget displaying the search results
  Widget _buildSearchResultsList() {
    // Show message if no results found
    if (searchResults == null || searchResults!.isEmpty) {
      return Center(
        child: Text(
          errorMessage ?? 'No results found',
          style: TextStyle(fontSize: 18, color: BlackText(context)),
          textAlign: TextAlign.center,
        ),
      );
    }

    // Build the list of search results
    return Column(
      children: [
        // Header section
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Select a product:',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: BlackText(context)),
          ),
        ),
        // Scrollable product list
        Expanded(
          child: ListView.builder(
            itemCount: searchResults!.length,
            itemBuilder: (context, index) {
              final product = searchResults![index];
              return Card(
                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  // Product image if available
                  leading: product.imageFrontUrl != null && product.imageFrontUrl!.isNotEmpty
                      ? Image.network(
                    product.imageFrontUrl!,
                    width: 50,
                    height: 50,
                    errorBuilder: (context, error, stackTrace) =>
                        Icon(Icons.image_not_supported, size: 40),
                  )
                      : Icon(Icons.food_bank, size: 40),
                  // Product name and brand
                  title: Text(
                    product.productName ?? 'Unknown Product',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(product.brands ?? 'Unknown Brand'),
                  // Handle product selection
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

  /// Builds the error state view
  ///
  /// Shows an error message and a button to go back
  ///
  /// @return Widget displaying the error state
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