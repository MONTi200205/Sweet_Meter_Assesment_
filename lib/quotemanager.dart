import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'OpenAi.dart';

class QuoteManager {
  List<String> quotes = [];
  int currentQuoteIndex = 0;
  Timer? _timer;
  final Function(String) onQuoteChanged;
  final String quotesKey = 'food_quotes';
  bool _isPaused = false; // Track power saving mode state
  bool _isInitialized = false; // Track if quotes have been initialized

  QuoteManager({required this.onQuoteChanged});

  // Add pause method for power saving mode
  void pause() {
    if (!_isPaused) {
      _isPaused = true;
      _timer?.cancel();
      _timer = null;
      onQuoteChanged("Power saving mode active. Quotes paused to save battery.");
    }
  }

  // Add resume method for when power saving mode is disabled
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

  void _startQuoteTimer() {
    // Don't start timer if in power saving mode
    if (_isPaused) return;

    // Don't start if no quotes available
    if (quotes.isEmpty) return;

    // Cancel existing timer before starting a new one
    _timer?.cancel();

    // Use a slightly longer duration for web platform
    _timer = Timer.periodic(Duration(seconds: 10), (timer) {
      if (quotes.isNotEmpty) {
        currentQuoteIndex = (currentQuoteIndex + 1) % quotes.length;
        onQuoteChanged(quotes[currentQuoteIndex]);
      } else {
        onQuoteChanged("No quotes available.");
        _timer?.cancel();
      }
    });
  }

  // Force a quote update (useful after login)
  void forceQuoteUpdate() {
    if (!_isPaused && quotes.isNotEmpty) {
      onQuoteChanged(quotes[currentQuoteIndex]);
      _startQuoteTimer();
    }
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> clearSavedQuotes() async {
    try {
      // If in power saving mode, don't perform the operation
      if (_isPaused) {
        onQuoteChanged("Power saving mode active. Operation not available.");
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(quotesKey);
      quotes.clear();
      currentQuoteIndex = 0;
      onQuoteChanged("All saved quotes have been removed.");
      print("Quotes successfully removed from SharedPreferences.");
    } catch (e) {
      print("Error clearing quotes: $e");
    }
  }

  // Check if we need to initialize quotes after login
  bool get needsInitialization => !_isInitialized;
}