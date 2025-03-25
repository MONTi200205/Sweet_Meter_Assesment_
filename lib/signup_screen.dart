import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sweet_meter_assesment/utils/Darkmode.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({Key? key}) : super(key: key);

  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  Future<void> _signUp() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Passwords do not match")),
      );
      return;
    }

    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Account created successfully!")),
      );
      Navigator.pop(context); // Navigate back to the Login screen
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get screen size and orientation
    final size = MediaQuery.of(context).size;
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // Background Image
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
          // Purple Gradient Overlay
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
          Container(
            width: size.width,
            height: size.height,
            color: Tinting(context),
          ),
          // Main Content - Choose layout based on orientation
          isLandscape
              ? _buildLandscapeLayout(context, size)
              : _buildPortraitLayout(context, size),
        ],
      ),
    );
  }

  // Portrait layout
  Widget _buildPortraitLayout(BuildContext context, Size size) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: size.width * 0.05),
          child: Column(
            children: [
              SizedBox(height: size.height * 0.05),
              // Title
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
              // Form fields
              _buildSignUpForm(context, size, isPortrait: true),
              SizedBox(height: size.height * 0.05),
            ],
          ),
        ),
      ),
    );
  }

  // Landscape layout - fixing bottom overflow
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
              // Title - bigger in landscape
              Padding(
                padding: EdgeInsets.only(bottom: size.height * 0.02),
                child: Text(
                  "SWEET METER",
                  style: TextStyle(
                    fontFamily: 'Agbalumo',
                    fontSize: size.width * 0.12, // Bigger font in landscape
                    fontWeight: FontWeight.bold,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ),

              // Add padding to push content down
              SizedBox(height: size.height * 0.15),

              // Main content with bottom margin to prevent overflow
              Padding(
                padding: EdgeInsets.only(bottom: size.height * 0.02),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Sign up form on the left
                    Expanded(
                      flex: 6,
                      child: _buildCompactSignUpForm(context, size),
                    ),
                    SizedBox(width: size.width * 0.04),
                    // Info panel on the right
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

  // Compact sign-up form for landscape orientation
  Widget _buildCompactSignUpForm(BuildContext context, Size size) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Email TextField
        TextField(
          controller: _emailController,
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
        // Password TextField
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
        // Confirm Password TextField
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
        // Sign-Up Button
        SizedBox(
          width: size.width * 0.25,
          height: size.height * 0.06,
          child: ElevatedButton(
            onPressed: _signUp,
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

  // Compact info panel for landscape with proper welcome message
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
          Icon(
            Icons.person_add_rounded,
            color: Colors.white,
            size: size.width * 0.025,
          ),
          SizedBox(height: size.height * 0.008),
          Text(
            "Join Us!",
            style: TextStyle(
              color: Colors.white,
              fontSize: size.width * 0.02,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: size.height * 0.008),
          Text(
            "Welcome to Sweet Meter! Create your account to track preferences and personalize your experience.",
            style: TextStyle(
              color: Colors.white70,
              fontSize: size.width * 0.012,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: size.height * 0.015),
          // Divider
          Divider(
            thickness: 1,
            color: Colors.white24,
          ),
          SizedBox(height: size.height * 0.008),
          Text(
            "Already have an account?",
            style: TextStyle(
              color: Colors.white70,
              fontSize: size.width * 0.014,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: size.height * 0.008),
          // Login button
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

  // Sign-up form - for portrait mode
  Widget _buildSignUpForm(BuildContext context, Size size, {required bool isPortrait}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Email TextField
        TextField(
          controller: _emailController,
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
        // Password TextField
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
        // Confirm Password TextField
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
        // Sign-Up Button
        SizedBox(
          width: isPortrait ? size.width * 0.6 : size.width * 0.3,
          height: isPortrait ? size.height * 0.06 : size.height * 0.1,
          child: ElevatedButton(
            onPressed: _signUp,
            child: Text(
              "Sign Up",
              style: TextStyle(
                fontSize: isPortrait ? size.width * 0.04 : size.width * 0.02,
              ),
            ),
          ),
        ),
        SizedBox(height: isPortrait ? size.height * 0.02 : size.height * 0.01),
        // Already Have an Account Button (portrait only)
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