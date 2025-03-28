import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'signup_screen.dart';
import 'home_screen.dart';
import 'package:sweet_meter_assesment/utils/Darkmode.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Handles Google Sign-In authentication flow for both web and mobile platforms
///
/// Initiates the Google authentication process, retrieves user information,
/// stores profile data in Firestore, and navigates to the home screen on success
///
/// @param context Current build context for navigation and displaying errors
/// @return Future that completes when authentication flow is finished
Future<void> signInWithGoogle(BuildContext context) async {
  try {
    // Initialize GoogleSignIn with appropriate configuration based on platform
    GoogleSignIn googleSignIn;

    if (kIsWeb) {
      // Web-specific configuration with client ID
      googleSignIn = GoogleSignIn(
        clientId: '685238501821-ch9t81g9dvcdfcquv2vpispjkukqu941.apps.googleusercontent.com',
        scopes: ['email', 'profile'], // Request access to email and profile info
      );
    } else {
      // Mobile configuration (client ID from google-services.json)
      googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'], // Request access to email and profile info
      );
    }

    // Trigger the authentication flow and show Google sign-in UI
    final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

    // User canceled sign-in process
    if (googleUser == null) {
      return;
    }

    // Extract profile data from Google user
    String? photoUrl = googleUser.photoUrl;
    final String email = googleUser.email;

    // Get authentication tokens from Google
    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

    // Create Firebase credential from Google auth tokens
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    // Sign in to Firebase using the Google credential
    final UserCredential userCredential =
    await FirebaseAuth.instance.signInWithCredential(credential);

    // Save profile picture URL to Firestore for later use in the app
    if (photoUrl != null) {
      await FirebaseFirestore.instance.collection('users').doc(email).set({
        'profilePictureUrl': photoUrl,
      }, SetOptions(merge: true)); // Use merge to avoid overwriting other data

      print("Saved profile picture URL to Firestore: $photoUrl");
    }

    // Navigate to home screen after successful login
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => HomeScreen()),
    );

  } catch (e) {
    // Log detailed error for debugging
    print("Detailed Google Sign-In error: $e");

    // Show error message to user
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error occurred: $e')),
    );
  }
}

/// Handles Facebook authentication flow
///
/// Initiates the Facebook login process, retrieves user profile data,
/// and navigates to home screen on successful authentication
///
/// @param context Current build context for navigation and displaying errors
/// @return Future that completes when authentication flow is finished
Future<void> signInWithFacebook(BuildContext context) async {
  try {
    // Show loading indicator during authentication process
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Colors.purple),
      ),
    );

    // Request Facebook login with specific permissions
    final LoginResult result = await FacebookAuth.instance.login(
      permissions: ['email', 'public_profile'],
    );

    if (result.status == LoginStatus.success) {
      // Get user profile data from Facebook
      final userData = await FacebookAuth.instance.getUserData(
        fields: "email,picture.width(400)", // Request high-quality profile picture
      );

      // Extract user information from Facebook response
      final String? email = userData['email'];
      final String? profilePicUrl = userData['picture']?['data']?['url'];

      print("Facebook email: $email");
      print("Facebook profile pic: $profilePicUrl");

      // Update global variable for immediate display in UI
      userProfileImageUrl = profilePicUrl;

      // Close loading dialog
      Navigator.pop(context);

      // Navigate to home screen after successful authentication
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomeScreen()),
      );
    } else {
      // Handle failed login attempt
      Navigator.pop(context); // Close loading dialog

      // Display error message to user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Facebook login failed: ${result.message}')),
      );
    }
  } catch (e) {
    // Close loading dialog if open (using try-catch to handle case where dialog isn't showing)
    try {
      Navigator.pop(context);
    } catch (_) {}

    // Display error message to user
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: $e')),
    );
  }
}

/// Main login screen for the Sweet Meter application
///
/// Provides email/password authentication with options for social login,
/// password reset, and account creation
class LoginScreen extends StatefulWidget {
  /// Creates a new LoginScreen
  ///
  /// @param key Widget key for identification
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

/// State management for the LoginScreen
///
/// Handles form input, authentication, and responsive layouts
class _LoginScreenState extends State<LoginScreen> {
  /// Controller for email input field
  final TextEditingController _emailController = TextEditingController();

  /// Controller for password input field
  final TextEditingController _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return Scaffold(
      resizeToAvoidBottomInset: true, // Resize when keyboard appears
      body: Stack(
        children: [
          // Background image layer
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
          // Purple gradient overlay for readability
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
          // Dark mode tinting layer (applied conditionally)
          Container(
            width: size.width,
            height: size.height,
            color: Tinting(context), // Apply dark mode tint if enabled
          ),
          // Responsive layout based on device orientation
          isLandscape
              ? _buildLandscapeLayout(context, size)
              : _buildPortraitLayout(context, size),
        ],
      ),
    );
  }

  /// Builds the portrait mode layout for phones
  ///
  /// Creates a vertical arrangement of components optimized for portrait orientation
  ///
  /// @param context Current build context
  /// @param size Screen dimensions
  /// @return Widget containing the portrait layout
  Widget _buildPortraitLayout(BuildContext context, Size size) {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: size.width * 0.05,
        ),
        child: Column(
          children: [
            // App title with branding
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

            // Login form with email/password fields
            _buildLoginForm(context, size),

            // Social login options (Facebook/Google)
            _buildSocialLoginButtons(context, size, isPortrait: true),

            // Bottom padding
            SizedBox(height: size.height * 0.05),
          ],
        ),
      ),
    );
  }

  /// Builds the landscape mode layout for phones and tablets
  ///
  /// Creates a horizontal arrangement of components optimized for landscape orientation
  ///
  /// @param context Current build context
  /// @param size Screen dimensions
  /// @return Widget containing the landscape layout
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
              // App title with branding
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

              // Vertical space for layout balance
              SizedBox(height: size.height * 0.15),

              // Two-column layout for login form and social buttons
              Padding(
                padding: EdgeInsets.only(bottom: size.height * 0.02),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Login form column (left side)
                    Expanded(
                      child: _buildCompactLoginForm(context, size),
                    ),
                    SizedBox(width: size.width * 0.05),
                    // Social login column (right side)
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

  /// Builds the standard login form for portrait orientation
  ///
  /// Creates email and password fields with login button and account options
  ///
  /// @param context Current build context
  /// @param size Screen dimensions
  /// @return Widget containing the login form
  Widget _buildLoginForm(BuildContext context, Size size) {
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Email input field
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

        // Password input field
        TextField(
          controller: _passwordController,
          obscureText: true, // Hide password characters
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
                // Get and validate form input
                final email = _emailController.text.trim();
                final password = _passwordController.text.trim();

                // Attempt Firebase email/password login
                await FirebaseAuth.instance.signInWithEmailAndPassword(
                  email: email,
                  password: password,
                );

                // Navigate to home screen on success
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => HomeScreen()),
                );
              } catch (e) {
                // Display error message to user
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
              // Get email from input field
              final email = _emailController.text.trim();

              if (email.isNotEmpty) {
                // Send password reset email via Firebase
                await FirebaseAuth.instance
                    .sendPasswordResetEmail(email: email);

                // Notify user of success
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Password reset email sent!")),
                );
              } else {
                // Validate email field isn't empty
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Please enter an email")),
                );
              }
            } catch (e) {
              // Display error message to user
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
            // Navigate to signup screen
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

  /// Builds a compact login form for landscape orientation
  ///
  /// Creates a space-efficient login form with fewer options
  ///
  /// @param context Current build context
  /// @param size Screen dimensions
  /// @return Widget containing the compact login form
  Widget _buildCompactLoginForm(BuildContext context, Size size) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Email input field
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

        // Password input field
        TextField(
          controller: _passwordController,
          obscureText: true, // Hide password characters
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
                // Get and validate form input
                final email = _emailController.text.trim();
                final password = _passwordController.text.trim();

                // Attempt Firebase email/password login
                await FirebaseAuth.instance.signInWithEmailAndPassword(
                  email: email,
                  password: password,
                );

                // Navigate to home screen on success
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => HomeScreen()),
                );
              } catch (e) {
                // Display error message to user
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

  /// Builds social login options that adapt based on orientation
  ///
  /// Creates a layout for social login buttons and additional account options
  /// that changes based on screen orientation
  ///
  /// @param context Current build context
  /// @param size Screen dimensions
  /// @param isPortrait Whether the current orientation is portrait
  /// @return Widget containing social login buttons
  Widget _buildSocialLoginButtons(BuildContext context, Size size,
      {required bool isPortrait}) {
    if (isPortrait) {
      // Portrait layout - horizontal buttons with minimal options
      return Column(
        children: [
          Divider(
              height: size.height * 0.05, thickness: 1, color: Colors.white38),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // Facebook login button
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
              // Google login button
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
      // Landscape layout - vertical card with additional options
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

            // Facebook login button
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

            // Google login button
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

            // Additional options section title
            Text(
              "Account Options",
              style: TextStyle(
                color: Colors.white70,
                fontSize: size.width * 0.016,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: size.height * 0.01),

            // Password reset button
            SizedBox(
              width: double.infinity,
              height: size.height * 0.05,
              child: ElevatedButton(
                onPressed: () async {
                  try {
                    // Get email from input field
                    final email = _emailController.text.trim();

                    if (email.isNotEmpty) {
                      // Send password reset email via Firebase
                      await FirebaseAuth.instance
                          .sendPasswordResetEmail(email: email);

                      // Notify user of success
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text("Password reset email sent!")),
                      );
                    } else {
                      // Validate email field isn't empty
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Please enter an email")),
                      );
                    }
                  } catch (e) {
                    // Display error message to user
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

            // Account creation button
            SizedBox(
              width: double.infinity,
              height: size.height * 0.05,
              child: ElevatedButton(
                onPressed: () {
                  // Navigate to signup screen
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