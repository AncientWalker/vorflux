import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:vorflux/models/conversation_thread.dart';
import 'package:vorflux/services/database_service.dart';
import 'package:vorflux/services/firebase_config.dart';
import 'package:vorflux/services/firestore_service.dart';

class BookmarkProvider extends ChangeNotifier {
  List<ConversationThread> _threads = [];
  bool _isLoading = false;
  final Set<String> _bookmarkedIds = {};
  final Set<String> _inFlightIds = {};
  StreamSubscription? _subscription;

  List<ConversationThread> get entries => _threads;
  bool get isLoading => _isLoading;
  bool get isEmpty => _threads.isEmpty;

  bool isBookmarked(String threadId) => _bookmarkedIds.contains(threadId);

  void listenToBookmarks(String userId) {
    if (!FirebaseConfig.isAvailable) {
      _loadFromLocalDb();
      return;
    }

    _subscription?.cancel();
    _isLoading = true;
    Future.microtask(notifyListeners);

    _subscription = FirestoreService.getUserBookmarks(userId).listen(
      (threads) {
        _threads = threads;
        _bookmarkedIds
          ..clear()
          ..addAll(threads.map((thread) => thread.id));
        _isLoading = false;
        notifyListeners();
      },
      onError: (e) {
        debugPrint('Error loading bookmarks: $e');
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  Future<void> _loadFromLocalDb() async {
    _isLoading = true;
    Future.microtask(notifyListeners);

    try {
      _threads = await DatabaseService.getAllBookmarks();
      _bookmarkedIds
        ..clear()
        ..addAll(_threads.map((thread) => thread.id));
    } catch (e) {
      debugPrint('Error loading local bookmarks: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> toggleBookmark({
    required ConversationThread thread,
    required String userId,
  }) async {
    if (_inFlightIds.contains(thread.id)) return false;

    _inFlightIds.add(thread.id);
    try {
      if (isBookmarked(thread.id)) {
        return await _removeBookmark(threadId: thread.id, userId: userId);
      }
      return await _addBookmark(thread: thread, userId: userId);
    } finally {
      _inFlightIds.remove(thread.id);
    }
  }

  Future<ConversationThread?> getFullThread(String threadId) async {
    try {
      if (!FirebaseConfig.isAvailable) {
        return await DatabaseService.getThread(threadId) ??
            _findThread(threadId);
      }
      return await FirestoreService.getThread(threadId) ?? _findThread(threadId);
    } catch (e) {
      debugPrint('Error loading bookmarked thread: $e');
      return _findThread(threadId);
    }
  }

  ConversationThread? _findThread(String threadId) {
    for (final thread in _threads) {
      if (thread.id == threadId) return thread;
    }
    return null;
  }

  Future<bool> _addBookmark({
    required ConversationThread thread,
    required String userId,
  }) async {
    try {
      if (!FirebaseConfig.isAvailable) {
        await DatabaseService.insertBookmark(thread);
        _threads.removeWhere((entry) => entry.id == thread.id);
        _threads.insert(0, thread);
      } else {
        await FirestoreService.addBookmark(userId: userId, thread: thread);
      }
      _bookmarkedIds.add(thread.id);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error adding bookmark: $e');
      return false;
    }
  }

  Future<bool> _removeBookmark({
    required String threadId,
    required String userId,
  }) async {
    try {
      if (!FirebaseConfig.isAvailable) {
        await DatabaseService.removeBookmark(threadId);
        _threads.removeWhere((entry) => entry.id == threadId);
      } else {
        await FirestoreService.removeBookmark(userId: userId, threadId: threadId);
      }
      _bookmarkedIds.remove(threadId);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error removing bookmark: $e');
      return false;
    }
  }

  void stopListening() {
    _subscription?.cancel();
    _subscription = null;
    _threads = [];
    _bookmarkedIds.clear();
    _inFlightIds.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
