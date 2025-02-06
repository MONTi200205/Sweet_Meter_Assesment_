import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'OpenAi.dart';

class QuoteManager {
  List<String> quotes = [];
  int currentQuoteIndex = 0;
  Timer? _timer;
  final Function(String) onQuoteChanged;
  final String quotesKey = 'food_quotes';

  QuoteManager({required this.onQuoteChanged});

  void loadQuotes(List<String> newQuotes) {
    quotes = newQuotes;
    if (quotes.isNotEmpty) {
      _startQuoteTimer();
    } else {
      onQuoteChanged("No quotes available.");
    }
  }

  void _startQuoteTimer() {
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
  }
  Future<void> clearSavedQuotes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      //final OpenAIService _openAIService = OpenAIService();
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