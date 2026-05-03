import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:vorflux/models/qa_entry.dart';
import 'package:vorflux/services/firebase_config.dart';
import 'package:vorflux/services/firestore_service.dart';
import 'package:vorflux/services/database_service.dart';

class FeedProvider extends ChangeNotifier {
  List<QAEntry> _entries = [];
  bool _isLoading = false;
  bool _hasError = false;
  StreamSubscription? _subscription;
  String _searchQuery = '';

  List<QAEntry> get entries => _entries;
  bool get isLoading => _isLoading;
  bool get hasError => _hasError;
  bool get isEmpty => _entries.isEmpty;
  String get searchQuery => _searchQuery;

  @visibleForTesting
  set entriesForTesting(List<QAEntry> entries) {
    _entries = entries;
  }

  /// Returns entries filtered by the current search query.
  /// Matches against question, answer, and author name (case-insensitive).
  List<QAEntry> get filteredEntries {
    if (_searchQuery.isEmpty) return _entries;
    final query = _searchQuery.toLowerCase();
    return _entries.where((entry) {
      return entry.question.toLowerCase().contains(query) ||
          entry.answer.toLowerCase().contains(query) ||
          (entry.askedBy?.toLowerCase().contains(query) ?? false);
    }).toList();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

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
    _searchQuery = '';
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
