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
        onQuoteChanged(quotes[currentQuoteIndex]);
        _startQuoteTimer();
      } else {
        onQuoteChanged("No quotes available.");
      }
    }
  }

  void loadQuotes(List<String> newQuotes) {
    quotes = newQuotes;

    // Check if we're in power saving mode
    if (_isPaused) {
      onQuoteChanged("Power saving mode active. Quotes paused to save battery.");
      return;
    }

    if (quotes.isNotEmpty) {
      onQuoteChanged(quotes[currentQuoteIndex]); // Show first quote immediately
      _startQuoteTimer();
    } else {
      onQuoteChanged("No quotes available.");
    }
  }

  void _startQuoteTimer() {
    // Don't start timer if in power saving mode
    if (_isPaused) return;

    // Cancel existing timer before starting a new one
    _timer?.cancel();

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
}