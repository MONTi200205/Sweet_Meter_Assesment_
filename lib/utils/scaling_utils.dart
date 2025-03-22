import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Scale factor values
double globalScaleFactor = 0.875; // Default to medium (0.875) instead of small

// Function to apply scale to a dimension
double scaled(double value) {
  return value * globalScaleFactor;
}

// Get a descriptive name for the current scale
String getScaleName() {
  if (globalScaleFactor <= 0.75) return "Small";
  if (globalScaleFactor <= 0.875) return "Medium";
  return "Large";
}

// Function to save scale preference
Future<void> saveScalePreference(double scale) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setDouble('ui_scale_factor', scale);
  globalScaleFactor = scale;
}

// Function to load scale preference
Future<double> loadScalePreference() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getDouble('ui_scale_factor') ?? 0.875; // Default to medium (0.875)
}

// Initialize scaling on app startup
Future<void> initializeScaling() async {
  globalScaleFactor = await loadScalePreference();
}