import 'dart:async';
import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:vorflux/models/chat_message.dart';

class OpenAIService {
  static const String _baseUrl = 'https://api.openai.com/v1/chat/completions';
  static const int _maxContextMessages = 20;

  static const String _systemPrompt = '''
You are an Islamic scholar. Answer questions ONLY based on the Quran and authentic Hadith. Always cite your sources with specific Surah:Ayah numbers for Quran references and the Hadith collection name and number for Hadith references. If a question cannot be answered from these sources, politely say so.

Format your response clearly:
- Use **bold** for Quran verse references (e.g., **Surah Al-Baqarah 2:255**)
- Use **bold** for Hadith references (e.g., **Sahih Bukhari 1**)
- Include the Arabic text when quoting short verses if relevant
- Provide brief context or explanation after each citation
- Be respectful and scholarly in tone
''';

  /// Sentinel value returned by [_extractContentFromSseLine] to signal
  /// the end of the SSE stream (`[DONE]`).
  static const String _done = '\x00DONE';

  static List<Map<String, String>> buildMessagesPayload(
    String question, {
    List<ChatMessage> conversationHistory = const [],
  }) {
    final messages = <Map<String, String>>[
      {'role': 'system', 'content': _systemPrompt},
    ];

    final recentHistory = conversationHistory.length > _maxContextMessages
        ? conversationHistory.sublist(
            conversationHistory.length - _maxContextMessages,
          )
        : conversationHistory;

    for (final msg in recentHistory) {
      messages.add({'role': msg.role, 'content': msg.content});
    }

    messages.add({'role': 'user', 'content': question});
    return messages;
  }

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

  static Future<String> askQuestion(
    String question, {
    List<ChatMessage> conversationHistory = const [],
  }) async {
    try {
      final messages = buildMessagesPayload(
        question,
        conversationHistory: conversationHistory,
      );
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-4o',
          'messages': messages,
          'max_tokens': 1500,
          'temperature': 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data['choices'][0]['message']['content'] as String;
      }
      if (response.statusCode == 401) {
        throw Exception(
          'Invalid API key. Please check your OpenAI API key in the .env file.',
        );
      }
      if (response.statusCode == 429) {
        throw Exception(
          'Rate limit exceeded. Please wait a moment and try again.',
        );
      }

      final errorData = jsonDecode(response.body) as Map<String, dynamic>;
      final errorMessage = errorData['error']?['message'] ?? 'Unknown error';
      throw Exception('API Error: $errorMessage');
    } on FormatException {
      throw Exception('Failed to parse API response.');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception(
        'Network error: Unable to reach OpenAI. Please check your connection.',
      );
    }
  }

  static Stream<String> parseSseStream(Stream<List<int>> byteStream) async* {
    final buffer = StringBuffer();

    await for (final chunk in byteStream.transform(utf8.decoder)) {
      buffer.write(chunk);
      var text = buffer.toString();

      while (text.contains('\n')) {
        final newlineIndex = text.indexOf('\n');
        final line = text.substring(0, newlineIndex).trim();
        text = text.substring(newlineIndex + 1);

        if (line.isEmpty) continue;
        final content = _extractContentFromSseLine(line);
        if (content == null) continue;
        if (content == _done) return;
        yield content;
      }

      buffer
        ..clear()
        ..write(text);
    }

    final remaining = buffer.toString().trim();
    if (remaining.isNotEmpty) {
      final content = _extractContentFromSseLine(remaining);
      if (content != null && content != _done) {
        yield content;
      }
    }
  }

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
      // Skip malformed JSON chunks.
    }

    return null;
  }

  static Stream<String> askQuestionStream(
    String question, {
    List<ChatMessage> conversationHistory = const [],
    http.Client? client,
  }) async* {
    final ownClient = client == null;
    client ??= http.Client();

    try {
      final messages = buildMessagesPayload(
        question,
        conversationHistory: conversationHistory,
      );
      final request = http.Request('POST', Uri.parse(_baseUrl));
      request.headers.addAll({
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_apiKey',
      });
      request.body = jsonEncode({
        'model': 'gpt-4o',
        'messages': messages,
        'max_tokens': 1500,
        'temperature': 0.7,
        'stream': true,
      });

      final response = await client.send(request);

      if (response.statusCode != 200) {
        if (response.statusCode == 401) {
          await response.stream.drain<void>();
          throw Exception(
            'Invalid API key. Please check your OpenAI API key in the .env file.',
          );
        }
        if (response.statusCode == 429) {
          await response.stream.drain<void>();
          throw Exception(
            'Rate limit exceeded. Please wait a moment and try again.',
          );
        }

        final body = await response.stream.bytesToString();
        try {
          final errorData = jsonDecode(body) as Map<String, dynamic>;
          final errorMessage =
              errorData['error']?['message'] ?? 'Unknown error';
          throw Exception('API Error: $errorMessage');
        } on FormatException {
          throw Exception('API Error: ${response.statusCode}');
        }
      }

      yield* parseSseStream(response.stream);
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception(
        'Network error: Unable to reach OpenAI. Please check your connection.',
      );
    } finally {
      if (ownClient) client.close();
    }
  }
}
