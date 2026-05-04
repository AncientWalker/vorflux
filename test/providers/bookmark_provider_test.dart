import 'package:flutter_test/flutter_test.dart';
import 'package:vorflux/models/conversation_thread.dart';
import 'package:vorflux/providers/bookmark_provider.dart';

ConversationThread makeThread({
  String id = 'thread-1',
  String title = 'What is patience?',
  String preview = 'Patience is praised in the Quran.',
}) {
  return ConversationThread(
    id: id,
    title: title,
    createdAt: DateTime(2024, 1, 1, 10),
    updatedAt: DateTime(2024, 1, 1, 10, 1),
    userName: 'Tester',
    userId: 'user-1',
    messageCount: 2,
    lastMessagePreview: preview,
  );
}

void main() {
  group('BookmarkProvider', () {
    late BookmarkProvider provider;

    setUp(() {
      provider = BookmarkProvider();
    });

    tearDown(() {
      provider.dispose();
    });

    test('initial state has empty entries', () {
      expect(provider.entries, isEmpty);
      expect(provider.isEmpty, isTrue);
      expect(provider.isLoading, isFalse);
    });

    test('isBookmarked returns false for unknown thread', () {
      expect(provider.isBookmarked('non-existent-id'), isFalse);
    });

    test('stopListening clears all state and notifies listeners', () {
      var notified = false;
      provider.addListener(() => notified = true);

      provider.stopListening();

      expect(provider.entries, isEmpty);
      expect(provider.isEmpty, isTrue);
      expect(notified, isTrue);
    });

    test('stopListening can be called multiple times safely', () {
      provider.stopListening();
      provider.stopListening();
      expect(provider.entries, isEmpty);
    });

    test('toggleBookmark returns bool indicating success or failure', () async {
      final thread = makeThread();
      final result = await provider.toggleBookmark(
        thread: thread,
        userId: 'test-user',
      );
      expect(result, isA<bool>());
    });
  });

  group('ConversationThread bookmark metadata', () {
    test('toMap includes bookmark-relevant fields', () {
      final thread = makeThread();
      final map = thread.toMap();

      expect(map['id'], 'thread-1');
      expect(map['title'], 'What is patience?');
      expect(map['userName'], 'Tester');
      expect(map['userId'], 'user-1');
      expect(map['messageCount'], 2);
      expect(map['lastMessagePreview'], 'Patience is praised in the Quran.');
    });

    test('fromMap roundtrips correctly', () {
      final original = makeThread(id: 'thread-2', title: 'What is salah?');
      final restored = ConversationThread.fromMap(original.toMap());

      expect(restored.id, original.id);
      expect(restored.title, original.title);
      expect(restored.userName, original.userName);
      expect(restored.userId, original.userId);
      expect(restored.messageCount, original.messageCount);
      expect(restored.lastMessagePreview, original.lastMessagePreview);
    });

    test('copyWith can strip messages for bookmark snapshots', () {
      final original = makeThread();
      final snapshot = original.copyWith(messages: const []);
      expect(snapshot.messages, isEmpty);
      expect(snapshot.id, original.id);
      expect(snapshot.title, original.title);
    });
  });
}
