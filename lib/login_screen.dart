import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'signup_screen.dart';
import 'home_screen.dart';
import 'package:sweet_meter_assesment/utils/Darkmode.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

Future<void> signInWithGoogle(BuildContext context) async {
  try {
    GoogleSignIn googleSignIn;

    if (kIsWeb) {
      // Web configuration
      googleSignIn = GoogleSignIn(
        clientId: '685238501821-ch9t81g9dvcdfcquv2vpispjkukqu941.apps.googleusercontent.com',
        scopes: ['email', 'profile'],
      );
    } else {
      // iOS/Android configuration (no client ID needed here)
      googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
      );
    }

    // Trigger the authentication flow
    final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

    // If user cancels the sign-in process
    if (googleUser == null) {
      return;
    }

    // Get profile picture URL from Google
    String? photoUrl = googleUser.photoUrl;
    final String email = googleUser.email;

    // Obtain the auth details from the request
    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

    // Create a new credential
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    // Sign in to Firebase with the Google credential
    final UserCredential userCredential =
    await FirebaseAuth.instance.signInWithCredential(credential);

    // Save the Google profile picture URL to Firestore
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
// Keep only ONE version of this function
Future<void> signInWithFacebook(BuildContext context) async {
  try {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Colors.purple),
      ),
    );

    // Trigger the sign-in flow
    final LoginResult result = await FacebookAuth.instance.login(
      permissions: ['email', 'public_profile'],
    );

    if (result.status == LoginStatus.success) {
      // Get user data including email and profile picture
      final userData = await FacebookAuth.instance.getUserData(
        fields: "email,picture.width(400)",
      );

      // Extract email and profile picture URL
      final String? email = userData['email'];
      final String? profilePicUrl = userData['picture']?['data']?['url'];

      print("Facebook email: $email");
      print("Facebook profile pic: $profilePicUrl");

      // Store user data somewhere in your app - perhaps in shared preferences or a global variable
      // Update global variable for immediate display
      userProfileImageUrl = profilePicUrl;

      // Close loading dialog
      Navigator.pop(context);

      // Navigate to home screen WITHOUT Firebase authentication
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
    // Get screen size and orientation
    final size = MediaQuery.of(context).size;
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

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

  // Portrait layout (original layout)
  Widget _buildPortraitLayout(BuildContext context, Size size) {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: size.width * 0.05,
        ),
        child: Column(
          children: [
            // Title
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
            // Login Form
            _buildLoginForm(context, size),
            // Social Login Buttons - Portrait Layout
            _buildSocialLoginButtons(context, size, isPortrait: true),
            SizedBox(height: size.height * 0.05),
          ],
        ),
      ),
    );
  }

  // Landscape layout - fixed with scrolling and bottom positioning
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
                    // Login form on the left
                    Expanded(
                      child: _buildCompactLoginForm(context, size),
                    ),
                    SizedBox(width: size.width * 0.05),
                    // Social buttons on the right
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

  // Login form - reused in both layouts
  Widget _buildLoginForm(BuildContext context, Size size) {
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

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
        // Password TextField
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
        // Login Button
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
        // Reset Password Button
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
        // Create Account Button
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

  // More compact login form for landscape orientation
  Widget _buildCompactLoginForm(BuildContext context, Size size) {
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
        SizedBox(height: size.height * 0.012),
        // Login Button
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

  // Social login buttons - reused in both layouts
  Widget _buildSocialLoginButtons(BuildContext context, Size size,
      {required bool isPortrait}) {
    if (isPortrait) {
      return Column(
        children: [
          Divider(
              height: size.height * 0.05, thickness: 1, color: Colors.white38),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // Facebook Button
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
              // Google Button (replaced Apple)
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
      // Landscape layout for social buttons - more compact
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
            // Connect title
            Text(
              "Connect with",
              style: TextStyle(
                color: Colors.white70,
                fontSize: size.width * 0.016,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: size.height * 0.01),

            // Facebook Button
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

            // Google Button (replaced Apple)
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

            // Divider
            Padding(
              padding: EdgeInsets.symmetric(vertical: size.height * 0.012),
              child: Divider(
                thickness: 1,
                color: Colors.white24,
              ),
            ),

            // Account Options heading
            Text(
              "Account Options",
              style: TextStyle(
                color: Colors.white70,
                fontSize: size.width * 0.016,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: size.height * 0.01),

            // Reset Password Button
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

            // Sign Up Button
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
