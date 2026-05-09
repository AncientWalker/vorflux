import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vorflux/models/conversation_thread.dart';
import 'package:vorflux/providers/searchable_entries_mixin.dart';
import 'package:vorflux/services/database_service.dart';
import 'package:vorflux/services/firebase_config.dart';
import 'package:vorflux/services/firestore_service.dart';

class FeedProvider extends ChangeNotifier with SearchableEntriesMixin {
  List<ConversationThread> _threads = [];
  bool _isLoading = false;
  bool _hasError = false;
  StreamSubscription? _subscription;

  DateTime? _lastSeenTimestamp;
  String? _currentUserId;

  /// Key used in SharedPreferences to store the last-seen feed timestamp.
  @visibleForTesting
  static String lastSeenKey(String userId) => 'feed_last_seen_$userId';

  List<ConversationThread> get threads => _threads;

  @override
  List<ConversationThread> get entries => _threads;

  bool get isLoading => _isLoading;
  bool get hasError => _hasError;
  bool get isEmpty => _threads.isEmpty;

  /// Number of feed threads from other users that were updated after the
  /// user last viewed the feed tab. Capped at display level in the UI (9+).
  ///
  /// When the user has never visited the feed (no stored timestamp), all
  /// threads from other users are considered unread.
  int get unreadCount {
    final cutoff = _lastSeenTimestamp ?? DateTime.fromMillisecondsSinceEpoch(0);
    return _threads.where((t) {
      // Only count threads from other users as unread.
      if (_currentUserId != null && t.userId == _currentUserId) return false;
      return t.updatedAt.isAfter(cutoff);
    }).length;
  }

  @override
  @visibleForTesting
  set entriesForTesting(List<ConversationThread> entries) {
    _threads = entries;
  }

  /// Allows tests to set the last-seen timestamp directly.
  @visibleForTesting
  void setLastSeenForTesting(DateTime? timestamp) {
    _lastSeenTimestamp = timestamp;
  }

  /// Allows tests to set the current user ID directly.
  @visibleForTesting
  void setCurrentUserIdForTesting(String? userId) {
    _currentUserId = userId;
  }

  @override
  List<String> searchableFields(ConversationThread entry) => [
        entry.title,
        entry.lastMessagePreview,
        entry.userName ?? '',
      ];

  void listenToFeed({String? userId}) {
    _currentUserId = userId ?? _currentUserId;

    if (!FirebaseConfig.isAvailable) {
      Future.microtask(() async {
        await _loadLastSeen();
        await _loadFromLocalDb();
      });
      return;
    }

    Future.microtask(() async {
      _subscription?.cancel();
      _isLoading = true;
      _hasError = false;
      notifyListeners();

      await _loadLastSeen();

      _subscription = FirestoreService.getAllThreads().listen(
        (threads) {
          _threads = threads;
          _isLoading = false;
          _hasError = false;
          notifyListeners();
        },
        onError: (e) {
          _hasError = true;
          _isLoading = false;
          debugPrint('Error loading feed: $e');
          notifyListeners();
        },
      );
    });
  }

  Future<void> _loadLastSeen() async {
    if (_currentUserId == null || _currentUserId!.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final millis = prefs.getInt(lastSeenKey(_currentUserId!));
      if (millis != null) {
        _lastSeenTimestamp = DateTime.fromMillisecondsSinceEpoch(millis);
      }
    } catch (e) {
      debugPrint('Error loading feed last-seen timestamp: $e');
    }
  }

  /// Marks the feed as seen by saving the current time. Call this when the
  /// user navigates to the Feed tab.
  Future<void> markFeedAsSeen() async {
    _lastSeenTimestamp = DateTime.now();
    notifyListeners();

    if (_currentUserId == null || _currentUserId!.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(
        lastSeenKey(_currentUserId!),
        _lastSeenTimestamp!.millisecondsSinceEpoch,
      );
    } catch (e) {
      debugPrint('Error saving feed last-seen timestamp: $e');
    }
  }

  Future<void> _loadFromLocalDb() async {
    _isLoading = true;
    _hasError = false;
    notifyListeners();

    try {
      _threads = await DatabaseService.getAllThreads();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading local feed: $e');
      _hasError = true;
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<ConversationThread> getFullThread(String threadId) async {
    final threadMeta = _threads.firstWhere((t) => t.id == threadId);

    if (FirebaseConfig.isAvailable) {
      final messages = await FirestoreService.getThreadMessages(threadId);
      return threadMeta.copyWith(messages: messages);
    }

    final fullThread = await DatabaseService.getThread(threadId);
    return fullThread ?? threadMeta;
  }

  Future<void> refreshFeed() async {
    if (!FirebaseConfig.isAvailable) {
      await _loadFromLocalDb();
      return;
    }

    listenToFeed();
  }

  void stopListening() {
    _subscription?.cancel();
    _subscription = null;
    _threads = [];
    clearSearch();
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
