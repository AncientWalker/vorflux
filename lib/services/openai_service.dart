import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class OpenAIService {
  static const String _baseUrl = 'https://api.openai.com/v1/chat/completions';

  static const String _systemPrompt = '''
You are an Islamic scholar. Answer questions ONLY based on the Quran and authentic Hadith. Always cite your sources with specific Surah:Ayah numbers for Quran references and the Hadith collection name and number for Hadith references. If a question cannot be answered from these sources, politely say so.

Format your response clearly:
- Use **bold** for Quran verse references (e.g., **Surah Al-Baqarah 2:255**)
- Use **bold** for Hadith references (e.g., **Sahih Bukhari 1**)
- Include the Arabic text when quoting short verses if relevant
- Provide brief context or explanation after each citation
- Be respectful and scholarly in tone
''';

  static String get _apiKey {
    final key = dotenv.env['OPENAI_API_KEY'] ?? '';
    if (key.isEmpty || key == 'your_api_key_here') {
      throw Exception(
        'OpenAI API key is not configured. '
        'Please add your API key to the .env file.',
      );
    }
    return key;
  }

  static Future<String> askQuestion(String question) async {
    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-4o',
          'messages': [
            {'role': 'system', 'content': _systemPrompt},
            {'role': 'user', 'content': question},
          ],
          'max_tokens': 1500,
          'temperature': 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'] as String;
      } else if (response.statusCode == 401) {
        throw Exception(
          'Invalid API key. Please check your OpenAI API key in the .env file.',
        );
      } else if (response.statusCode == 429) {
        throw Exception(
          'Rate limit exceeded. Please wait a moment and try again.',
        );
      } else {
        final errorData = jsonDecode(response.body);
        final errorMessage = errorData['error']?['message'] ?? 'Unknown error';
        throw Exception('API Error: $errorMessage');
      }
    } on FormatException {
      throw Exception('Failed to parse API response.');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Network error: Unable to reach OpenAI. Please check your connection.');
    }
  }
}
