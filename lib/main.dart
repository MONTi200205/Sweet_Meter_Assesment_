import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'login_screen.dart';
import 'firebase_options.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:sweet_meter_assesment/utils/scaling_utils.dart';
import 'splash_screen.dart'; // Import the new splash screen

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await initializeScaling();
  // Initialize Facebook Auth for web
  if (kIsWeb) {
    await FacebookAuth.instance.webAndDesktopInitialize(
      appId: "1652075802379061",
      cookie: true,
      xfbml: true,
      version: "v15.0",
    );
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Sweet Meter',
      theme: ThemeData(
        primarySwatch: Colors.purple,
        primaryColor: const Color(0xFFE91E63),
        scaffoldBackgroundColor: const Color(0xFFF3E5F5), // Light purple background
        colorScheme: ColorScheme.fromSwatch().copyWith(
          primary: const Color(0xFFE91E63),
          secondary: const Color(0xFFE91E63),
          background: const Color(0xFFF3E5F5), // Light purple background
        ),
      ),
      home: const SplashScreen(), // Start with splash screen instead of login
    );
  }
}