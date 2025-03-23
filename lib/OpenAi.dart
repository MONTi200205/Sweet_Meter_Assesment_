import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class OpenAIService {
  final String apiKey =
      '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';
  final String quotesKey = 'food_quotes';

  Future<String> generateAndSaveQuotes(int numberOfQuotes) async {
    List<String> quotes = [];

    try {
      for (int i = 0; i < numberOfQuotes; i++) {
        String quote = await _generateHealthyFoodQuote();
        quotes.add(quote);
      }

      await _saveQuotesToPrefs(quotes);
      return 'Quotes generated and saved successfully!';
    } catch (e) {
      print('Error generating or saving quotes: $e');
      return 'Error generating or saving quotes. Please try again later.';
    }
  }

  Future<String> _generateHealthyFoodQuote() async {
    final url = Uri.parse('https://api.openai.com/v1/chat/completions');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $apiKey',
    };
    final body = jsonEncode({
      "model": "gpt-4o-mini",
      "messages": [
        {
          "role": "system",
          "content": "You provide engaging, diverse, and **non-repetitive** "
              "health tips and food facts. Each response must be **unique**, avoiding similar structures"
              " or phrasing. Share a useful health tip or an interesting fact about a specific food and its"
              " benefits. Keep responses varied and informative, using a mix of 'Did you know…' facts, 'Try this…'"
              " tips, and 'This food helps with…' insights. and keep it within 25 words"
        },
        {
          "role": "user",
          "content": "Give me a unique and useful health tip or food fact. Avoid repeating common phrases and make sure each response is different."
        }
      ],
      "temperature": 1,
      "max_tokens": 50
    });

    try {
      final response = await http.post(url, headers: headers, body: body);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['choices'] != null &&
            data['choices'].isNotEmpty &&
            data['choices'][0]['message'] != null &&
            data['choices'][0]['message']['content'] != null) {
          String quote =
              data['choices'][0]['message']['content'].toString().trim();

          // **Filter out repeated phrases** from old quotes
          List<String> previousQuotes = await getSavedQuotes();
          for (String oldQuote in previousQuotes) {
            if (quote
                .toLowerCase()
                .contains(oldQuote.toLowerCase().split(' ').first)) {
              return await _generateHealthyFoodQuote(); // Re-generate if it's too similar
            }
          }

          return quote;
        } else {
          print('Unexpected JSON response format: $data');
          return 'Failed to parse quote from response.';
        }
      } else {
        print(
            'Failed to fetch quote: ${response.statusCode}, Response body: ${response.body}');
        return 'Failed to fetch quote: ${response.statusCode}';
      }
    } catch (e) {
      print('Error: $e');
      return 'Failed to fetch quote. Please try again later.';
    }
  }

  Future<void> _saveQuotesToPrefs(List<String> quotes) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(quotesKey, quotes);
      print('Quotes saved to SharedPreferences.');
    } catch (e) {
      print('Error saving quotes to SharedPreferences: $e');
    }
  }

  Future<List<String>> getSavedQuotes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final quotes = prefs.getStringList(quotesKey);
      return quotes ?? [];
    } catch (e) {
      print('Error reading quotes from SharedPreferences: $e');
      return [];
    }
  }
}
