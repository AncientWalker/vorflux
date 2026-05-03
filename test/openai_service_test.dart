import 'dart:async';
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:vorflux/services/openai_service.dart';

/// Creates a byte stream from a list of SSE-formatted strings.
///
/// Each entry in [lines] is encoded to UTF-8 and added as a separate chunk.
/// This mirrors the way a real HTTP response body is delivered.
Stream<List<int>> sseStream(List<String> lines) {
  final controller = StreamController<List<int>>();
  for (final line in lines) {
    controller.add(utf8.encode(line));
  }
  controller.close();
  return controller.stream;
}

void main() {
  group('OpenAIService SSE parsing', () {
    test('parseSseStream yields content deltas from well-formed SSE', () async {
      final stream = sseStream([
        'data: {"choices":[{"delta":{"role":"assistant"},"index":0}]}\n\n',
        'data: {"choices":[{"delta":{"content":"Hello"},"index":0}]}\n\n',
        'data: {"choices":[{"delta":{"content":" world"},"index":0}]}\n\n',
        'data: [DONE]\n\n',
      ]);

      final tokens = await OpenAIService.parseSseStream(stream).toList();
      expect(tokens, equals(['Hello', ' world']));
    });

    test('parseSseStream handles chunked SSE data split across boundaries',
        () async {
      final stream = sseStream([
        'data: {"choices":[{"delta":{"con',
        'tent":"part1"},"index":0}]}\n\n',
        'data: {"choices":[{"delta":{"content":"part2"},"index":0}]}\n\ndata: [DONE]\n\n',
      ]);

      final tokens = await OpenAIService.parseSseStream(stream).toList();
      expect(tokens, equals(['part1', 'part2']));
    });

    test('parseSseStream skips empty lines and non-data lines', () async {
      final stream = sseStream([
        '\n\n',
        ': comment line\n\n',
        'data: {"choices":[{"delta":{"content":"ok"},"index":0}]}\n\n',
        'data: [DONE]\n\n',
      ]);

      final tokens = await OpenAIService.parseSseStream(stream).toList();
      expect(tokens, equals(['ok']));
    });

    test('parseSseStream handles delta with no content field', () async {
      final stream = sseStream([
        'data: {"choices":[{"delta":{"role":"assistant"},"index":0}]}\n\n',
        'data: {"choices":[{"delta":{},"index":0}]}\n\n',
        'data: {"choices":[{"delta":{"content":"text"},"index":0}]}\n\n',
        'data: [DONE]\n\n',
      ]);

      final tokens = await OpenAIService.parseSseStream(stream).toList();
      expect(tokens, equals(['text']));
    });

    test('parseSseStream handles malformed JSON gracefully', () async {
      final stream = sseStream([
        'data: {invalid json}\n\n',
        'data: {"choices":[{"delta":{"content":"after"},"index":0}]}\n\n',
        'data: [DONE]\n\n',
      ]);

      final tokens = await OpenAIService.parseSseStream(stream).toList();
      expect(tokens, equals(['after']));
    });

    test('parseSseStream handles empty choices array', () async {
      final stream = sseStream([
        'data: {"choices":[]}\n\n',
        'data: {"choices":[{"delta":{"content":"ok"},"index":0}]}\n\n',
        'data: [DONE]\n\n',
      ]);

      final tokens = await OpenAIService.parseSseStream(stream).toList();
      expect(tokens, equals(['ok']));
    });

    test('parseSseStream handles remaining buffer after stream ends', () async {
      // Stream ends without a trailing newline
      final stream = sseStream([
        'data: {"choices":[{"delta":{"content":"last"},"index":0}]}',
      ]);

      final tokens = await OpenAIService.parseSseStream(stream).toList();
      expect(tokens, equals(['last']));
    });

    test('parseSseStream stops at DONE sentinel', () async {
      final stream = sseStream([
        'data: {"choices":[{"delta":{"content":"before"},"index":0}]}\n\n',
        'data: [DONE]\n\n',
        // This should never be reached
        'data: {"choices":[{"delta":{"content":"after"},"index":0}]}\n\n',
      ]);

      final tokens = await OpenAIService.parseSseStream(stream).toList();
      expect(tokens, equals(['before']));
    });
  });

  group('OpenAIService.askQuestionStream error handling', () {
    setUpAll(() async {
      // Load the .env file so that _apiKey does not throw during tests.
      await dotenv.load(fileName: '.env');
    });

    test('throws on 401 with invalid API key message', () async {
      final client = MockClient((request) async {
        return http.Response('Unauthorized', 401);
      });

      expect(
        () => OpenAIService.askQuestionStream('test', client: client).toList(),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Invalid API key'),
          ),
        ),
      );
    });

    test('throws on 429 with rate limit message', () async {
      final client = MockClient((request) async {
        return http.Response('Too Many Requests', 429);
      });

      expect(
        () => OpenAIService.askQuestionStream('test', client: client).toList(),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Rate limit exceeded'),
          ),
        ),
      );
    });

    test('parses error message from JSON body on generic error', () async {
      final errorBody = jsonEncode({
        'error': {'message': 'Model not found'},
      });
      final client = MockClient((request) async {
        return http.Response(errorBody, 404);
      });

      expect(
        () => OpenAIService.askQuestionStream('test', client: client).toList(),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('API Error: Model not found'),
          ),
        ),
      );
    });

    test('falls back to status code when error body is not JSON', () async {
      final client = MockClient((request) async {
        return http.Response('not json', 500);
      });

      expect(
        () => OpenAIService.askQuestionStream('test', client: client).toList(),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('API Error: 500'),
          ),
        ),
      );
    });
  });
}
