import 'dart:convert';
import 'package:http/http.dart' as http;

class OpenAIService {
  static const String _apiKey = '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'; // Replace with your key
  static const String _apiUrl = 'https://api.openai.com/v1/chat/completions';

  Future<String> sendMessage(String userInput) async {
    try {
      final prompt = """
        You are a car sales assistant. Extract a clean and effective vehicle search query from the user's message. 
        Only include keywords like make, model, color, year, or important features. Don't explain anything.
        Just return a short search query string that could be used in a search engine.
        
        Examples:
        User: "I need a 2018 or newer white Toyota Vitz with petrol engine"
        Output: "Toyota Vitz 2018+ White Petrol"
        
        User: "$userInput"
        Output:
        """;

      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "model": "gpt-4o",
          "messages": [
            {
              "role": "system",
              "content": "You are a helpful assistant that converts user needs into vehicle search terms."
            },
            {
              "role": "user",
              "content": prompt
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'].trim();
      } else {
        // Helpful logging for debugging
        final errorBody = jsonDecode(response.body);
        return "❌ OpenAI API Error ${response.statusCode}: ${errorBody['error']?['message'] ?? 'Unknown error'}";
      }
    } catch (e) {
      return "⚠️ Error: Unable to connect to AI. $e";
    }
  }
}
