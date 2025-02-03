import 'dart:convert';
import 'package:http/http.dart' as http;

class OpenAIService {
  final String apiKey = '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';

  // Function to generate a healthy food quote with error handling
  Future<String> generateHealthyFoodQuote() async {
    final url = Uri.parse('https://api.openai.com/v1/completions');

    // Set the headers for the request
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $apiKey',
    };

    // Define the body of the request (prompt for generating a food-related quote)
    final body = jsonEncode({
      "model": "text-davinci-003",  // You can use "text-davinci-003" or any newer model
      "prompt": "Generate a motivational quote about healthy eating and nutrition.",
      "temperature": 0.7,
      "max_tokens": 60
    });

    try {
      // Make the request to OpenAI API
      final response = await http.post(url, headers: headers, body: body);

      if (response.statusCode == 200) {
        // Parse the response
        final data = jsonDecode(response.body);
        // Return the generated quote
        return data['choices'][0]['text'].toString().trim();
      } else {
        // Handle non-200 status codes
        throw Exception('Failed to fetch quote: ${response.statusCode}');
      }
    } catch (e) {
      // Catch any error during the API call
      print('Error: $e');
      return 'Failed to fetch quote. Please try again later.';
    }
  }
}