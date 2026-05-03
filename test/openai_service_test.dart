import 'dart:async';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:vorflux/services/openai_service.dart';

void main() {
  group('OpenAIService SSE parsing', () {
    test('parseSseStream yields content deltas from well-formed SSE', () async {
      final sseLines = [
        'data: {"choices":[{"delta":{"role":"assistant"},"index":0}]}\n\n',
        'data: {"choices":[{"delta":{"content":"Hello"},"index":0}]}\n\n',
        'data: {"choices":[{"delta":{"content":" world"},"index":0}]}\n\n',
        'data: [DONE]\n\n',
      ];

      final controller = StreamController<List<int>>();
      for (final line in sseLines) {
        controller.add(utf8.encode(line));
      }
      controller.close();

      final tokens = await OpenAIService.parseSseStream(controller.stream).toList();
      expect(tokens, equals(['Hello', ' world']));
    });

    test('parseSseStream handles chunked SSE data split across boundaries', () async {
      // Simulate a chunk that splits in the middle of a JSON line
      final controller = StreamController<List<int>>();
      controller.add(utf8.encode('data: {"choices":[{"delta":{"con'));
      controller.add(utf8.encode('tent":"part1"},"index":0}]}\n\n'));
      controller.add(utf8.encode('data: {"choices":[{"delta":{"content":"part2"},"index":0}]}\n\ndata: [DONE]\n\n'));
      controller.close();

      final tokens = await OpenAIService.parseSseStream(controller.stream).toList();
      expect(tokens, equals(['part1', 'part2']));
    });

    test('parseSseStream skips empty lines and non-data lines', () async {
      final controller = StreamController<List<int>>();
      controller.add(utf8.encode('\n\n'));
      controller.add(utf8.encode(': comment line\n\n'));
      controller.add(utf8.encode('data: {"choices":[{"delta":{"content":"ok"},"index":0}]}\n\n'));
      controller.add(utf8.encode('data: [DONE]\n\n'));
      controller.close();

      final tokens = await OpenAIService.parseSseStream(controller.stream).toList();
      expect(tokens, equals(['ok']));
    });

    test('parseSseStream handles delta with no content field', () async {
      final controller = StreamController<List<int>>();
      controller.add(utf8.encode('data: {"choices":[{"delta":{"role":"assistant"},"index":0}]}\n\n'));
      controller.add(utf8.encode('data: {"choices":[{"delta":{},"index":0}]}\n\n'));
      controller.add(utf8.encode('data: {"choices":[{"delta":{"content":"text"},"index":0}]}\n\n'));
      controller.add(utf8.encode('data: [DONE]\n\n'));
      controller.close();

      final tokens = await OpenAIService.parseSseStream(controller.stream).toList();
      expect(tokens, equals(['text']));
    });

    test('parseSseStream handles malformed JSON gracefully', () async {
      final controller = StreamController<List<int>>();
      controller.add(utf8.encode('data: {invalid json}\n\n'));
      controller.add(utf8.encode('data: {"choices":[{"delta":{"content":"after"},"index":0}]}\n\n'));
      controller.add(utf8.encode('data: [DONE]\n\n'));
      controller.close();

      final tokens = await OpenAIService.parseSseStream(controller.stream).toList();
      expect(tokens, equals(['after']));
    });

    test('parseSseStream handles empty choices array', () async {
      final controller = StreamController<List<int>>();
      controller.add(utf8.encode('data: {"choices":[]}\n\n'));
      controller.add(utf8.encode('data: {"choices":[{"delta":{"content":"ok"},"index":0}]}\n\n'));
      controller.add(utf8.encode('data: [DONE]\n\n'));
      controller.close();

      final tokens = await OpenAIService.parseSseStream(controller.stream).toList();
      expect(tokens, equals(['ok']));
    });

    test('parseSseStream handles remaining buffer after stream ends', () async {
      // Stream ends without a trailing newline
      final controller = StreamController<List<int>>();
      controller.add(utf8.encode('data: {"choices":[{"delta":{"content":"last"},"index":0}]}'));
      controller.close();

      final tokens = await OpenAIService.parseSseStream(controller.stream).toList();
      expect(tokens, equals(['last']));
    });

    test('parseSseStream stops at DONE sentinel', () async {
      final controller = StreamController<List<int>>();
      controller.add(utf8.encode('data: {"choices":[{"delta":{"content":"before"},"index":0}]}\n\n'));
      controller.add(utf8.encode('data: [DONE]\n\n'));
      // This should never be reached
      controller.add(utf8.encode('data: {"choices":[{"delta":{"content":"after"},"index":0}]}\n\n'));
      controller.close();

      final tokens = await OpenAIService.parseSseStream(controller.stream).toList();
      expect(tokens, equals(['before']));
    });
  });
}
