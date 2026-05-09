import 'package:flutter_test/flutter_test.dart';
import 'package:vorflux/models/chat_message.dart';
import 'package:vorflux/models/conversation_thread.dart';
import 'package:vorflux/services/openai_service.dart';
import 'package:vorflux/utils/text_utils.dart';

void main() {
  group('formatRelativeTimestamp', () {
    test('returns Just now for less than a minute', () {
      final dateTime = DateTime.now().subtract(const Duration(seconds: 30));
      expect(formatRelativeTimestamp(dateTime), 'Just now');
    });

    test('returns minutes for less than an hour', () {
      final dateTime = DateTime.now().subtract(const Duration(minutes: 5));
      expect(formatRelativeTimestamp(dateTime), '5m ago');
    });

    test('returns hours for less than a day', () {
      final dateTime = DateTime.now().subtract(const Duration(hours: 3));
      expect(formatRelativeTimestamp(dateTime), '3h ago');
    });

    test('returns days for less than a week', () {
      final dateTime = DateTime.now().subtract(const Duration(days: 4));
      expect(formatRelativeTimestamp(dateTime), '4d ago');
    });

    test('returns calendar date for a week or more', () {
      expect(formatRelativeTimestamp(DateTime(2025, 1, 5)), '05/01/2025');
    });
  });

  group('ChatMessage', () {
    test('toMap()/fromMap() round-trip preserves all fields', () {
      final timestamp = DateTime(2025, 6, 15, 10, 30, 0);
      final message = ChatMessage(
        id: 'msg-1',
        threadId: 'thread-1',
        role: 'user',
        content: 'What is the meaning of life?',
        timestamp: timestamp,
      );

      final map = message.toMap();
      final restored = ChatMessage.fromMap(map);

      expect(restored.id, 'msg-1');
      expect(restored.threadId, 'thread-1');
      expect(restored.role, 'user');
      expect(restored.content, 'What is the meaning of life?');
      expect(restored.timestamp, timestamp);
    });

    test('toMap() serializes timestamp as ISO 8601 string', () {
      final timestamp = DateTime(2025, 6, 15, 10, 30, 0);
      final message = ChatMessage(
        id: 'msg-1',
        threadId: 'thread-1',
        role: 'user',
        content: 'test',
        timestamp: timestamp,
      );

      final map = message.toMap();
      expect(map['timestamp'], timestamp.toIso8601String());
    });

    test('formattedTimestamp delegates to formatter for < 1 minute', () {
      final message = ChatMessage(
        id: 'msg-1',
        threadId: 'thread-1',
        role: 'user',
        content: 'test',
        timestamp: DateTime.now().subtract(const Duration(seconds: 30)),
      );

      expect(message.formattedTimestamp, 'Just now');
    });

    test('formattedTimestamp delegates to formatter for < 60 minutes', () {
      final message = ChatMessage(
        id: 'msg-1',
        threadId: 'thread-1',
        role: 'user',
        content: 'test',
        timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
      );

      expect(message.formattedTimestamp, '5m ago');
    });

    test('formattedTimestamp delegates to formatter for < 24 hours', () {
      final message = ChatMessage(
        id: 'msg-1',
        threadId: 'thread-1',
        role: 'user',
        content: 'test',
        timestamp: DateTime.now().subtract(const Duration(hours: 3)),
      );

      expect(message.formattedTimestamp, '3h ago');
    });

    test('formattedTimestamp delegates to formatter for < 7 days', () {
      final message = ChatMessage(
        id: 'msg-1',
        threadId: 'thread-1',
        role: 'user',
        content: 'test',
        timestamp: DateTime.now().subtract(const Duration(days: 4)),
      );

      expect(message.formattedTimestamp, '4d ago');
    });

    test('formattedTimestamp delegates to formatter for >= 7 days', () {
      final message = ChatMessage(
        id: 'msg-1',
        threadId: 'thread-1',
        role: 'user',
        content: 'test',
        timestamp: DateTime(2025, 1, 5),
      );

      expect(message.formattedTimestamp, '05/01/2025');
    });

    test('feedback field defaults to null', () {
      final message = ChatMessage(
        id: 'msg-1',
        threadId: 'thread-1',
        role: 'assistant',
        content: 'test',
        timestamp: DateTime(2025, 6, 15),
      );
      expect(message.feedback, isNull);
    });

    test('fromMap with feedback up', () {
      final map = {
        'id': 'msg-1',
        'threadId': 'thread-1',
        'role': 'assistant',
        'content': 'test',
        'timestamp': '2025-06-15T00:00:00.000',
        'feedback': 'up',
      };
      final message = ChatMessage.fromMap(map);
      expect(message.feedback, 'up');
    });

    test('fromMap with no feedback key defaults to null', () {
      final map = {
        'id': 'msg-1',
        'threadId': 'thread-1',
        'role': 'assistant',
        'content': 'test',
        'timestamp': '2025-06-15T00:00:00.000',
      };
      final message = ChatMessage.fromMap(map);
      expect(message.feedback, isNull);
    });

    test('toMap includes feedback field', () {
      final message = ChatMessage(
        id: 'msg-1',
        threadId: 'thread-1',
        role: 'assistant',
        content: 'test',
        timestamp: DateTime(2025, 6, 15),
        feedback: 'down',
      );
      final map = message.toMap();
      expect(map['feedback'], 'down');
    });

    test('toMap includes null feedback', () {
      final message = ChatMessage(
        id: 'msg-1',
        threadId: 'thread-1',
        role: 'assistant',
        content: 'test',
        timestamp: DateTime(2025, 6, 15),
      );
      final map = message.toMap();
      expect(map.containsKey('feedback'), true);
      expect(map['feedback'], isNull);
    });

    test('copyWith sets feedback to up', () {
      final message = ChatMessage(
        id: 'msg-1',
        threadId: 'thread-1',
        role: 'assistant',
        content: 'test',
        timestamp: DateTime(2025, 6, 15),
      );
      final updated = message.copyWith(feedback: () => 'up');
      expect(updated.feedback, 'up');
      expect(updated.id, 'msg-1'); // other fields preserved
    });

    test('copyWith clears feedback to null', () {
      final message = ChatMessage(
        id: 'msg-1',
        threadId: 'thread-1',
        role: 'assistant',
        content: 'test',
        timestamp: DateTime(2025, 6, 15),
        feedback: 'up',
      );
      final updated = message.copyWith(feedback: () => null);
      expect(updated.feedback, isNull);
    });

    test('copyWith with no feedback arg preserves existing', () {
      final message = ChatMessage(
        id: 'msg-1',
        threadId: 'thread-1',
        role: 'assistant',
        content: 'test',
        timestamp: DateTime(2025, 6, 15),
        feedback: 'down',
      );
      final updated = message.copyWith(content: 'new content');
      expect(updated.feedback, 'down');
      expect(updated.content, 'new content');
    });

    test('toMap/fromMap round-trip preserves feedback', () {
      final message = ChatMessage(
        id: 'msg-1',
        threadId: 'thread-1',
        role: 'assistant',
        content: 'test',
        timestamp: DateTime(2025, 6, 15),
        feedback: 'up',
      );
      final restored = ChatMessage.fromMap(message.toMap());
      expect(restored.feedback, 'up');
    });
  });

  group('ConversationThread', () {
    test('toMap()/fromMap() round-trip preserves all fields', () {
      final createdAt = DateTime(2025, 6, 15, 10, 0, 0);
      final updatedAt = DateTime(2025, 6, 15, 11, 0, 0);
      final thread = ConversationThread(
        id: 'thread-1',
        title: 'Test Thread',
        createdAt: createdAt,
        updatedAt: updatedAt,
        userId: 'user-1',
        userName: 'Test User',
        userPhotoURL: 'https://example.com/photo.jpg',
        messageCount: 5,
        lastMessagePreview: 'Hello, world!',
      );

      final map = thread.toMap();
      final restored = ConversationThread.fromMap(map);

      expect(restored.id, 'thread-1');
      expect(restored.title, 'Test Thread');
      expect(restored.createdAt, createdAt);
      expect(restored.updatedAt, updatedAt);
      expect(restored.userId, 'user-1');
      expect(restored.userName, 'Test User');
      expect(restored.userPhotoURL, 'https://example.com/photo.jpg');
      expect(restored.messageCount, 5);
      expect(restored.lastMessagePreview, 'Hello, world!');
    });

    test('fromMap() defaults messageCount to 0 and lastMessagePreview to empty string when null', () {
      final map = {
        'id': 'thread-1',
        'title': 'Test',
        'createdAt': DateTime(2025, 6, 15).toIso8601String(),
        'updatedAt': DateTime(2025, 6, 15).toIso8601String(),
        'userId': null,
        'userName': null,
        'userPhotoURL': null,
        'messageCount': null,
        'lastMessagePreview': null,
      };

      final thread = ConversationThread.fromMap(map);
      expect(thread.messageCount, 0);
      expect(thread.lastMessagePreview, '');
    });

    test('toMap() does not include messages list', () {
      final thread = ConversationThread(
        id: 'thread-1',
        title: 'Test',
        createdAt: DateTime(2025, 6, 15),
        updatedAt: DateTime(2025, 6, 15),
        messages: [
          ChatMessage(
            id: 'msg-1',
            threadId: 'thread-1',
            role: 'user',
            content: 'test',
            timestamp: DateTime(2025, 6, 15),
          ),
        ],
      );

      final map = thread.toMap();
      expect(map.containsKey('messages'), false);
    });

    test('formattedTimestamp uses updatedAt', () {
      final thread = ConversationThread(
        id: 'thread-1',
        title: 'Test',
        createdAt: DateTime(2020, 1, 1),
        updatedAt: DateTime.now().subtract(const Duration(minutes: 10)),
      );

      expect(thread.formattedTimestamp, '10m ago');
    });

    test('formattedTimestamp returns Just now for < 1 minute', () {
      final thread = ConversationThread(
        id: 'thread-1',
        title: 'Test',
        createdAt: DateTime(2020, 1, 1),
        updatedAt: DateTime.now().subtract(const Duration(seconds: 20)),
      );

      expect(thread.formattedTimestamp, 'Just now');
    });

    test('formattedTimestamp returns DD/MM/YYYY for >= 7 days', () {
      final thread = ConversationThread(
        id: 'thread-1',
        title: 'Test',
        createdAt: DateTime(2020, 1, 1),
        updatedAt: DateTime(2025, 3, 9),
      );

      expect(thread.formattedTimestamp, '09/03/2025');
    });

    test('copyWith preserves unchanged fields', () {
      final createdAt = DateTime(2025, 6, 15, 10, 0, 0);
      final updatedAt = DateTime(2025, 6, 15, 11, 0, 0);
      final original = ConversationThread(
        id: 'thread-1',
        title: 'Original Title',
        createdAt: createdAt,
        updatedAt: updatedAt,
        userId: 'user-1',
        userName: 'Test User',
        userPhotoURL: 'https://example.com/photo.jpg',
        messageCount: 5,
        lastMessagePreview: 'Hello',
      );

      final copied = original.copyWith(title: 'New Title');

      expect(copied.id, 'thread-1');
      expect(copied.title, 'New Title');
      expect(copied.createdAt, createdAt);
      expect(copied.updatedAt, updatedAt);
      expect(copied.userId, 'user-1');
      expect(copied.userName, 'Test User');
      expect(copied.userPhotoURL, 'https://example.com/photo.jpg');
      expect(copied.messageCount, 5);
      expect(copied.lastMessagePreview, 'Hello');
    });

    test('copyWith overrides specified fields', () {
      final original = ConversationThread(
        id: 'thread-1',
        title: 'Original',
        createdAt: DateTime(2025, 6, 15),
        updatedAt: DateTime(2025, 6, 15),
        messageCount: 0,
        lastMessagePreview: '',
      );

      final newUpdatedAt = DateTime(2025, 6, 16);
      final copied = original.copyWith(
        title: 'Updated',
        updatedAt: newUpdatedAt,
        messageCount: 3,
        lastMessagePreview: 'Latest message',
      );

      expect(copied.id, 'thread-1');
      expect(copied.title, 'Updated');
      expect(copied.updatedAt, newUpdatedAt);
      expect(copied.messageCount, 3);
      expect(copied.lastMessagePreview, 'Latest message');
    });
  });

  group('OpenAIService.buildMessagesPayload', () {
    test('with empty history returns [system, user]', () {
      final result = OpenAIService.buildMessagesPayload('What is Islam?');

      expect(result.length, 2);
      expect(result[0]['role'], 'system');
      expect(result[1]['role'], 'user');
      expect(result[1]['content'], 'What is Islam?');
    });

    test('with 5 messages returns [system, msg1..msg5, user]', () {
      final history = List.generate(
        5,
        (i) => ChatMessage(
          id: 'msg-$i',
          threadId: 'thread-1',
          role: i.isEven ? 'user' : 'assistant',
          content: 'Message $i',
          timestamp: DateTime(2025, 6, 15, 10, i),
        ),
      );

      final result = OpenAIService.buildMessagesPayload(
        'New question?',
        conversationHistory: history,
      );

      expect(result.length, 7);
      expect(result[0]['role'], 'system');
      expect(result[1]['role'], 'user');
      expect(result[1]['content'], 'Message 0');
      expect(result[2]['role'], 'assistant');
      expect(result[2]['content'], 'Message 1');
      expect(result[3]['role'], 'user');
      expect(result[3]['content'], 'Message 2');
      expect(result[4]['role'], 'assistant');
      expect(result[4]['content'], 'Message 3');
      expect(result[5]['role'], 'user');
      expect(result[5]['content'], 'Message 4');
      expect(result[6]['role'], 'user');
      expect(result[6]['content'], 'New question?');
    });

    test('with 25 messages truncates to most recent 20 plus system and user', () {
      final history = List.generate(
        25,
        (i) => ChatMessage(
          id: 'msg-$i',
          threadId: 'thread-1',
          role: i.isEven ? 'user' : 'assistant',
          content: 'Message $i',
          timestamp: DateTime(2025, 6, 15, 10, i),
        ),
      );

      final result = OpenAIService.buildMessagesPayload(
        'Final question?',
        conversationHistory: history,
      );

      expect(result.length, 22);
      expect(result[0]['role'], 'system');
      expect(result[1]['content'], 'Message 5');
      expect(result[20]['content'], 'Message 24');
      expect(result[21]['role'], 'user');
      expect(result[21]['content'], 'Final question?');
    });
  });
}
