/// SignUpScreen.dart
///
/// A Flutter screen that handles user registration with email verification.
/// This screen provides a responsive UI with different layouts for portrait and landscape orientations.
/// It includes form validation, Firebase authentication, and email verification functionality.

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sweet_meter_assesment/utils/Darkmode.dart';

/// A StatefulWidget that provides the user registration interface with email verification.
/// This screen adapts its layout based on device orientation and screen size.
class SignUpScreen extends StatefulWidget {
  const SignUpScreen({Key? key}) : super(key: key);

  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

/// The state management class for SignUpScreen.
/// Handles user input, form validation, and the registration process.
class _SignUpScreenState extends State<SignUpScreen> {
  /// Controller for the email input field
  final TextEditingController _emailController = TextEditingController();

  /// Controller for the password input field
  final TextEditingController _passwordController = TextEditingController();

  /// Controller for the password confirmation input field
  final TextEditingController _confirmPasswordController = TextEditingController();

  /// Flag indicating whether an authentication operation is in progress
  bool _isLoading = false;

  /// Handles the user registration process and email verification flow.
  ///
  /// Validates input, creates a Firebase user account, and sends a verification email.
  /// Shows appropriate messages for success or failure conditions.
  Future<void> _signUp() async {
    setState(() {
      _isLoading = true;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    // Validate password match
    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Passwords do not match")),
      );
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      // Create the user account in Firebase
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Send verification email to the user
      await userCredential.user!.sendEmailVerification();

      setState(() {
        _isLoading = false;
      });

      // Show verification instructions
      _showVerificationDialog();

    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  /// Displays a dialog informing the user about the email verification requirement.
  ///
  /// Shows information about the verification process and next steps.
  /// This dialog is not dismissible to ensure the user acknowledges the information.
  void _showVerificationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Verify Your Email"),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text("A verification link has been sent to ${_emailController.text}"),
                const SizedBox(height: 10),
                const Text("Please check your email and click on the link to verify your account."),
                const SizedBox(height: 10),
                const Text("You won't be able to log in until you verify your email."),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pop(); // Go back to login screen
              },
            ),
          ],
        );
      },
    );
  }

  /// Builds the main UI for the SignUpScreen.
  ///
  /// @param context The BuildContext for this widget
  /// @return A Widget representing the complete screen UI
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // Background image
          Container(
            width: size.width,
            height: size.height,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/log.jpg"),
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Purple gradient overlay for visual aesthetics
          Container(
            width: size.width,
            height: size.height,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.purple, Colors.transparent],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                stops: [0.1, 0.9],
              ),
            ),
          ),
          // Dark mode compatibility layer
          Container(
            width: size.width,
            height: size.height,
            color: Tinting(context),
          ),
          // Responsive layout based on device orientation
          isLandscape
              ? _buildLandscapeLayout(context, size)
              : _buildPortraitLayout(context, size),

          // Loading overlay during authentication
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Builds the portrait layout optimized for vertical screens.
  ///
  /// @param context The current build context
  /// @param size The size of the current screen
  /// @return A widget containing the portrait-oriented UI
  Widget _buildPortraitLayout(BuildContext context, Size size) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: size.width * 0.05),
          child: Column(
            children: [
              SizedBox(height: size.height * 0.05),
              // App title
              Center(
                child: Text(
                  "SWEET METER",
                  style: TextStyle(
                    fontFamily: 'Agbalumo',
                    fontSize: size.width * 0.1,
                    fontWeight: FontWeight.bold,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ),
              SizedBox(height: size.height * 0.05),
              // Registration form
              _buildSignUpForm(context, size, isPortrait: true),
              SizedBox(height: size.height * 0.05),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds the landscape layout with a two-column design.
  ///
  /// @param context The current build context
  /// @param size The size of the current screen
  /// @return A widget containing the landscape-oriented UI with two columns
  Widget _buildLandscapeLayout(BuildContext context, Size size) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            size.width * 0.05,
            size.height * 0.02,
            size.width * 0.05,
            size.height * 0.02,
          ),
          child: Column(
            children: [
              // App title with larger font for landscape
              Padding(
                padding: EdgeInsets.only(bottom: size.height * 0.02),
                child: Text(
                  "SWEET METER",
                  style: TextStyle(
                    fontFamily: 'Agbalumo',
                    fontSize: size.width * 0.12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ),

              // Vertical spacing
              SizedBox(height: size.height * 0.15),

              // Two-column layout
              Padding(
                padding: EdgeInsets.only(bottom: size.height * 0.02),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Registration form column
                    Expanded(
                      flex: 6,
                      child: _buildCompactSignUpForm(context, size),
                    ),
                    SizedBox(width: size.width * 0.04),
                    // Welcome information column
                    Expanded(
                      flex: 4,
                      child: _buildCompactInfoPanel(context, size),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds a compact sign-up form optimized for landscape mode.
  ///
  /// @param context The current build context
  /// @param size The size of the current screen
  /// @return A widget containing the compact form with smaller font sizes and spacing
  Widget _buildCompactSignUpForm(BuildContext context, Size size) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Email field
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: "Email",
            labelStyle: TextStyle(
              color: Colors.white,
              fontSize: size.width * 0.016,
            ),
            enabledBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white),
            ),
          ),
        ),
        SizedBox(height: size.height * 0.008),
        // Password field
        TextField(
          controller: _passwordController,
          obscureText: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: "Password",
            labelStyle: TextStyle(
              color: Colors.white,
              fontSize: size.width * 0.016,
            ),
            enabledBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white),
            ),
          ),
        ),
        SizedBox(height: size.height * 0.008),
        // Password confirmation field
        TextField(
          controller: _confirmPasswordController,
          obscureText: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: "Confirm Password",
            labelStyle: TextStyle(
              color: Colors.white,
              fontSize: size.width * 0.016,
            ),
            enabledBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white),
            ),
          ),
        ),
        SizedBox(height: size.height * 0.012),
        // Sign up button
        SizedBox(
          width: size.width * 0.25,
          height: size.height * 0.06,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _signUp,
            child: Text(
              "Sign Up",
              style: TextStyle(
                fontSize: size.width * 0.016,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Builds a welcome message and additional options panel for landscape mode.
  ///
  /// @param context The current build context
  /// @param size The size of the current screen
  /// @return A widget containing welcome information and navigation options
  Widget _buildCompactInfoPanel(BuildContext context, Size size) {
    return Container(
      padding: EdgeInsets.all(size.height * 0.015),
      decoration: BoxDecoration(
        color: Colors.black12,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white30, width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Welcome icon
          Icon(
            Icons.person_add_rounded,
            color: Colors.white,
            size: size.width * 0.025,
          ),
          SizedBox(height: size.height * 0.008),
          // Panel title
          Text(
            "Join Us!",
            style: TextStyle(
              color: Colors.white,
              fontSize: size.width * 0.02,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: size.height * 0.008),
          // Welcome message explaining the signup process
          Text(
            "Welcome to Sweet Meter! Create your account to track preferences and personalize your experience. We'll send a verification email to confirm your account.",
            style: TextStyle(
              color: Colors.white70,
              fontSize: size.width * 0.012,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: size.height * 0.015),
          // Visual divider
          Divider(
            thickness: 1,
            color: Colors.white24,
          ),
          SizedBox(height: size.height * 0.008),
          // Login alternative message
          Text(
            "Already have an account?",
            style: TextStyle(
              color: Colors.white70,
              fontSize: size.width * 0.014,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: size.height * 0.008),
          // Navigate to login button
          SizedBox(
            width: double.infinity,
            height: size.height * 0.06,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple.withOpacity(0.6),
              ),
              child: Text(
                "Log In",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: size.width * 0.014,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the standard sign-up form used primarily in portrait mode.
  ///
  /// @param context The current build context
  /// @param size The size of the current screen
  /// @param isPortrait Flag indicating whether the current orientation is portrait
  /// @return A widget containing the standard form with appropriate sizing
  Widget _buildSignUpForm(BuildContext context, Size size, {required bool isPortrait}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Email field
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: "Email",
            labelStyle: TextStyle(
              color: Colors.white,
              fontSize: isPortrait ? size.width * 0.04 : size.width * 0.02,
            ),
            enabledBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white),
            ),
          ),
        ),
        SizedBox(height: isPortrait ? size.height * 0.02 : size.height * 0.01),
        // Password field
        TextField(
          controller: _passwordController,
          obscureText: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: "Password",
            labelStyle: TextStyle(
              color: Colors.white,
              fontSize: isPortrait ? size.width * 0.04 : size.width * 0.02,
            ),
            enabledBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white),
            ),
          ),
        ),
        SizedBox(height: isPortrait ? size.height * 0.02 : size.height * 0.01),
        // Password confirmation field
        TextField(
          controller: _confirmPasswordController,
          obscureText: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: "Confirm Password",
            labelStyle: TextStyle(
              color: Colors.white,
              fontSize: isPortrait ? size.width * 0.04 : size.width * 0.02,
            ),
            enabledBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white),
            ),
          ),
        ),
        SizedBox(height: isPortrait ? size.height * 0.04 : size.height * 0.02),
        // Sign up button
        SizedBox(
          width: isPortrait ? size.width * 0.6 : size.width * 0.3,
          height: isPortrait ? size.height * 0.06 : size.height * 0.1,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _signUp,
            child: Text(
              "Sign Up",
              style: TextStyle(
                fontSize: isPortrait ? size.width * 0.04 : size.width * 0.02,
              ),
            ),
          ),
        ),
        SizedBox(height: isPortrait ? size.height * 0.02 : size.height * 0.01),
        // Login alternative (portrait only)
        if (isPortrait)
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text(
              "Already have an account? Login",
              style: TextStyle(
                color: Colors.white,
                fontSize: size.width * 0.035,
              ),
            ),
          ),
      ],
    );
  }
}