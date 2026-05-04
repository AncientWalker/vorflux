import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:vorflux/models/qa_entry.dart';
import 'package:vorflux/providers/searchable_entries_mixin.dart';
import 'package:vorflux/services/firebase_config.dart';
import 'package:vorflux/services/firestore_service.dart';
import 'package:vorflux/services/database_service.dart';

class FeedProvider extends ChangeNotifier with SearchableEntriesMixin {
  List<QAEntry> _entries = [];
  bool _isLoading = false;
  bool _hasError = false;
  StreamSubscription? _subscription;

  @override
  List<QAEntry> get entries => _entries;
  bool get isLoading => _isLoading;
  bool get hasError => _hasError;
  bool get isEmpty => _entries.isEmpty;

  @override
  @visibleForTesting
  set entriesForTesting(List<QAEntry> entries) {
    _entries = entries;
  }

  /// Matches against question, answer, and author name (case-insensitive).
  @override
  List<String> searchableFields(QAEntry entry) => [
        entry.question,
        entry.answer,
        entry.askedBy ?? '',
      ];

  void listenToFeed() {
    if (!FirebaseConfig.isAvailable) {
      // Offline mode: show all local entries as the "feed"
      _loadFromLocalDb();
      return;
    }

    // Firestore mode
    _subscription?.cancel();
    _isLoading = true;
    _hasError = false;
    notifyListeners();

    _subscription = FirestoreService.getAllQuestions().listen(
      (entries) {
        _entries = entries;
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
  }

  Future<void> _loadFromLocalDb() async {
    _isLoading = true;
    _hasError = false;
    notifyListeners();

    try {
      _entries = await DatabaseService.getAllEntries();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading local feed: $e');
      _hasError = true;
      _isLoading = false;
      notifyListeners();
    }
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
    _entries = [];
    clearSearch();
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
