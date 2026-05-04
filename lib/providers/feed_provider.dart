import 'dart:async';

import 'package:flutter/foundation.dart';
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

  List<ConversationThread> get threads => _threads;

  @override
  List<ConversationThread> get entries => _threads;

  bool get isLoading => _isLoading;
  bool get hasError => _hasError;
  bool get isEmpty => _threads.isEmpty;

  @override
  @visibleForTesting
  set entriesForTesting(List<ConversationThread> entries) {
    _threads = entries;
  }

  @override
  List<String> searchableFields(ConversationThread entry) => [
        entry.title,
        entry.lastMessagePreview,
        entry.userName ?? '',
      ];

  void listenToFeed() {
    if (!FirebaseConfig.isAvailable) {
      Future.microtask(_loadFromLocalDb);
      return;
    }

    Future.microtask(() {
      _subscription?.cancel();
      _isLoading = true;
      _hasError = false;
      notifyListeners();

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
