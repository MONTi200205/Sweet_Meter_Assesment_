import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

/// Service for generating and managing healthy food quotes using OpenAI's API
///
/// This class provides functionality to generate motivational health tips and
/// food-related quotes using OpenAI's GPT models. Quotes are generated, filtered
/// for uniqueness, and stored in the device's local storage for later display.
class OpenAIService {
  /// OpenAI API key for authentication
  ///
  /// Used to authenticate requests to the OpenAI API
  final String apiKey =
      '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';

  /// Storage key used for saving quotes in SharedPreferences
  ///
  /// Serves as a unique identifier for retrieving stored quotes
  final String quotesKey = 'food_quotes';

  /// Generates and saves multiple health and food quotes
  ///
  /// Requests a specified number of unique quotes from OpenAI,
  /// filters them for uniqueness, and saves them to local storage
  ///
  /// @param numberOfQuotes Number of quotes to generate and save
  /// @return String message indicating success or failure of the operation
  Future<String> generateAndSaveQuotes(int numberOfQuotes) async {
    List<String> quotes = [];

    try {
      // Generate the requested number of quotes
      for (int i = 0; i < numberOfQuotes; i++) {
        String quote = await _generateHealthyFoodQuote();
        quotes.add(quote);
      }

      // Save the generated quotes to SharedPreferences
      await _saveQuotesToPrefs(quotes);
      return 'Quotes generated and saved successfully!';
    } catch (e) {
      print('Error generating or saving quotes: $e');
      return 'Error generating or saving quotes. Please try again later.';
    }
  }

  /// Generates a single health or food quote using OpenAI's API
  ///
  /// Makes a request to the OpenAI API to generate a unique, non-repetitive
  /// health tip or food fact. Checks against previously generated quotes
  /// to ensure uniqueness.
  ///
  /// @return Future<String> containing the generated quote or error message
  Future<String> _generateHealthyFoodQuote() async {
    // Prepare API request
    final url = Uri.parse('https://api.openai.com/v1/chat/completions');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $apiKey',
    };

    // Configure prompt and parameters for OpenAI
    final body = jsonEncode({
      "model": "gpt-4o-mini", // Using GPT-4o Mini model for generation
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
      "temperature": 1, // Higher temperature for more creative responses
      "max_tokens": 50  // Limit response length
    });

    try {
      // Send request to OpenAI API
      final response = await http.post(url, headers: headers, body: body);

      // Handle successful response
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['choices'] != null &&
            data['choices'].isNotEmpty &&
            data['choices'][0]['message'] != null &&
            data['choices'][0]['message']['content'] != null) {

          // Extract quote text from response
          String quote =
          data['choices'][0]['message']['content'].toString().trim();

          // Check for similarity with previously generated quotes
          List<String> previousQuotes = await getSavedQuotes();
          for (String oldQuote in previousQuotes) {
            // If new quote starts with the same word as an old quote, regenerate
            if (quote
                .toLowerCase()
                .contains(oldQuote.toLowerCase().split(' ').first)) {
              return await _generateHealthyFoodQuote(); // Recursively regenerate for uniqueness
            }
          }

          return quote;
        } else {
          // Handle unexpected response format
          print('Unexpected JSON response format: $data');
          return 'Failed to parse quote from response.';
        }
      } else {
        // Handle API error response
        print(
            'Failed to fetch quote: ${response.statusCode}, Response body: ${response.body}');
        return 'Failed to fetch quote: ${response.statusCode}';
      }
    } catch (e) {
      // Handle network or other errors
      print('Error: $e');
      return 'Failed to fetch quote. Please try again later.';
    }
  }

  /// Saves a list of quotes to SharedPreferences for persistent storage
  ///
  /// @param quotes List of quote strings to save
  /// @return Future that completes when saving is done
  Future<void> _saveQuotesToPrefs(List<String> quotes) async {
    try {
      // Get SharedPreferences instance
      final prefs = await SharedPreferences.getInstance();

      // Save quotes as a string list
      await prefs.setStringList(quotesKey, quotes);
      print('Quotes saved to SharedPreferences.');
    } catch (e) {
      // Log error but don't throw to prevent app crashes
      print('Error saving quotes to SharedPreferences: $e');
    }
  }

  /// Retrieves previously saved quotes from SharedPreferences
  ///
  /// @return List<String> containing stored quotes, or empty list if none exist
  Future<List<String>> getSavedQuotes() async {
    try {
      // Get SharedPreferences instance
      final prefs = await SharedPreferences.getInstance();

      // Retrieve quotes or return empty list if none are found
      final quotes = prefs.getStringList(quotesKey);
      return quotes ?? [];
    } catch (e) {
      // Log error and return empty list to prevent app crashes
      print('Error reading quotes from SharedPreferences: $e');
      return [];
    }
  }
}