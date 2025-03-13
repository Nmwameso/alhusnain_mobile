import 'dart:convert';
import 'package:http/http.dart' as http;

class OpenAIService {
  static const String _apiKey = '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'; // Replace with your API key
  static const String _apiUrl = 'https://api.openai.com/v1/chat/completions';

  Future<String> sendMessage(String message) async {
    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "model": "gpt-4",
          "messages": [
            {"role": "system", "content": "You are a helpful car sales assistant."},
            {"role": "user", "content": message}
          ]
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'].trim();
      } else {
        return "❌ Error: ${response.statusCode}";
      }
    } catch (e) {
      return "⚠️ Error: Unable to connect to AI.";
    }
  }
}
