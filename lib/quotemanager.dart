import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'OpenAi.dart';

/// Manages motivational food and health quotes for the application
///
/// Handles loading, displaying, and rotating quotes with support for
/// power-saving mode and persistence. Quotes are automatically rotated
/// on a timer to provide continuously changing motivation.
class QuoteManager {
  /// Collection of available quotes to display
  List<String> quotes = [];

  /// Current position in the quotes list
  int currentQuoteIndex = 0;

  /// Timer that controls quote rotation
  Timer? _timer;

  /// Callback function to notify parent widgets when quotes change
  ///
  /// This allows the UI to update with the new quote text
  final Function(String) onQuoteChanged;

  /// Storage key for saving quotes in SharedPreferences
  final String quotesKey = 'food_quotes';

  /// Whether quotes rotation is paused (for power saving)
  bool _isPaused = false;

  /// Whether quotes have been initialized and loaded
  bool _isInitialized = false;

  /// Creates a new QuoteManager instance
  ///
  /// @param onQuoteChanged Callback function that receives updated quote text
  QuoteManager({required this.onQuoteChanged});

  /// Pauses quote rotation to save battery power
  ///
  /// Called when the device enters power saving mode
  void pause() {
    if (!_isPaused) {
      _isPaused = true;
      // Cancel the timer to stop quote rotation
      _timer?.cancel();
      _timer = null;
      // Update the UI with a message
      onQuoteChanged("Power saving mode active. Quotes paused to save battery.");
    }
  }

  /// Resumes quote rotation when power saving mode is disabled
  ///
  /// Restarts the quote timer and displays the current quote
  void resume() {
    if (_isPaused) {
      _isPaused = false;
      if (quotes.isNotEmpty) {
        // Reset the index to ensure we're showing a quote
        currentQuoteIndex = 0;
        onQuoteChanged(quotes[currentQuoteIndex]);
        _startQuoteTimer();
      } else {
        onQuoteChanged("No quotes available.");
      }
    }
  }

  /// Loads a new set of quotes and starts rotation
  ///
  /// @param newQuotes List of quote strings to use for rotation
  void loadQuotes(List<String> newQuotes) {
    quotes = newQuotes;
    _isInitialized = true;

    // If no quotes were loaded, show a message
    if (quotes.isEmpty) {
      onQuoteChanged("No quotes available.");
      return;
    }

    // Check if we're in power saving mode
    if (_isPaused) {
      onQuoteChanged("Power saving mode active. Quotes paused to save battery.");
      return;
    }

    // Make sure we have a valid index
    if (currentQuoteIndex >= quotes.length) {
      currentQuoteIndex = 0;
    }

    // Show the current quote immediately
    onQuoteChanged(quotes[currentQuoteIndex]);

    // Start the timer for quote rotation
    _startQuoteTimer();
  }

  /// Starts the timer that automatically rotates quotes
  ///
  /// Creates a periodic timer that changes the quote every 10 seconds
  void _startQuoteTimer() {
    // Don't start timer if in power saving mode
    if (_isPaused) return;

    // Don't start if no quotes available
    if (quotes.isEmpty) return;

    // Cancel existing timer before starting a new one
    _timer?.cancel();

    // Create a periodic timer that fires every 10 seconds
    _timer = Timer.periodic(Duration(seconds: 10), (timer) {
      if (quotes.isNotEmpty) {
        // Cycle through the quotes list
        currentQuoteIndex = (currentQuoteIndex + 1) % quotes.length;
        onQuoteChanged(quotes[currentQuoteIndex]);
      } else {
        onQuoteChanged("No quotes available.");
        _timer?.cancel();
      }
    });
  }

  /// Forces an immediate update of the current quote
  ///
  /// Useful after login or when quotes need to be refreshed manually
  void forceQuoteUpdate() {
    if (!_isPaused && quotes.isNotEmpty) {
      onQuoteChanged(quotes[currentQuoteIndex]);
      _startQuoteTimer();
    }
  }

  /// Stops quote rotation and cancels the timer
  ///
  /// Called when the widget is disposed to prevent memory leaks
  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  /// Clears all saved quotes from local storage
  ///
  /// Removes quotes from SharedPreferences and resets the manager state
  ///
  /// @return Future that completes when the operation is finished
  Future<void> clearSavedQuotes() async {
    try {
      // If in power saving mode, don't perform the operation
      if (_isPaused) {
        onQuoteChanged("Power saving mode active. Operation not available.");
        return;
      }

      // Remove quotes from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(quotesKey);

      // Reset internal state
      quotes.clear();
      currentQuoteIndex = 0;

      // Update UI with confirmation
      onQuoteChanged("All saved quotes have been removed.");
      print("Quotes successfully removed from SharedPreferences.");
    } catch (e) {
      print("Error clearing quotes: $e");
    }
  }

  /// Checks if quotes need to be initialized
  ///
  /// @return Boolean indicating whether quotes need to be loaded
  bool get needsInitialization => !_isInitialized;
}