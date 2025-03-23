import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'login_screen.dart';
import 'home_screen.dart';
import 'package:sweet_meter_assesment/utils/scaling_utils.dart';

// Get current user email
String currentUserEmail = FirebaseAuth.instance.currentUser?.email ?? '';

class MenuScreen extends StatelessWidget {
  final Function(String)? onProfileUpdated;

  const MenuScreen({Key? key, this.onProfileUpdated}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.purple.withOpacity(
                  0.9), // Same purple as home screen but with opacity
              Colors.purple.withOpacity(0.7),
            ],
          ),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.menu, color: Colors.white, size: 24),
                        const SizedBox(width: 16),
                        const Text(
                          "Menu",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              // Menu Items
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: ListView(
                    padding: const EdgeInsets.only(top: 30),
                    children: [
                      // Profile Section
                      _buildMenuItem(
                        context,
                        icon: Icons.account_circle,
                        title: "Update Profile Picture",
                        subtitle: "Change your profile image",
                        iconColor: Colors.blue,
                        onTap: () => _updateProfilePicture(context),
                      ),

                      _buildDivider(),

                      // History Section
                      _buildMenuItem(
                        context,
                        icon: Icons.delete_outline,
                        title: "Delete History",
                        subtitle: "Clear all your food records",
                        iconColor: Colors.red,
                        onTap: () => _deleteHistory(context),
                      ),

                      _buildDivider(),

                      // UI Scaling Section
                      _buildMenuItem(
                        context,
                        icon: Icons.zoom_in,
                        title: "UI Scaling",
                        subtitle: "Change interface size: ${_getScaleName()}",
                        iconColor: Colors.green,
                        onTap: () => _showScalingDialog(context),
                      ),

                      _buildDivider(),

                      // Logout Section
                      _buildMenuItem(
                        context,
                        icon: Icons.logout,
                        title: "Logout",
                        subtitle: "Sign out from your account",
                        iconColor: Colors.orange,
                        onTap: () => _logout(context),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 14,
          color: Colors.grey.shade600,
        ),
      ),
      trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
      onTap: onTap,
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      thickness: 0.5,
      indent: 70,
      endIndent: 20,
      color: Colors.grey.withOpacity(0.3),
    );
  }

  String _getScaleName() {
    if (globalScaleFactor <= 0.75) return "Small";
    if (globalScaleFactor <= 0.875) return "Medium";
    return "Large";
  }

  // Profile Picture Update
  Future<void> _updateProfilePicture(BuildContext context) async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      File imageFile = File(image.path);

      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: Colors.purple),
        ),
      );

      try {
        final downloadUrl =
            await _uploadProfilePicture(currentUserEmail, imageFile);

        // Close loading dialog
        Navigator.pop(context);
        Navigator.pop(context); // Close menu

        if (downloadUrl != null) {
          if (onProfileUpdated != null) {
            onProfileUpdated!(downloadUrl);
          }

          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text("Profile picture updated successfully")));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text("Failed to update profile picture")));
        }
      } catch (e) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Error: ${e.toString()}")));
      }
    }
  }

  // Upload profile picture to Firebase
  Future<String?> _uploadProfilePicture(String email, File imageFile) async {
    try {
      print('Starting upload for email: $email');

      final storageRef = FirebaseStorage.instance
          .ref()
          .child('profile_pictures')
          .child('$email.jpg');

      print('Storage reference created');

      // Upload the file
      final uploadTask = storageRef.putFile(imageFile);
      print('Upload task started');

      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        print('Upload progress: ${snapshot.bytesTransferred}/${snapshot.totalBytes}');
      }, onError: (e) {
        print('Upload error: $e');
      });

      final snapshot = await uploadTask;
      print('Upload completed');

      // Get download URL
      final downloadUrl = await snapshot.ref.getDownloadURL();
      print('Download URL received: $downloadUrl');

      // Save URL to Firestore
      await FirebaseFirestore.instance.collection('users').doc(email).set({
        'profilePictureUrl': downloadUrl,
      }, SetOptions(merge: true));

      print('URL saved to Firestore');

      return downloadUrl;
    } catch (e) {
      print('Detailed error uploading profile picture: $e');
      if (e is FirebaseException) {
        print('Firebase error code: ${e.code}');
        print('Firebase error message: ${e.message}');
      }
      return null;
    }
  }

  // Delete history
  Future<void> _deleteHistory(BuildContext context) async {
    // Confirmation
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text("Delete History"),
            content: Text(
                "Are you sure you want to delete all your food tracking history? This action cannot be undone."),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text("Cancel"),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text("Delete", style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed) return;

    // Delete from SharedPreferences
    final email = FirebaseAuth.instance.currentUser?.email;

    if (email == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Error: User not logged in")));
      return;
    }

    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: Colors.purple),
        ),
      );

      // Local storage
      final prefs = await SharedPreferences.getInstance();
      final dataMapString = prefs.getString('userFoodData');

      if (dataMapString != null) {
        final Map<String, dynamic> dataMap = json.decode(dataMapString);

        if (dataMap.containsKey(email)) {
          dataMap.remove(email);
          await prefs.setString('userFoodData', json.encode(dataMap));
        }
      }

      // Firebase
      await FirebaseFirestore.instance
          .collection('users')
          .doc(email)
          .update({'foodEntries': FieldValue.delete()});

      // Close dialogs
      Navigator.pop(context); // Loading
      Navigator.pop(context); // Menu

      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("History deleted successfully")));
    } catch (e) {
      Navigator.pop(context); // Close loading
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: ${e.toString()}")));
    }
  }

  // Replace the _showScalingDialog method in your menu_screen.dart file

// Show UI scaling dialog
  // Replace the entire _showScalingDialog method with this implementation

  void _showScalingDialog(BuildContext context) {
    // Force initial scale for the dialog
    // This will show Medium selected by default
    double tempScale = 0.875; // Always start with Medium selected in the dialog

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          print("Current scale in dialog: $tempScale"); // Debug print

          return AlertDialog(
            title: Text("UI Scaling"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  margin: EdgeInsets.only(bottom: 24),
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      "Sweet Meter Preview",
                      style: TextStyle(
                        fontSize: 20 * tempScale,
                        fontWeight: FontWeight.bold,
                        color: Colors.purple,
                      ),
                    ),
                  ),
                ),

                // More reliable button implementation
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Small button
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          tempScale = 0.75;
                          print("Selected Small: $tempScale");
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: (tempScale - 0.75).abs() < 0.01
                            ? Colors.purple
                            : Colors.grey.shade200,
                        foregroundColor: (tempScale - 0.75).abs() < 0.01
                            ? Colors.white
                            : Colors.black,
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: Text("Small"),
                    ),

                    // Medium button
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          tempScale = 0.875;
                          print("Selected Medium: $tempScale");
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: (tempScale - 0.875).abs() < 0.01
                            ? Colors.purple
                            : Colors.grey.shade200,
                        foregroundColor: (tempScale - 0.875).abs() < 0.01
                            ? Colors.white
                            : Colors.black,
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: Text("Medium"),
                    ),

                    // Large button
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          tempScale = 1.0;
                          print("Selected Large: $tempScale");
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: (tempScale - 1.0).abs() < 0.01
                            ? Colors.purple
                            : Colors.grey.shade200,
                        foregroundColor: (tempScale - 1.0).abs() < 0.01
                            ? Colors.white
                            : Colors.black,
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: Text("Large"),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text("Cancel"),
              ),
              FilledButton(
                onPressed: () async {
                  print("Saving scale preference: $tempScale"); // Debug print
                  await saveScalePreference(tempScale);
                  Navigator.pop(context);  // Close dialog
                  Navigator.pop(context);  // Close menu

                  // Notify user
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("UI scale updated to ${_getScaleNameFromValue(tempScale)}"))
                  );

                  // Refresh screen
                  Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => HomeScreen())
                  );
                },
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.purple,
                ),
                child: Text("Apply"),
              ),
            ],
          );
        },
      ),
    );
  }

// You can remove the _scaleButton method since we're now using ElevatedButton directly

  Widget _scaleButton(
      String text, double scale, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.purple : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  String _getScaleNameFromValue(double scale) {
    if (scale <= 0.75) return "Small";
    if (scale <= 0.875) return "Medium";
    return "Large";
  }

  // Logout function
  void _logout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text("Logout"),
            content: Text("Are you sure you want to logout?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text("Cancel"),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.red,
                ),
                child: Text("Logout"),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed) return;

    try {
      await FirebaseAuth.instance.signOut();

      // Navigate to login
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => LoginScreen()),
        (route) => false, // Remove all previous routes
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error logging out: ${e.toString()}")));
    }
  }
}
