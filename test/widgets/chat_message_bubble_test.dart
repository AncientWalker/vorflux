import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vorflux/models/chat_message.dart';
import 'package:vorflux/widgets/chat_message_bubble.dart';

void main() {
  Widget buildTestWidget(ChatMessageBubble bubble) {
    return MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: bubble,
        ),
      ),
    );
  }

  group('ChatMessageBubble feedback', () {
    testWidgets('assistant bubble shows feedback row when onFeedback is provided', (tester) async {
      final message = ChatMessage(
        id: 'msg-1',
        threadId: 'thread-1',
        role: 'assistant',
        content: 'Test answer',
        timestamp: DateTime(2025, 1, 1),
      );

      await tester.pumpWidget(buildTestWidget(
        ChatMessageBubble(
          message: message,
          onFeedback: (_, __) async {},
        ),
      ));

      expect(find.text('Was this helpful?'), findsOneWidget);
      expect(find.byIcon(Icons.thumb_up_outlined), findsOneWidget);
      expect(find.byIcon(Icons.thumb_down_outlined), findsOneWidget);
    });

    testWidgets('assistant bubble hides feedback row when onFeedback is null', (tester) async {
      final message = ChatMessage(
        id: 'msg-1',
        threadId: 'thread-1',
        role: 'assistant',
        content: 'Test answer',
        timestamp: DateTime(2025, 1, 1),
      );

      await tester.pumpWidget(buildTestWidget(
        ChatMessageBubble(message: message),
      ));

      expect(find.text('Was this helpful?'), findsNothing);
      expect(find.byIcon(Icons.thumb_up_outlined), findsNothing);
      expect(find.byIcon(Icons.thumb_down_outlined), findsNothing);
    });

    testWidgets('user bubble does not show feedback row', (tester) async {
      final message = ChatMessage(
        id: 'msg-1',
        threadId: 'thread-1',
        role: 'user',
        content: 'Test question',
        timestamp: DateTime(2025, 1, 1),
      );

      await tester.pumpWidget(buildTestWidget(
        ChatMessageBubble(
          message: message,
          onFeedback: (_, __) async {},
        ),
      ));

      expect(find.text('Was this helpful?'), findsNothing);
    });

    testWidgets('tapping thumbs up calls onFeedback with up when no current feedback', (tester) async {
      String? receivedId;
      String? receivedFeedback;

      final message = ChatMessage(
        id: 'msg-1',
        threadId: 'thread-1',
        role: 'assistant',
        content: 'Test answer',
        timestamp: DateTime(2025, 1, 1),
      );

      await tester.pumpWidget(buildTestWidget(
        ChatMessageBubble(
          message: message,
          onFeedback: (id, feedback) async {
            receivedId = id;
            receivedFeedback = feedback;
          },
        ),
      ));

      await tester.tap(find.byIcon(Icons.thumb_up_outlined));
      await tester.pump();

      expect(receivedId, 'msg-1');
      expect(receivedFeedback, 'up');
    });

    testWidgets('tapping thumbs up toggles off when already up', (tester) async {
      String? receivedFeedback = 'not-called';

      final message = ChatMessage(
        id: 'msg-1',
        threadId: 'thread-1',
        role: 'assistant',
        content: 'Test answer',
        timestamp: DateTime(2025, 1, 1),
        feedback: 'up',
      );

      await tester.pumpWidget(buildTestWidget(
        ChatMessageBubble(
          message: message,
          onFeedback: (id, feedback) async {
            receivedFeedback = feedback;
          },
        ),
      ));

      // When feedback is 'up', the filled icon is shown
      await tester.tap(find.byIcon(Icons.thumb_up));
      await tester.pump();

      expect(receivedFeedback, isNull);
    });

    testWidgets('tapping thumbs down calls onFeedback with down', (tester) async {
      String? receivedFeedback;

      final message = ChatMessage(
        id: 'msg-1',
        threadId: 'thread-1',
        role: 'assistant',
        content: 'Test answer',
        timestamp: DateTime(2025, 1, 1),
      );

      await tester.pumpWidget(buildTestWidget(
        ChatMessageBubble(
          message: message,
          onFeedback: (id, feedback) async {
            receivedFeedback = feedback;
          },
        ),
      ));

      await tester.tap(find.byIcon(Icons.thumb_down_outlined));
      await tester.pump();

      expect(receivedFeedback, 'down');
    });

    testWidgets('shows filled thumb_up icon when feedback is up', (tester) async {
      final message = ChatMessage(
        id: 'msg-1',
        threadId: 'thread-1',
        role: 'assistant',
        content: 'Test answer',
        timestamp: DateTime(2025, 1, 1),
        feedback: 'up',
      );

      await tester.pumpWidget(buildTestWidget(
        ChatMessageBubble(
          message: message,
          onFeedback: (_, __) async {},
        ),
      ));

      expect(find.byIcon(Icons.thumb_up), findsOneWidget);
      expect(find.byIcon(Icons.thumb_up_outlined), findsNothing);
      expect(find.byIcon(Icons.thumb_down_outlined), findsOneWidget);
    });

    testWidgets('shows filled thumb_down icon when feedback is down', (tester) async {
      final message = ChatMessage(
        id: 'msg-1',
        threadId: 'thread-1',
        role: 'assistant',
        content: 'Test answer',
        timestamp: DateTime(2025, 1, 1),
        feedback: 'down',
      );

      await tester.pumpWidget(buildTestWidget(
        ChatMessageBubble(
          message: message,
          onFeedback: (_, __) async {},
        ),
      ));

      expect(find.byIcon(Icons.thumb_down), findsOneWidget);
      expect(find.byIcon(Icons.thumb_down_outlined), findsNothing);
      expect(find.byIcon(Icons.thumb_up_outlined), findsOneWidget);
    });

    testWidgets('buttons are disabled while feedback is saving', (tester) async {
      final completer = Completer<void>();
      var callCount = 0;

      final message = ChatMessage(
        id: 'msg-1',
        threadId: 'thread-1',
        role: 'assistant',
        content: 'Test answer',
        timestamp: DateTime(2025, 1, 1),
      );

      await tester.pumpWidget(buildTestWidget(
        ChatMessageBubble(
          message: message,
          onFeedback: (id, feedback) {
            callCount++;
            return completer.future;
          },
        ),
      ));

      // First tap should go through
      await tester.tap(find.byIcon(Icons.thumb_up_outlined));
      await tester.pump();
      expect(callCount, 1);

      // Second tap while still saving should be ignored
      await tester.tap(find.byIcon(Icons.thumb_up_outlined));
      await tester.pump();
      expect(callCount, 1);

      // Complete the save and verify buttons re-enable
      completer.complete();
      await tester.pump();

      // Now tapping should work again
      await tester.tap(find.byIcon(Icons.thumb_up_outlined));
      await tester.pump();
      expect(callCount, 2);
    });
  });
}
