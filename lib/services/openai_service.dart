import 'dart:async';
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

  /// Parses an SSE byte stream into content delta strings.
  /// Exposed as a static method for testability.
  static Stream<String> parseSseStream(Stream<List<int>> byteStream) async* {
    String buffer = '';
    await for (final chunk in byteStream.transform(utf8.decoder)) {
      buffer += chunk;
      while (buffer.contains('\n')) {
        final newlineIndex = buffer.indexOf('\n');
        final line = buffer.substring(0, newlineIndex).trim();
        buffer = buffer.substring(newlineIndex + 1);

        if (line.isEmpty) continue;
        final content = _extractContentFromSseLine(line);
        if (content == null) continue;
        if (content == _done) return;
        yield content;
      }
    }

    // Process any remaining data in the buffer
    if (buffer.trim().isNotEmpty) {
      final content = _extractContentFromSseLine(buffer.trim());
      if (content != null && content != _done) {
        yield content;
      }
    }
  }

  static const String _done = '\x00DONE';

  /// Extracts the content delta from a single SSE line.
  /// Returns null if the line has no content, or [_done] if the stream is finished.
  static String? _extractContentFromSseLine(String line) {
    if (!line.startsWith('data: ')) return null;
    final data = line.substring(6);
    if (data == '[DONE]') return _done;

    try {
      final json = jsonDecode(data) as Map<String, dynamic>;
      final choices = json['choices'] as List<dynamic>?;
      if (choices != null && choices.isNotEmpty) {
        final delta = choices[0]['delta'] as Map<String, dynamic>? ?? {};
        return delta['content'] as String?;
      }
    } on FormatException {
      // Skip malformed JSON chunks
    }
    return null;
  }

  /// Streams the AI response token-by-token using OpenAI's SSE streaming API.
  /// Each yielded string is a content delta (partial token).
  static Stream<String> askQuestionStream(String question) async* {
    final client = http.Client();
    try {
      final request = http.Request('POST', Uri.parse(_baseUrl));
      request.headers.addAll({
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_apiKey',
      });
      request.body = jsonEncode({
        'model': 'gpt-4o',
        'messages': [
          {'role': 'system', 'content': _systemPrompt},
          {'role': 'user', 'content': question},
        ],
        'max_tokens': 1500,
        'temperature': 0.7,
        'stream': true,
      });

      final response = await client.send(request);

      if (response.statusCode != 200) {
        final body = await response.stream.bytesToString();
        if (response.statusCode == 401) {
          throw Exception(
            'Invalid API key. Please check your OpenAI API key in the .env file.',
          );
        } else if (response.statusCode == 429) {
          throw Exception(
            'Rate limit exceeded. Please wait a moment and try again.',
          );
        } else {
          try {
            final errorData = jsonDecode(body);
            final errorMessage =
                errorData['error']?['message'] ?? 'Unknown error';
            throw Exception('API Error: $errorMessage');
          } on FormatException {
            throw Exception('API Error: ${response.statusCode}');
          }
        }
      }

      yield* parseSseStream(response.stream);
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception(
        'Network error: Unable to reach OpenAI. Please check your connection.',
      );
    } finally {
      client.close();
    }
  }
}
