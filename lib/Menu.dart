import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';
import 'login_screen.dart';
import 'package:sweet_meter_assesment/utils/Darkmode.dart';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// This variable should be defined in HomeScreen.dart as well
String currentUserEmail = FirebaseAuth.instance.currentUser?.email ?? '';

Future<String?> uploadProfilePicture(String email, File imageFile) async {
  try {
    // Create a storage reference
    final storageRef = FirebaseStorage.instance
        .ref()
        .child('profile_pictures')
        .child('$email.jpg');

    // Upload the file
    final uploadTask = storageRef.putFile(imageFile);
    final snapshot = await uploadTask;

    // Get download URL
    final downloadUrl = await snapshot.ref.getDownloadURL();

    // Save URL to Firestore
    await FirebaseFirestore.instance
        .collection('users')
        .doc(email)
        .set({
      'profilePictureUrl': downloadUrl,
    }, SetOptions(merge: true));

    return downloadUrl;
  } catch (e) {
    print('Error uploading profile picture: $e');
    return null;
  }
}

class Menu {
  OverlayEntry? _overlayEntry;
  final GlobalKey _menuKey;
  bool _isMenuVisible = false;
  Orientation? _currentOrientation;

  // Add a callback function to update the profile image
  final Function(String)? onProfileUpdated;

  // Modified constructor to accept the callback
  Menu(this._menuKey, {this.onProfileUpdated});

  void hideMenu() {
    if (!_isMenuVisible) return;
    _overlayEntry?.remove();
    _overlayEntry = null;
    _isMenuVisible = false;
  }

  void showMenu(BuildContext context) {
    if (_isMenuVisible) {
      hideMenu(); // Close the menu if it's already open instead of returning
      return;
    }
    _isMenuVisible = true;

    // Store the current orientation when opening the menu
    _currentOrientation = MediaQuery.of(context).orientation;

    // Use a short delay to ensure the overlay is properly added
    Future.microtask(() {
      final RenderBox? renderBox =
      _menuKey.currentContext?.findRenderObject() as RenderBox?;

      if (renderBox == null) {
        _isMenuVisible = false;
        return;
      }

      final Offset offset = renderBox.localToGlobal(Offset.zero);
      final Size size = renderBox.size;

      final screenWidth = MediaQuery.of(context).size.width;
      final screenHeight = MediaQuery.of(context).size.height;
      final safePadding = MediaQuery.of(context).padding;

      // Check if orientation has changed since menu was requested
      final currentOrientation = MediaQuery.of(context).orientation;
      if (_currentOrientation != null &&
          _currentOrientation != currentOrientation) {
        // Orientation changed, don't show the menu
        _isMenuVisible = false;
        return;
      }

      // Make menu size responsive to screen size
      double menuWidth = min(screenWidth * 0.6, 300.0);
      double menuHeight = min(screenHeight * 0.4, 250.0);

      double topPosition = offset.dy + size.height;
      double leftPosition = offset.dx - menuWidth * 0.2;

      // Ensure menu stays within screen bounds
      topPosition =
          min(topPosition, screenHeight - menuHeight - safePadding.bottom - 10);
      leftPosition = max(10, min(leftPosition, screenWidth - menuWidth - 10));

      _overlayEntry = OverlayEntry(
        builder: (context) => OrientationBuilder(
          builder: (context, orientation) {
            // Close menu if orientation changes after it's been opened
            if (_currentOrientation != null &&
                orientation != _currentOrientation) {
              // We need to use a microtask to avoid modifying the widget tree during build
              Future.microtask(() => hideMenu());
              return Container(); // Return empty container while closing
            }

            return Stack(
              children: [
                // Full screen transparent layer to capture taps outside menu
                Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: hideMenu,
                    child: Container(
                      color: Colors.black
                          .withOpacity(0.3), // Semi-transparent background
                    ),
                  ),
                ),
                Positioned(
                  top: topPosition,
                  left: leftPosition,
                  child: Material(
                    elevation: 6.0,
                    color: IconColor(context),
                    borderRadius: BorderRadius.circular(20.0),
                    child: Container(
                      width: menuWidth,
                      height: menuHeight,
                      padding: EdgeInsets.all(min(screenWidth * 0.05, 20.0)),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20.0),
                        color: Background(context),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Menu",
                                style: TextStyle(
                                  fontSize: min(screenWidth * 0.05, 20.0),
                                  fontWeight: FontWeight.bold,
                                  color: Colors.purple,
                                ),
                              ),
                              // Add X button to close menu
                              IconButton(
                                icon: Icon(Icons.close, color: Colors.purple),
                                onPressed: hideMenu,
                                iconSize: min(screenWidth * 0.05, 20.0),
                                padding: EdgeInsets.zero,
                                constraints: BoxConstraints(),
                              ),
                            ],
                          ),
                          Divider(color: Colors.grey),
                          Expanded(
                            child: ListView(
                              padding: EdgeInsets.zero,
                              children: [
                                ListTile(
                                  dense: true,
                                  leading: Icon(Icons.account_circle, color: Colors.purple),
                                  title: Text(
                                    "Account",
                                    style: TextStyle(fontSize: min(screenWidth * 0.045, 16.0)),
                                  ),
                                  onTap: () async {
                                    hideMenu();

                                    // Show image picker
                                    final picker = ImagePicker();
                                    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

                                    if (image != null) {
                                      File imageFile = File(image.path);

                                      // Show loading indicator
                                      showDialog(
                                        context: context,
                                        barrierDismissible: false,
                                        builder: (context) => Center(child: CircularProgressIndicator()),
                                      );

                                      // Upload image
                                      final profileUrl = await uploadProfilePicture(currentUserEmail, imageFile);

                                      // Close loading indicator
                                      Navigator.pop(context);

                                      if (profileUrl != null) {
                                        // Use the callback instead of setState
                                        if (onProfileUpdated != null) {
                                          onProfileUpdated!(profileUrl);
                                        }
                                        ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text("Profile picture updated successfully"))
                                        );
                                      } else {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text("Failed to upload profile picture"))
                                        );
                                      }
                                    }
                                  },
                                ),
                                ListTile(
                                  dense: true,
                                  leading:
                                  Icon(Icons.delete, color: Colors.red),
                                  title: Text(
                                    "Delete History",
                                    style: TextStyle(
                                        fontSize:
                                        min(screenWidth * 0.045, 16.0)),
                                  ),
                                  onTap: () async {
                                    hideMenu();

                                    // 1. Get the current user's email
                                    final email = FirebaseAuth
                                        .instance.currentUser?.email;

                                    // 2. Remove locally from SharedPreferences
                                    final prefs =
                                    await SharedPreferences.getInstance();
                                    final dataMapString =
                                    prefs.getString('userFoodData');

                                    if (dataMapString != null) {
                                      final Map<String, dynamic> dataMap =
                                      json.decode(dataMapString);

                                      if (dataMap.containsKey(email)) {
                                        dataMap.remove(email);
                                        await prefs.setString('userFoodData',
                                            json.encode(dataMap));
                                        print(
                                            'Food history cleared locally for $email');
                                      } else {
                                        print(
                                            'No local history found for $email');
                                      }
                                    } else {
                                      print('No local food history found');
                                    }

                                    // 3. Remove all fields inside 'foodEntries' in Firebase
                                    if (email != null) {
                                      try {
                                        final userRef = FirebaseFirestore
                                            .instance
                                            .collection('users')
                                            .doc(email);

                                        // Clear the 'foodEntries' field
                                        await userRef.update({
                                          'foodEntries': FieldValue.delete(),
                                        });

                                        print(
                                            'Food entries removed from Firebase for $email');
                                      } catch (e) {
                                        print(
                                            'Error removing food entries from Firebase: $e');
                                      }
                                    }
                                  },
                                ),
                                ListTile(
                                  dense: true,
                                  leading:
                                  Icon(Icons.logout, color: Colors.orange),
                                  title: Text(
                                    "Logout",
                                    style: TextStyle(
                                        fontSize:
                                        min(screenWidth * 0.045, 16.0)),
                                  ),
                                  onTap: () {
                                    // Get the Navigator and context before hiding the menu
                                    final navigator = Navigator.of(context);
                                    final navigatorContext = context;

                                    // Hide menu first
                                    hideMenu();

                                    // Perform logout after a very short delay
                                    Future.microtask(() async {
                                      print('Attempting to log out...');
                                      try {
                                        await FirebaseAuth.instance.signOut();
                                        navigator.pushReplacement(
                                          MaterialPageRoute(
                                              builder: (context) =>
                                                  LoginScreen()),
                                        );
                                        print('Logout successful!');
                                      } catch (e) {
                                        print('Error logging out: $e');
                                      }
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      );

      Overlay.of(context)?.insert(_overlayEntry!);
    });
  }
}