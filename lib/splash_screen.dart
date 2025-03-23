import 'package:flutter/material.dart';
import 'dart:async';
import 'login_screen.dart';
import 'package:sweet_meter_assesment/utils/Darkmode.dart';
import 'package:sweet_meter_assesment/utils/scaling_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeInAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // Load scaling preference
    loadScalePreference().then((value) {
      if (mounted) {
        setState(() {
          // This is now handled by the scaling_utils.dart
        });
      }
    });

    // Set up animations
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _fadeInAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Interval(0.0, 0.65, curve: Curves.easeInOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Interval(0.0, 0.65, curve: Curves.easeInOut),
      ),
    );

    // Start animation
    _animationController.forward();

    // Navigate to login screen after delay
    Timer(const Duration(milliseconds: 3000), () {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // Function to load scale preference from SharedPreferences
  Future<double> loadScalePreference() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble('scaleFactor') ?? 1.0;
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final screenWidth = size.width;
    final screenHeight = size.height;
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    return Stack(
      children: [
        // Background Color
        Container(
          width: double.infinity,
          height: double.infinity,
          color: Background(context),
        ),
        // Background Image with Overlay
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
          body: Center(
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return FadeTransition(
                  opacity: _fadeInAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // App Logo with web/mobile detection - no white circle
                        kIsWeb
                            ? Image.network(
                          'assets/sweetmeter.png',
                          width: scaled(isLandscape ? screenHeight * 0.4 : screenWidth * 0.5),
                          height: scaled(isLandscape ? screenHeight * 0.4 : screenWidth * 0.5),
                          errorBuilder: (context, error, stackTrace) {
                            // Fallback if image fails to load
                            return Icon(
                              Icons.health_and_safety,
                              size: scaled(isLandscape ? screenHeight * 0.3 : screenWidth * 0.4),
                              color: Colors.purple,
                            );
                          },
                        )
                            : Image.asset(
                          'assets/sweetmeter.png',
                          width: scaled(isLandscape ? screenHeight * 0.4 : screenWidth * 0.5),
                          height: scaled(isLandscape ? screenHeight * 0.4 : screenWidth * 0.5),
                        ),

                        SizedBox(height: scaled(screenHeight * 0.04)),

                        // App Name
                        Text(
                          "SWEET METER",
                          style: TextStyle(
                            fontFamily: 'Agbalumo',
                            fontSize: scaled(isLandscape ? screenHeight * 0.05 : screenWidth * 0.08),
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),

                        SizedBox(height: scaled(screenHeight * 0.02)),

                        // Tagline - without purple container
                        Text(
                          'Control sugar',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: scaled(isLandscape ? screenHeight * 0.025 : screenWidth * 0.04),
                            fontStyle: FontStyle.italic,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}