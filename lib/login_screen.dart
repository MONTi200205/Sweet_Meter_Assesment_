import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'signup_screen.dart';
import 'home_screen.dart';
import 'package:sweet_meter_assesment/utils/Darkmode.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

// Handles Google Sign-In authentication flow for both web and mobile platforms
Future<void> signInWithGoogle(BuildContext context) async {
  try {
    GoogleSignIn googleSignIn;

    if (kIsWeb) {
      // Web-specific configuration with client ID
      googleSignIn = GoogleSignIn(
        clientId: '685238501821-ch9t81g9dvcdfcquv2vpispjkukqu941.apps.googleusercontent.com',
        scopes: ['email', 'profile'],
      );
    } else {
      // Mobile configuration
      googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
      );
    }

    // Trigger the authentication flow
    final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

    if (googleUser == null) {
      return; // User canceled the sign-in process
    }

    // Extract profile data
    String? photoUrl = googleUser.photoUrl;
    final String email = googleUser.email;

    // Get authentication tokens
    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

    // Create Firebase credential
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    // Sign in to Firebase
    final UserCredential userCredential =
    await FirebaseAuth.instance.signInWithCredential(credential);

    // Save profile picture to Firestore for later use
    if (photoUrl != null) {
      await FirebaseFirestore.instance.collection('users').doc(email).set({
        'profilePictureUrl': photoUrl,
      }, SetOptions(merge: true));

      print("Saved profile picture URL to Firestore: $photoUrl");
    }

    // Navigate to home screen after successful login
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => HomeScreen()),
    );

  } catch (e) {
    print("Detailed Google Sign-In error: $e");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error occurred: $e')),
    );
  }
}

// Handles Facebook authentication flow
Future<void> signInWithFacebook(BuildContext context) async {
  try {
    // Show loading indicator during auth process
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Colors.purple),
      ),
    );

    // Request Facebook login
    final LoginResult result = await FacebookAuth.instance.login(
      permissions: ['email', 'public_profile'],
    );

    if (result.status == LoginStatus.success) {
      // Get user profile data
      final userData = await FacebookAuth.instance.getUserData(
        fields: "email,picture.width(400)",
      );

      // Extract user information
      final String? email = userData['email'];
      final String? profilePicUrl = userData['picture']?['data']?['url'];

      print("Facebook email: $email");
      print("Facebook profile pic: $profilePicUrl");

      // Update global variable for immediate display
      userProfileImageUrl = profilePicUrl;

      // Close loading dialog
      Navigator.pop(context);

      // Navigate to home screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomeScreen()),
      );
    } else {
      // Close loading dialog
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Facebook login failed: ${result.message}')),
      );
    }
  } catch (e) {
    // Close loading dialog if open
    try {
      Navigator.pop(context);
    } catch (_) {}

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: $e')),
    );
  }
}

// Main login screen widget
class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

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
          // Purple gradient overlay
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
          // Dark mode tinting
          Container(
            width: size.width,
            height: size.height,
            color: Tinting(context),
          ),
          // Responsive layout based on orientation
          isLandscape
              ? _buildLandscapeLayout(context, size)
              : _buildPortraitLayout(context, size),
        ],
      ),
    );
  }

  // Portrait mode layout
  Widget _buildPortraitLayout(BuildContext context, Size size) {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: size.width * 0.05,
        ),
        child: Column(
          children: [
            // App title
            Center(
              child: Padding(
                padding: EdgeInsets.only(top: size.height * 0.05),
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
            ),
            SizedBox(height: size.height * 0.05),
            // Login form
            _buildLoginForm(context, size),
            // Social login options
            _buildSocialLoginButtons(context, size, isPortrait: true),
            SizedBox(height: size.height * 0.05),
          ],
        ),
      ),
    );
  }

  // Landscape mode layout
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
              // App title
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

              // Vertical space
              SizedBox(height: size.height * 0.15),

              // Two-column layout for login form and social buttons
              Padding(
                padding: EdgeInsets.only(bottom: size.height * 0.02),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Login form column
                    Expanded(
                      child: _buildCompactLoginForm(context, size),
                    ),
                    SizedBox(width: size.width * 0.05),
                    // Social login column
                    Expanded(
                      child: _buildSocialLoginButtons(context, size,
                          isPortrait: false),
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

  // Standard login form for portrait orientation
  Widget _buildLoginForm(BuildContext context, Size size) {
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Email field
        TextField(
          controller: _emailController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: "Email",
            labelStyle: TextStyle(
              color: Colors.white,
              fontSize: isLandscape ? size.width * 0.02 : size.width * 0.04,
            ),
            enabledBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white),
            ),
          ),
        ),
        SizedBox(height: isLandscape ? size.height * 0.01 : size.height * 0.02),
        // Password field
        TextField(
          controller: _passwordController,
          obscureText: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: "Password",
            labelStyle: TextStyle(
              color: Colors.white,
              fontSize: isLandscape ? size.width * 0.02 : size.width * 0.04,
            ),
            enabledBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white),
            ),
          ),
        ),
        SizedBox(height: isLandscape ? size.height * 0.02 : size.height * 0.04),
        // Login button
        SizedBox(
          width: isLandscape ? size.width * 0.3 : size.width * 0.6,
          height: isLandscape ? size.height * 0.1 : size.height * 0.06,
          child: ElevatedButton(
            onPressed: () async {
              try {
                final email = _emailController.text.trim();
                final password = _passwordController.text.trim();
                await FirebaseAuth.instance.signInWithEmailAndPassword(
                  email: email,
                  password: password,
                );
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => HomeScreen()),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Error: $e")),
                );
              }
            },
            child: Text(
              "Login",
              style: TextStyle(
                fontSize: isLandscape ? size.width * 0.02 : size.width * 0.04,
              ),
            ),
          ),
        ),
        SizedBox(height: isLandscape ? size.height * 0.01 : size.height * 0.02),
        // Password reset option
        TextButton(
          onPressed: () async {
            try {
              final email = _emailController.text.trim();
              if (email.isNotEmpty) {
                await FirebaseAuth.instance
                    .sendPasswordResetEmail(email: email);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Password reset email sent!")),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Please enter an email")),
                );
              }
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Error: $e")),
              );
            }
          },
          child: Text(
            "Send Reset Link",
            style: TextStyle(
              color: Colors.white,
              fontSize: isLandscape ? size.width * 0.015 : size.width * 0.035,
            ),
          ),
        ),
        // Account creation option
        TextButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SignUpScreen()),
            );
          },
          child: Text(
            "Create Account",
            style: TextStyle(
              color: Colors.white,
              fontSize: isLandscape ? size.width * 0.015 : size.width * 0.035,
            ),
          ),
        ),
      ],
    );
  }

  // Compact login form for landscape orientation
  Widget _buildCompactLoginForm(BuildContext context, Size size) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Email field
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
        SizedBox(height: size.height * 0.012),
        // Login button
        SizedBox(
          width: size.width * 0.25,
          height: size.height * 0.06,
          child: ElevatedButton(
            onPressed: () async {
              try {
                final email = _emailController.text.trim();
                final password = _passwordController.text.trim();
                await FirebaseAuth.instance.signInWithEmailAndPassword(
                  email: email,
                  password: password,
                );
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => HomeScreen()),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Error: $e")),
                );
              }
            },
            child: Text(
              "Login",
              style: TextStyle(
                fontSize: size.width * 0.016,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Social login options that adapt based on orientation
  Widget _buildSocialLoginButtons(BuildContext context, Size size,
      {required bool isPortrait}) {
    if (isPortrait) {
      // Portrait layout - horizontal buttons
      return Column(
        children: [
          Divider(
              height: size.height * 0.05, thickness: 1, color: Colors.white38),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // Facebook login
              SizedBox(
                width: size.width * 0.38,
                height: size.height * 0.05,
                child: ElevatedButton.icon(
                  onPressed: () {
                    signInWithFacebook(context);
                  },
                  icon: const Icon(Icons.facebook, color: Colors.white),
                  label: const Text(
                    "Facebook",
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                  ),
                ),
              ),
              // Google login
              SizedBox(
                width: size.width * 0.38,
                height: size.height * 0.05,
                child: ElevatedButton.icon(
                  onPressed: () {
                    signInWithGoogle(context);
                  },
                  icon: const Icon(Icons.g_mobiledata, color: Colors.white),
                  label: const Text(
                    "Google",
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    } else {
      // Landscape layout - vertical cards with additional options
      return Container(
        decoration: BoxDecoration(
          color: Colors.black12,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white30, width: 1),
        ),
        padding: EdgeInsets.all(size.height * 0.015),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Section title
            Text(
              "Connect with",
              style: TextStyle(
                color: Colors.white70,
                fontSize: size.width * 0.016,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: size.height * 0.01),

            // Facebook login
            SizedBox(
              width: double.infinity,
              height: size.height * 0.06,
              child: ElevatedButton.icon(
                onPressed: () {
                  signInWithFacebook(context);
                },
                icon: const Icon(Icons.facebook, color: Colors.white, size: 16),
                label: Text(
                  "Facebook",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: size.width * 0.014,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                ),
              ),
            ),
            SizedBox(height: size.height * 0.008),

            // Google login
            SizedBox(
              width: size.width * 0.38,
              height: size.height * 0.05,
              child: ElevatedButton.icon(
                onPressed: () {
                  signInWithGoogle(context);
                },
                icon: const Icon(Icons.g_mobiledata, color: Colors.white),
                label: const Text(
                  "Google",
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                ),
              ),
            ),

            // Section divider
            Padding(
              padding: EdgeInsets.symmetric(vertical: size.height * 0.012),
              child: Divider(
                thickness: 1,
                color: Colors.white24,
              ),
            ),

            // Additional options section
            Text(
              "Account Options",
              style: TextStyle(
                color: Colors.white70,
                fontSize: size.width * 0.016,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: size.height * 0.01),

            // Password reset
            SizedBox(
              width: double.infinity,
              height: size.height * 0.05,
              child: ElevatedButton(
                onPressed: () async {
                  try {
                    final email = _emailController.text.trim();
                    if (email.isNotEmpty) {
                      await FirebaseAuth.instance
                          .sendPasswordResetEmail(email: email);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text("Password reset email sent!")),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Please enter an email")),
                      );
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Error: $e")),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple.withOpacity(0.6),
                ),
                child: Text(
                  "Reset Password",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: size.width * 0.012,
                  ),
                ),
              ),
            ),
            SizedBox(height: size.height * 0.008),

            // Account creation
            SizedBox(
              width: double.infinity,
              height: size.height * 0.05,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const SignUpScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.withOpacity(0.6),
                ),
                child: Text(
                  "Create Account",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: size.width * 0.012,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }
  }
}