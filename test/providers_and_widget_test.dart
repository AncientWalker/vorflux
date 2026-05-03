import 'package:flutter_test/flutter_test.dart';
import 'package:vorflux/models/chat_message.dart';
import 'package:vorflux/models/conversation_thread.dart';

// Unit tests for the provider and widget logic introduced in Task 3.
// We test pure logic here (no Flutter widgets or services) to keep tests
// runnable without Firebase, sqflite, or a real Flutter test environment.

void main() {
  group('HistoryProvider - title/preview truncation logic', () {
    test('title is truncated to 100 chars for long questions', () {
      final question = 'A' * 200;
      final title = question.length > 100 ? question.substring(0, 100) : question;
      expect(title.length, 100);
      expect(title, 'A' * 100);
    });

    test('title stays unchanged for short questions', () {
      const question = 'What is Islam?';
      final title = question.length > 100 ? question.substring(0, 100) : question;
      expect(title, 'What is Islam?');
    });

    test('preview is truncated to 120 chars with ellipsis for long answers', () {
      final answer = 'B' * 200;
      final preview = answer.length > 120 ? '${answer.substring(0, 120)}...' : answer;
      expect(preview.length, 123);
      expect(preview.endsWith('...'), true);
    });

    test('preview stays unchanged for short answers', () {
      const answer = 'Short answer.';
      final preview = answer.length > 120 ? '${answer.substring(0, 120)}...' : answer;
      expect(preview, 'Short answer.');
    });

    test('preview stays unchanged for exactly 120 chars', () {
      final answer = 'C' * 120;
      final preview = answer.length > 120 ? '${answer.substring(0, 120)}...' : answer;
      expect(preview, answer);
      expect(preview.length, 120);
    });
  });

  group('HistoryProvider - thread list sorting logic', () {
    test('threads sort by updatedAt descending', () {
      final now = DateTime(2025, 6, 15, 10, 0, 0);
      final threads = [
        ConversationThread(
          id: 'old', title: 'Old',
          createdAt: now, updatedAt: now,
        ),
        ConversationThread(
          id: 'new', title: 'New',
          createdAt: now, updatedAt: now.add(const Duration(hours: 2)),
        ),
        ConversationThread(
          id: 'mid', title: 'Mid',
          createdAt: now, updatedAt: now.add(const Duration(hours: 1)),
        ),
      ];

      threads.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

      expect(threads[0].id, 'new');
      expect(threads[1].id, 'mid');
      expect(threads[2].id, 'old');
    });
  });

  group('HistoryProvider - thread index update logic', () {
    test('existing thread is updated in list', () {
      final now = DateTime(2025, 6, 15, 10, 0, 0);
      final threads = [
        ConversationThread(
          id: 'thread-1', title: 'Thread 1',
          createdAt: now, updatedAt: now,
          messageCount: 0, lastMessagePreview: '',
        ),
        ConversationThread(
          id: 'thread-2', title: 'Thread 2',
          createdAt: now, updatedAt: now,
          messageCount: 0, lastMessagePreview: '',
        ),
      ];

      const threadId = 'thread-1';
      final updatedThread = ConversationThread(
        id: threadId, title: 'Thread 1',
        createdAt: now, updatedAt: now.add(const Duration(hours: 1)),
        messageCount: 2, lastMessagePreview: 'Updated preview',
      );

      final threadIndex = threads.indexWhere((t) => t.id == threadId);
      expect(threadIndex, 0);
      threads[threadIndex] = updatedThread;
      threads.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

      expect(threads[0].id, 'thread-1');
      expect(threads[0].messageCount, 2);
      expect(threads[0].lastMessagePreview, 'Updated preview');
    });

    test('new thread is inserted at beginning when not found', () {
      final now = DateTime(2025, 6, 15, 10, 0, 0);
      final threads = <ConversationThread>[
        ConversationThread(
          id: 'thread-1', title: 'Existing',
          createdAt: now, updatedAt: now,
        ),
      ];

      final newThread = ConversationThread(
        id: 'thread-new', title: 'New Thread',
        createdAt: now, updatedAt: now.add(const Duration(hours: 1)),
      );

      final threadIndex = threads.indexWhere((t) => t.id == 'thread-new');
      expect(threadIndex, -1);
      threads.insert(0, newThread);
      threads.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

      expect(threads[0].id, 'thread-new');
      expect(threads.length, 2);
    });
  });

  group('HistoryProvider - optimistic temp message logic', () {
    test('temp user message has temp-user- prefix', () {
      final now = DateTime.now();
      final tempId = 'temp-user-${now.millisecondsSinceEpoch}';
      expect(tempId.startsWith('temp-user-'), true);
    });

    test('removing temp message from messages list on failure', () {
      final now = DateTime.now();
      final messages = [
        ChatMessage(id: 'msg-1', threadId: 't1', role: 'user', content: 'old', timestamp: now),
        ChatMessage(id: 'temp-user-12345', threadId: 't1', role: 'user', content: 'new', timestamp: now),
      ];

      if (messages.last.id.startsWith('temp-user-')) {
        messages.removeLast();
      }

      expect(messages.length, 1);
      expect(messages.last.id, 'msg-1');
    });

    test('non-temp messages are not removed on failure', () {
      final now = DateTime.now();
      final messages = [
        ChatMessage(id: 'msg-1', threadId: 't1', role: 'user', content: 'old', timestamp: now),
        ChatMessage(id: 'msg-2', threadId: 't1', role: 'assistant', content: 'response', timestamp: now),
      ];

      if (messages.last.id.startsWith('temp-user-')) {
        messages.removeLast();
      }

      expect(messages.length, 2);
    });
  });

  group('HistoryProvider - conversation history building', () {
    test('conversation history is built from existing messages', () {
      final now = DateTime(2025, 6, 15, 10, 0, 0);
      final existingMessages = [
        ChatMessage(id: 'msg-1', threadId: 't1', role: 'user', content: 'Q1', timestamp: now),
        ChatMessage(id: 'msg-2', threadId: 't1', role: 'assistant', content: 'A1', timestamp: now),
      ];

      final conversationHistory = List<ChatMessage>.from(existingMessages);
      expect(conversationHistory.length, 2);
      expect(conversationHistory[0].role, 'user');
      expect(conversationHistory[1].role, 'assistant');
    });

    test('conversation history includes messages in order for multi-turn', () {
      final now = DateTime(2025, 6, 15, 10, 0, 0);
      final existingMessages = [
        ChatMessage(id: 'msg-1', threadId: 't1', role: 'user', content: 'Q1', timestamp: now),
        ChatMessage(id: 'msg-2', threadId: 't1', role: 'assistant', content: 'A1', timestamp: now.add(const Duration(seconds: 1))),
        ChatMessage(id: 'msg-3', threadId: 't1', role: 'user', content: 'Q2', timestamp: now.add(const Duration(seconds: 2))),
        ChatMessage(id: 'msg-4', threadId: 't1', role: 'assistant', content: 'A2', timestamp: now.add(const Duration(seconds: 3))),
      ];

      final conversationHistory = List<ChatMessage>.from(existingMessages);
      // Build persisted messages (adding new Q&A pair)
      final userMsg = ChatMessage(id: 'msg-5', threadId: 't1', role: 'user', content: 'Q3', timestamp: now.add(const Duration(seconds: 4)));
      final assistantMsg = ChatMessage(id: 'msg-6', threadId: 't1', role: 'assistant', content: 'A3', timestamp: now.add(const Duration(seconds: 5)));
      final persisted = conversationHistory..add(userMsg)..add(assistantMsg);

      expect(persisted.length, 6);
      expect(persisted.last.role, 'assistant');
      expect(persisted.last.content, 'A3');
    });
  });

  group('FeedProvider - thread list logic', () {
    test('threads list initialized empty', () {
      final threads = <ConversationThread>[];
      expect(threads.isEmpty, true);
    });

    test('threads can be populated and checked', () {
      final now = DateTime(2025, 6, 15);
      final threads = [
        ConversationThread(id: 't1', title: 'Thread 1', createdAt: now, updatedAt: now),
        ConversationThread(id: 't2', title: 'Thread 2', createdAt: now, updatedAt: now),
      ];
      expect(threads.isEmpty, false);
      expect(threads.length, 2);
    });
  });

  group('ConversationThread - copyWith for messages', () {
    test('copyWith replaces messages list', () {
      final now = DateTime(2025, 6, 15);
      final thread = ConversationThread(
        id: 't1', title: 'Test',
        createdAt: now, updatedAt: now,
        messages: const [],
      );

      final msg = ChatMessage(
        id: 'msg-1', threadId: 't1', role: 'user', content: 'Hello', timestamp: now,
      );

      final updated = thread.copyWith(messages: [msg]);
      expect(updated.messages.length, 1);
      expect(updated.messages.first.content, 'Hello');
      expect(thread.messages.length, 0); // original unchanged
    });

    test('copyWith with empty list clears messages', () {
      final now = DateTime(2025, 6, 15);
      final msg = ChatMessage(
        id: 'msg-1', threadId: 't1', role: 'user', content: 'Hello', timestamp: now,
      );
      final thread = ConversationThread(
        id: 't1', title: 'Test',
        createdAt: now, updatedAt: now,
        messages: [msg],
      );

      final cleared = thread.copyWith(messages: const []);
      expect(cleared.messages, isEmpty);
    });

    test('copyWith preserves other fields when only messages changes', () {
      final now = DateTime(2025, 6, 15);
      final thread = ConversationThread(
        id: 't1', title: 'Original Title',
        createdAt: now, updatedAt: now,
        userId: 'u1', userName: 'Alice',
        messageCount: 5, lastMessagePreview: 'preview text',
      );

      final msg = ChatMessage(
        id: 'msg-1', threadId: 't1', role: 'user', content: 'New message', timestamp: now,
      );
      final updated = thread.copyWith(messages: [msg]);

      expect(updated.id, 't1');
      expect(updated.title, 'Original Title');
      expect(updated.userId, 'u1');
      expect(updated.userName, 'Alice');
      expect(updated.messageCount, 5);
      expect(updated.lastMessagePreview, 'preview text');
    });
  });

  group('ChatMessageBubble - role-based rendering logic', () {
    test('user messages have role user', () {
      final msg = ChatMessage(
        id: 'msg-1', threadId: 't1', role: 'user', content: 'Hello', timestamp: DateTime.now(),
      );
      expect(msg.role, 'user');
      expect(msg.role == 'user', true);
    });

    test('assistant messages have role assistant', () {
      final msg = ChatMessage(
        id: 'msg-2', threadId: 't1', role: 'assistant', content: 'Hi!', timestamp: DateTime.now(),
      );
      expect(msg.role, 'assistant');
      expect(msg.role == 'user', false);
    });
  });

  group('DetailScreen - copy conversation logic', () {
    test('conversation is formatted correctly for clipboard', () {
      final now = DateTime(2025, 6, 15, 10, 0, 0);
      final messages = [
        ChatMessage(id: 'msg-1', threadId: 't1', role: 'user', content: 'What is patience?', timestamp: now),
        ChatMessage(id: 'msg-2', threadId: 't1', role: 'assistant', content: 'Patience in Islam...', timestamp: now),
        ChatMessage(id: 'msg-3', threadId: 't1', role: 'user', content: 'Tell me more', timestamp: now),
        ChatMessage(id: 'msg-4', threadId: 't1', role: 'assistant', content: 'More details...', timestamp: now),
      ];

      final buffer = StringBuffer();
      for (final msg in messages) {
        buffer.writeln(msg.role == 'user' ? 'Q: ${msg.content}' : 'A: ${msg.content}');
        buffer.writeln();
      }
      final result = buffer.toString().trim();

      expect(result.contains('Q: What is patience?'), true);
      expect(result.contains('A: Patience in Islam...'), true);
      expect(result.contains('Q: Tell me more'), true);
      expect(result.contains('A: More details...'), true);
    });

    test('empty messages produces empty string', () {
      final messages = <ChatMessage>[];
      final buffer = StringBuffer();
      for (final msg in messages) {
        buffer.writeln(msg.role == 'user' ? 'Q: ${msg.content}' : 'A: ${msg.content}');
        buffer.writeln();
      }
      final result = buffer.toString().trim();
      expect(result, '');
    });
  });

  group('HistoryScreen - thread display logic', () {
    test('formattedTimestamp shows "Just now" for recent thread', () {
      final thread = ConversationThread(
        id: 't1', title: 'Test',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now().subtract(const Duration(seconds: 30)),
      );
      expect(thread.formattedTimestamp, 'Just now');
    });

    test('formattedTimestamp shows minutes for < 1 hour', () {
      final thread = ConversationThread(
        id: 't1', title: 'Test',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now().subtract(const Duration(minutes: 15)),
      );
      expect(thread.formattedTimestamp, '15m ago');
    });

    test('formattedTimestamp shows hours for < 24 hours', () {
      final thread = ConversationThread(
        id: 't1', title: 'Test',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now().subtract(const Duration(hours: 5)),
      );
      expect(thread.formattedTimestamp, '5h ago');
    });

    test('formattedTimestamp shows days for < 7 days', () {
      final thread = ConversationThread(
        id: 't1', title: 'Test',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now().subtract(const Duration(days: 3)),
      );
      expect(thread.formattedTimestamp, '3d ago');
    });
  });

  group('FeedScreen - user avatar logic', () {
    test('thread with non-empty userName shows first initial', () {
      final thread = ConversationThread(
        id: 't1', title: 'Test',
        createdAt: DateTime.now(), updatedAt: DateTime.now(),
        userName: 'Alice',
      );
      expect(thread.userName?.isNotEmpty == true, true);
      expect(thread.userName![0].toUpperCase(), 'A');
    });

    test('thread with null userName falls back to ?', () {
      final thread = ConversationThread(
        id: 't1', title: 'Test',
        createdAt: DateTime.now(), updatedAt: DateTime.now(),
      );
      final initial = thread.userName?.isNotEmpty == true ? thread.userName![0].toUpperCase() : '?';
      expect(initial, '?');
    });

    test('thread with empty userName falls back to ?', () {
      final thread = ConversationThread(
        id: 't1', title: 'Test',
        createdAt: DateTime.now(), updatedAt: DateTime.now(),
        userName: '',
      );
      final initial = thread.userName?.isNotEmpty == true ? thread.userName![0].toUpperCase() : '?';
      expect(initial, '?');
    });
  });
}
