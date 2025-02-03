import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';
import 'login_screen.dart';
import 'package:sweet_meter_assesment/utils/Darkmode.dart';
import 'dart:convert';

class Menu {
  OverlayEntry? _overlayEntry;
  final GlobalKey _menuKey;
  bool _isMenuVisible = false;

  Menu(this._menuKey);
  void hideMenu() {
    if (!_isMenuVisible) return; // Prevent duplicate hide calls
    _overlayEntry?.remove();
    _overlayEntry = null;
    _isMenuVisible = false;
  }
  void showMenu(BuildContext context) {
    if (_isMenuVisible) return; // Prevent multiple menu entries
    _isMenuVisible = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final RenderBox? renderBox = _menuKey.currentContext?.findRenderObject() as RenderBox?;

      if (renderBox == null) {
        _isMenuVisible = false; // Reset if rendering fails
        return;
      }

      final Offset offset = renderBox.localToGlobal(Offset.zero);
      final Size size = renderBox.size;

      final screenWidth = MediaQuery.of(context).size.width;
      final screenHeight = MediaQuery.of(context).size.height;
      final safePadding = MediaQuery.of(context).padding;

      double menuWidth = screenWidth * 0.6;
      double menuHeight = screenHeight * 0.4;

      double topPosition = offset.dy + size.height;
      double leftPosition = offset.dx - menuWidth * 0.2;

      topPosition = min(topPosition, screenHeight - menuHeight - safePadding.bottom - 10);
      leftPosition = max(10, min(leftPosition, screenWidth - menuWidth - 10));

      _overlayEntry = OverlayEntry(
        builder: (context) => GestureDetector(
          onTap: hideMenu,
          child: Material(
            color: Colors.transparent,
            child: Stack(
              children: [
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
                      padding: EdgeInsets.all(screenWidth * 0.05),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20.0),
                        color: Background(context),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Text(
                              "Menu",
                              style: TextStyle(
                                fontSize: screenWidth * 0.05,
                                fontWeight: FontWeight.bold,
                                color: Colors.purple,
                              ),
                            ),
                          ),
                          Divider(color: Colors.grey),
                          SizedBox(height: screenHeight * 0.02),
                          ListTile(
                            leading: Icon(Icons.account_circle, color: Colors.purple),
                            title: Text(
                              "Account",
                              style: TextStyle(fontSize: screenWidth * 0.045),
                            ),
                            onTap: () {
                              hideMenu();
                              hideMenu;// Hide the menu first
                              print("Account selected");
                            },
                          ),
                          ListTile(
                            leading: Icon(Icons.delete, color: Colors.red),
                            title: Text(
                              "Delete History",
                              style: TextStyle(fontSize: screenWidth * 0.045),
                            ),
                              onTap: () async {
                                hideMenu();
                                final prefs = await SharedPreferences.getInstance();
                                final email = FirebaseAuth.instance.currentUser?.email;

                                final dataMapString = prefs.getString('userFoodData');
                                if (dataMapString != null) {
                                  final Map<String, dynamic> dataMap = json.decode(dataMapString);

                                  if (dataMap.containsKey(email)) {
                                    dataMap.remove(email); // Remove only the current user's data
                                    await prefs.setString('userFoodData', json.encode(dataMap)); // Save the updated data
                                    print('Food history cleared for $email');
                                  } else {
                                    print('No history found for $email');
                                  }
                                } else {
                                  print('No food history found at all');
                                }
                              }
                          ),
                          ListTile(
                            leading: Icon(Icons.logout, color: Colors.orange),
                            title: Text(
                              "Logout",
                              style: TextStyle(fontSize: screenWidth * 0.045),
                            ),
                            onTap: () async {
                              hideMenu(); // Hide the menu first
                              print('Attempting to log out...');
                              try {
                                await FirebaseAuth.instance.signOut();
                                Navigator.of(context).pushReplacement(
                                  MaterialPageRoute(builder: (context) => LoginScreen()),
                                );
                                print('Logout successful!');
                              } catch (e) {
                                print('Error logging out: $e');
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      Overlay.of(context)?.insert(_overlayEntry!);
    });
  }
}