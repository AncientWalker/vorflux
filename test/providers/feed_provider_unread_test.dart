import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vorflux/providers/feed_provider.dart';

import '../helpers/test_factories.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FeedProvider unread count', () {
    late FeedProvider provider;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      provider = FeedProvider();
    });

    test('unreadCount treats all threads as unread when lastSeen is null (first launch)', () {
      provider.setCurrentUserIdForTesting('user-me');
      provider.entriesForTesting = [
        makeThread(id: '1', updatedAt: DateTime(2025, 6, 1), userId: 'user-other-1'),
        makeThread(id: '2', updatedAt: DateTime(2025, 5, 1), userId: 'user-other-2'),
      ];
      // lastSeen is null by default — all threads from others are unread
      expect(provider.unreadCount, 2);
    });

    test('unreadCount is 0 when lastSeen is null and threads list is empty', () {
      provider.setCurrentUserIdForTesting('user-me');
      provider.entriesForTesting = [];
      expect(provider.unreadCount, 0);
    });

    test('unreadCount excludes own threads even when lastSeen is null', () {
      provider.setCurrentUserIdForTesting('user-me');
      provider.entriesForTesting = [
        makeThread(id: '1', updatedAt: DateTime(2025, 6, 1), userId: 'user-me'),
        makeThread(id: '2', updatedAt: DateTime(2025, 6, 1), userId: 'user-other'),
      ];
      // Only thread 2 counts — thread 1 is from current user
      expect(provider.unreadCount, 1);
    });

    test('unreadCount counts threads updated after lastSeen', () {
      final lastSeen = DateTime(2025, 6, 1, 12, 0);
      provider.setLastSeenForTesting(lastSeen);
      provider.setCurrentUserIdForTesting('user-me');
      provider.entriesForTesting = [
        makeThread(
            id: '1',
            updatedAt: DateTime(2025, 6, 1, 13, 0),
            userId: 'user-other'),
        makeThread(
            id: '2',
            updatedAt: DateTime(2025, 6, 1, 11, 0),
            userId: 'user-other'),
        makeThread(
            id: '3',
            updatedAt: DateTime(2025, 6, 1, 14, 0),
            userId: 'user-other'),
      ];
      // Threads 1 and 3 are after lastSeen
      expect(provider.unreadCount, 2);
    });

    test('unreadCount excludes threads from the current user', () {
      final lastSeen = DateTime(2025, 6, 1, 12, 0);
      provider.setLastSeenForTesting(lastSeen);
      provider.setCurrentUserIdForTesting('user-me');
      provider.entriesForTesting = [
        makeThread(
            id: '1',
            updatedAt: DateTime(2025, 6, 1, 13, 0),
            userId: 'user-me'),
        makeThread(
            id: '2',
            updatedAt: DateTime(2025, 6, 1, 14, 0),
            userId: 'user-other'),
      ];
      // Only thread 2 counts (thread 1 is from current user)
      expect(provider.unreadCount, 1);
    });

    test('unreadCount is 0 when all threads are before lastSeen', () {
      final lastSeen = DateTime(2025, 6, 2);
      provider.setLastSeenForTesting(lastSeen);
      provider.setCurrentUserIdForTesting('user-me');
      provider.entriesForTesting = [
        makeThread(
            id: '1',
            updatedAt: DateTime(2025, 6, 1, 10, 0),
            userId: 'user-other'),
        makeThread(
            id: '2',
            updatedAt: DateTime(2025, 6, 1, 11, 0),
            userId: 'user-other'),
      ];
      expect(provider.unreadCount, 0);
    });

    test('unreadCount is 0 when threads list is empty', () {
      provider.setLastSeenForTesting(DateTime(2025, 6, 1));
      provider.setCurrentUserIdForTesting('user-me');
      provider.entriesForTesting = [];
      expect(provider.unreadCount, 0);
    });

    test('unreadCount includes threads with null userId (not current user)', () {
      final lastSeen = DateTime(2025, 6, 1, 12, 0);
      provider.setLastSeenForTesting(lastSeen);
      provider.setCurrentUserIdForTesting('user-me');
      provider.entriesForTesting = [
        makeThread(
            id: '1',
            updatedAt: DateTime(2025, 6, 1, 13, 0),
            userId: null),
      ];
      // Thread with null userId is not the current user, so it counts
      expect(provider.unreadCount, 1);
    });

    test('unreadCount handles thread updated at exact lastSeen time', () {
      final lastSeen = DateTime(2025, 6, 1, 12, 0);
      provider.setLastSeenForTesting(lastSeen);
      provider.setCurrentUserIdForTesting('user-me');
      provider.entriesForTesting = [
        makeThread(
            id: '1',
            updatedAt: DateTime(2025, 6, 1, 12, 0),
            userId: 'user-other'),
      ];
      // isAfter is strict — exact same time does not count
      expect(provider.unreadCount, 0);
    });

    test('unreadCount works when currentUserId is null', () {
      final lastSeen = DateTime(2025, 6, 1, 12, 0);
      provider.setLastSeenForTesting(lastSeen);
      // currentUserId is null — all threads from others count
      provider.entriesForTesting = [
        makeThread(
            id: '1',
            updatedAt: DateTime(2025, 6, 1, 13, 0),
            userId: 'user-a'),
        makeThread(
            id: '2',
            updatedAt: DateTime(2025, 6, 1, 14, 0),
            userId: 'user-b'),
      ];
      expect(provider.unreadCount, 2);
    });

    test('markFeedAsSeen resets unreadCount to 0', () async {
      provider.setLastSeenForTesting(DateTime(2025, 6, 1, 12, 0));
      provider.setCurrentUserIdForTesting('user-me');
      provider.entriesForTesting = [
        makeThread(
            id: '1',
            updatedAt: DateTime(2025, 6, 1, 13, 0),
            userId: 'user-other'),
        makeThread(
            id: '2',
            updatedAt: DateTime(2025, 6, 1, 14, 0),
            userId: 'user-other'),
      ];
      expect(provider.unreadCount, 2);

      await provider.markFeedAsSeen();

      // After marking as seen, all existing threads should be "read"
      expect(provider.unreadCount, 0);
    });

    test('markFeedAsSeen notifies listeners', () async {
      var notifyCount = 0;
      provider.addListener(() => notifyCount++);

      await provider.markFeedAsSeen();

      expect(notifyCount, 1);
    });

    test('lastSeenKey is scoped per user', () {
      expect(FeedProvider.lastSeenKey('user-123'), 'feed_last_seen_user-123');
      expect(FeedProvider.lastSeenKey('user-456'), 'feed_last_seen_user-456');
    });

    test('large unread count works correctly (for 9+ display)', () {
      final lastSeen = DateTime(2025, 6, 1, 12, 0);
      provider.setLastSeenForTesting(lastSeen);
      provider.setCurrentUserIdForTesting('user-me');
      provider.entriesForTesting = List.generate(
        15,
        (i) => makeThread(
          id: 'thread-$i',
          updatedAt: DateTime(2025, 6, 1, 13, i),
          userId: 'user-other-$i',
        ),
      );
      expect(provider.unreadCount, 15);
      // UI would display "9+" but the raw count is 15
    });

    test('stopListening clears lastSeenTimestamp and currentUserId', () {
      provider.setLastSeenForTesting(DateTime(2025, 6, 1));
      provider.setCurrentUserIdForTesting('user-me');
      provider.entriesForTesting = [
        makeThread(
            id: '1',
            updatedAt: DateTime(2025, 6, 1, 13, 0),
            userId: 'user-other'),
      ];
      expect(provider.unreadCount, 1);

      provider.stopListening();

      // After stopListening, threads are cleared so unreadCount is 0
      expect(provider.unreadCount, 0);

      // Simulate a new user signing in with new threads — lastSeen should
      // be null (cleared), so all threads from others count as unread.
      provider.setCurrentUserIdForTesting('user-new');
      provider.entriesForTesting = [
        makeThread(
            id: '2',
            updatedAt: DateTime(2025, 1, 1),
            userId: 'user-someone'),
      ];
      expect(provider.unreadCount, 1);
    });

    test('markFeedAsSeen uses latest thread time when ahead of device clock',
        () async {
      // Simulate a thread whose updatedAt is far in the future (server clock
      // ahead of device). markFeedAsSeen should use that timestamp so the
      // badge clears for all visible items.
      final futureTime = DateTime.now().add(const Duration(hours: 1));
      provider.setCurrentUserIdForTesting('user-me');
      provider.entriesForTesting = [
        makeThread(id: '1', updatedAt: futureTime, userId: 'user-other'),
      ];
      expect(provider.unreadCount, 1);

      await provider.markFeedAsSeen();

      // The future-timestamped thread should now be considered "read"
      expect(provider.unreadCount, 0);
    });
  });
}
