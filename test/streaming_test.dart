import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:vorflux/services/openai_service.dart';
import 'package:vorflux/widgets/chat_message_bubble.dart';

import 'helpers/test_factories.dart';

/// Creates a byte stream from a list of SSE-formatted strings.
Stream<List<int>> sseStream(List<String> lines) {
  final controller = StreamController<List<int>>();
  for (final line in lines) {
    controller.add(utf8.encode(line));
  }
  controller.close();
  return controller.stream;
}

void main() {
  group('askQuestionStream with conversationHistory', () {
    setUpAll(() async {
      await dotenv.load(fileName: '.env');
    });

    test('includes conversation history in request body', () async {
      Map<String, dynamic>? capturedBody;

      final client = MockClient.streaming((request, bodyStream) async {
        final bodyBytes = await bodyStream.toBytes();
        capturedBody = jsonDecode(utf8.decode(bodyBytes)) as Map<String, dynamic>;

        // Return a valid SSE response
        final responseController = StreamController<List<int>>();
        responseController.add(utf8.encode(
          'data: {"choices":[{"delta":{"content":"ok"},"index":0}]}\n\n',
        ));
        responseController.add(utf8.encode('data: [DONE]\n\n'));
        responseController.close();

        return http.StreamedResponse(responseController.stream, 200);
      });

      final history = [
        makeMessage(
          id: 'h1',
          role: 'user',
          content: 'Previous question',
        ),
        makeMessage(
          id: 'h2',
          role: 'assistant',
          content: 'Previous answer',
        ),
      ];

      final tokens = await OpenAIService.askQuestionStream(
        'New question',
        conversationHistory: history,
        client: client,
      ).toList();

      expect(tokens, equals(['ok']));
      expect(capturedBody, isNotNull);

      final messages = capturedBody!['messages'] as List<dynamic>;
      // Should be: system + 2 history + new user question = 4 messages
      expect(messages.length, equals(4));
      expect(messages[0]['role'], equals('system'));
      expect(messages[1]['role'], equals('user'));
      expect(messages[1]['content'], equals('Previous question'));
      expect(messages[2]['role'], equals('assistant'));
      expect(messages[2]['content'], equals('Previous answer'));
      expect(messages[3]['role'], equals('user'));
      expect(messages[3]['content'], equals('New question'));
      expect(capturedBody!['stream'], isTrue);
    });

    test('sends only system + user when no history provided', () async {
      Map<String, dynamic>? capturedBody;

      final client = MockClient.streaming((request, bodyStream) async {
        final bodyBytes = await bodyStream.toBytes();
        capturedBody = jsonDecode(utf8.decode(bodyBytes)) as Map<String, dynamic>;

        final responseController = StreamController<List<int>>();
        responseController.add(utf8.encode(
          'data: {"choices":[{"delta":{"content":"ok"},"index":0}]}\n\n',
        ));
        responseController.add(utf8.encode('data: [DONE]\n\n'));
        responseController.close();

        return http.StreamedResponse(responseController.stream, 200);
      });

      await OpenAIService.askQuestionStream(
        'Solo question',
        client: client,
      ).toList();

      expect(capturedBody, isNotNull);
      final messages = capturedBody!['messages'] as List<dynamic>;
      // Should be: system + user = 2 messages
      expect(messages.length, equals(2));
      expect(messages[0]['role'], equals('system'));
      expect(messages[1]['role'], equals('user'));
      expect(messages[1]['content'], equals('Solo question'));
    });

    test('streams multiple tokens progressively', () async {
      final client = MockClient.streaming((request, bodyStream) async {
        await bodyStream.toBytes(); // consume body

        final responseController = StreamController<List<int>>();
        responseController.add(utf8.encode(
          'data: {"choices":[{"delta":{"content":"Hello"},"index":0}]}\n\n',
        ));
        responseController.add(utf8.encode(
          'data: {"choices":[{"delta":{"content":" "},"index":0}]}\n\n',
        ));
        responseController.add(utf8.encode(
          'data: {"choices":[{"delta":{"content":"world"},"index":0}]}\n\n',
        ));
        responseController.add(utf8.encode('data: [DONE]\n\n'));
        responseController.close();

        return http.StreamedResponse(responseController.stream, 200);
      });

      final tokens = <String>[];
      await for (final token in OpenAIService.askQuestionStream(
        'test',
        client: client,
      )) {
        tokens.add(token);
      }

      expect(tokens, equals(['Hello', ' ', 'world']));
    });
  });

  group('ChatMessageBubble streaming indicator', () {
    testWidgets('shows blinking cursor when isStreaming is true',
        (tester) async {
      final message = makeMessage(
        content: 'Partial answer',
        role: 'assistant',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ChatMessageBubble(
                message: message,
                isStreaming: true,
              ),
            ),
          ),
        ),
      );

      // FadeTransition should be present for the blinking cursor
      // (scoped to ChatMessageBubble to avoid matching MaterialApp transitions)
      expect(
        find.descendant(
          of: find.byType(ChatMessageBubble),
          matching: find.byType(FadeTransition),
        ),
        findsOneWidget,
      );

      // Timestamp should NOT be shown during streaming
      expect(find.text(message.formattedTimestamp), findsNothing);
    });

    testWidgets('hides cursor and shows timestamp when not streaming',
        (tester) async {
      final message = makeMessage(
        content: 'Full answer',
        role: 'assistant',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ChatMessageBubble(
                message: message,
                isStreaming: false,
              ),
            ),
          ),
        ),
      );

      // FadeTransition (cursor) should NOT be present within the bubble
      expect(
        find.descendant(
          of: find.byType(ChatMessageBubble),
          matching: find.byType(FadeTransition),
        ),
        findsNothing,
      );

      // Timestamp should be shown
      expect(find.text(message.formattedTimestamp), findsOneWidget);
    });

    testWidgets('handles empty content during streaming', (tester) async {
      final message = makeMessage(
        content: '',
        role: 'assistant',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ChatMessageBubble(
                message: message,
                isStreaming: true,
              ),
            ),
          ),
        ),
      );

      // Should not crash with empty content
      // FadeTransition (cursor) should be present within the bubble
      expect(
        find.descendant(
          of: find.byType(ChatMessageBubble),
          matching: find.byType(FadeTransition),
        ),
        findsOneWidget,
      );
    });

    testWidgets('does not show feedback row during streaming', (tester) async {
      final message = makeMessage(
        content: 'Streaming...',
        role: 'assistant',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ChatMessageBubble(
                message: message,
                isStreaming: true,
                // onFeedback is null during streaming
              ),
            ),
          ),
        ),
      );

      // Feedback row should not be present
      expect(find.text('Was this helpful?'), findsNothing);
    });

    testWidgets('disposes cursor animation controller properly',
        (tester) async {
      final message = makeMessage(
        content: 'Answer',
        role: 'assistant',
      );

      // Start with streaming
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ChatMessageBubble(
                key: const ValueKey('bubble'),
                message: message,
                isStreaming: true,
              ),
            ),
          ),
        ),
      );

      expect(
        find.descendant(
          of: find.byType(ChatMessageBubble),
          matching: find.byType(FadeTransition),
        ),
        findsOneWidget,
      );

      // Switch to not streaming
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ChatMessageBubble(
                key: const ValueKey('bubble'),
                message: message,
                isStreaming: false,
              ),
            ),
          ),
        ),
      );

      // Cursor should be gone
      expect(
        find.descendant(
          of: find.byType(ChatMessageBubble),
          matching: find.byType(FadeTransition),
        ),
        findsNothing,
      );
    });
  });
}
