import 'dart:convert';
import 'package:http/http.dart' as http;

class AiBioService {
  static String get _apiKey => const String.fromEnvironment('OPENAI_API_KEY', defaultValue: '');
  static const String _endpoint = 'https://api.openai.com/v1/chat/completions';

  static Future<String?> generateBio({
    required String name,
    required String profession,
    required String experience,
    required String skills,
    required String location,
  }) async {
    if (_apiKey.isEmpty) {
      print('AI Bio service error: OpenAI API key not configured');
      return null;
    }
    final prompt =
        'Write a short, professional artisan bio for $name, a $profession in $location, with $experience experience. Highlight these skills: $skills.';

    final response = await http.post(
      Uri.parse(_endpoint),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_apiKey',
      },
      body: jsonEncode({
        'model': 'gpt-3.5-turbo',
        'messages': [
          {'role': 'system', 'content': 'You are a helpful assistant for writing artisan bios.'},
          {'role': 'user', 'content': prompt},
        ],
        'max_tokens': 120,
        'temperature': 0.7,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['choices'][0]['message']['content']?.trim();
    } else {
      print('AI Bio generation failed: ${response.body}');
      return null;
    }
  }
}
