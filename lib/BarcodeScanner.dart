import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'ProcessingApi.dart';
import 'home_screen.dart';
import 'package:sweet_meter_assesment/utils/Darkmode.dart';

/// A screen that provides barcode scanning functionality for food products
/// Allows users to scan product barcodes and sends the results for processing
class BarcodeScanner extends StatefulWidget {
  @override
  _BarcodeScannerState createState() => _BarcodeScannerState();
}

class _BarcodeScannerState extends State<BarcodeScanner> {
  // Tracks the current barcode scan result
  String _scanBarcode = 'Scan a barcode';

  // Indicates if scanning is in progress
  bool _isScanning = false;

  @override
  void initState() {
    super.initState();
  }

  /// Handles the barcode scanning process
  ///
  /// Uses the device camera to scan barcodes and processes the result
  /// Including error handling and navigation to the processing screen
  Future<void> scanBarcodeNormal() async {
    String barcodeScanRes;

    // Platform messages may fail, so we use a try/catch PlatformException
    try {
      setState(() {
        _isScanning = true;
      });

      // Initiate the barcode scanner with customized UI colors
      barcodeScanRes = await FlutterBarcodeScanner.scanBarcode(
          '#ff6666', 'Cancel', true, ScanMode.BARCODE);

      if (barcodeScanRes != '-1') {
        // Valid barcode scanned (-1 indicates user cancellation)
        setState(() {
          _scanBarcode = barcodeScanRes;
        });
      } else {
        // User canceled the scanning process
        setState(() {
          _scanBarcode = 'Scan canceled';
        });
      }
    } on PlatformException {
      barcodeScanRes = 'Failed to get platform version.';
    } catch (e) {
      barcodeScanRes = 'Error: $e';
    }

    // Prevent setState calls if widget is disposed during async operation
    if (!mounted) return;

    setState(() {
      _isScanning = false;
      _scanBarcode = barcodeScanRes;
    });

    // Process valid barcode results by navigating to processing screen
    if (barcodeScanRes != '-1' &&
        barcodeScanRes != 'Scan canceled' &&
        !barcodeScanRes.startsWith('Error:') &&
        !barcodeScanRes.startsWith('Failed')) {
      navigateToProcessing(barcodeScanRes);
    }
  }

  /// Navigates to the food processing screen with the scanned barcode
  ///
  /// @param barcode The scanned barcode to be processed
  void navigateToProcessing(String barcode) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Processing(
          foodName: barcode,
          isBarcode: true,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;

    return Stack(
      children: [
        // Background color layer
        Container(
          width: double.infinity,
          height: double.infinity,
          color: Background(context),
        ),

        // Background image with overlay for visual appeal
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

        // Main content scaffold
        Scaffold(
          backgroundColor: Background(context),
          appBar: AppBar(
            // Back button to return to previous screen
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
          body: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.06),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    // Screen title
                    Text(
                      'Scan Product Barcode',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: Colors.purple,
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.01),
                    Divider(color: Colors.purple, thickness: 1),

                    // Barcode result display container
                    Container(
                      width: screenWidth * 0.8,
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.purple, width: 2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          // Barcode icon
                          Icon(
                            Icons.qr_code,
                            size: 64,
                            color: Colors.purple,
                          ),
                          SizedBox(height: 10),
                          // Label for scanned barcode
                          Text(
                            'Scanned Barcode:',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: BlackText(context),
                            ),
                          ),
                          SizedBox(height: 5),
                          // Barcode value display with conditional text
                          Text(
                            _scanBarcode == '-1'
                                ? 'No barcode scanned'
                                : _scanBarcode,
                            style: TextStyle(
                              fontSize: 16,
                              color: BlackText(context),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: screenHeight * 0.03),

                    // Scan initiation button - disabled during active scanning
                    ElevatedButton.icon(
                      onPressed: _isScanning ? null : scanBarcodeNormal,
                      icon: Icon(Icons.qr_code_scanner, color: Colors.white),
                      label: Text(
                        'Scan Barcode',
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: EdgeInsets.symmetric(
                          vertical: screenHeight * 0.02,
                          horizontal: screenWidth * 0.1,
                        ),
                      ),
                    ),

                    SizedBox(height: screenHeight * 0.02),

                    // Submit button - only enabled with valid barcode
                    ElevatedButton(
                      onPressed: (_scanBarcode != 'Scan a barcode' &&
                          _scanBarcode != '-1' &&
                          _scanBarcode != 'Scan canceled' &&
                          !_scanBarcode.startsWith('Error:') &&
                          !_scanBarcode.startsWith('Failed'))
                          ? () => navigateToProcessing(_scanBarcode)
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: EdgeInsets.symmetric(
                          vertical: screenHeight * 0.02,
                          horizontal: screenWidth * 0.2,
                        ),
                        disabledBackgroundColor: Colors.grey,
                      ),
                      child: Text(
                        'Submit',
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
                    ),

                    // Loading indicator displayed during scanning
                    if (_isScanning)
                      CircularProgressIndicator(color: Colors.purple),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}