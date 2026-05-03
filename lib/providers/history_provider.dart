import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:vorflux/models/qa_entry.dart';
import 'package:vorflux/services/firebase_config.dart';
import 'package:vorflux/services/firestore_service.dart';
import 'package:vorflux/services/database_service.dart';

class HistoryProvider extends ChangeNotifier {
  List<QAEntry> _entries = [];
  bool _isLoading = false;
  StreamSubscription? _subscription;
  String? _currentUserId;
  String _searchQuery = '';

  List<QAEntry> get entries => _entries;
  bool get isLoading => _isLoading;
  bool get isEmpty => _entries.isEmpty;
  String get searchQuery => _searchQuery;

  @visibleForTesting
  set entriesForTesting(List<QAEntry> entries) {
    _entries = entries;
  }

  /// Returns entries filtered by the current search query.
  /// Matches against question and answer text (case-insensitive).
  List<QAEntry> get filteredEntries {
    if (_searchQuery.isEmpty) return _entries;
    final query = _searchQuery.toLowerCase();
    return _entries.where((entry) {
      return entry.question.toLowerCase().contains(query) ||
          entry.answer.toLowerCase().contains(query);
    }).toList();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void listenToUserQuestions(String userId) {
    _currentUserId = userId;

    if (!FirebaseConfig.isAvailable) {
      // Offline mode: load from SQLite
      _loadFromLocalDb();
      return;
    }

    // Firestore mode
    _subscription?.cancel();
    _isLoading = true;
    notifyListeners();

    _subscription = FirestoreService.getUserQuestions(userId).listen(
      (entries) {
        _entries = entries;
        _isLoading = false;
        notifyListeners();
      },
      onError: (e) {
        debugPrint('Error loading history: $e');
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  Future<void> _loadFromLocalDb() async {
    _isLoading = true;
    notifyListeners();

    try {
      _entries = await DatabaseService.getAllEntries();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading local history: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<QAEntry?> addEntry({
    required String question,
    required String answer,
    required String userId,
    required String userName,
    required String userPhotoURL,
  }) async {
    if (!FirebaseConfig.isAvailable) {
      // Offline mode: save to SQLite
      final entry = QAEntry(
        id: const Uuid().v4(),
        question: question,
        answer: answer,
        timestamp: DateTime.now(),
        askedBy: userName,
        userPhotoURL: userPhotoURL,
        userId: userId,
      );
      try {
        await DatabaseService.insertEntry(entry);
        _entries.insert(0, entry);
        notifyListeners();
        return entry;
      } catch (e) {
        debugPrint('Error saving to local DB: $e');
        return null;
      }
    }

    // Firestore mode
    try {
      final docId = await FirestoreService.saveQuestion(
        userId: userId,
        userName: userName,
        userPhotoURL: userPhotoURL,
        questionText: question,
        answerText: answer,
      );
      return QAEntry(
        id: docId,
        question: question,
        answer: answer,
        timestamp: DateTime.now(),
        askedBy: userName,
        userPhotoURL: userPhotoURL,
        userId: userId,
      );
    } catch (e) {
      debugPrint('Error saving question: $e');
      return null;
    }
  }

  Future<void> deleteEntry(String id) async {
    if (!FirebaseConfig.isAvailable) {
      try {
        await DatabaseService.deleteEntry(id);
        _entries.removeWhere((e) => e.id == id);
        notifyListeners();
      } catch (e) {
        debugPrint('Error deleting from local DB: $e');
      }
      return;
    }

    try {
      await FirestoreService.deleteQuestion(id);
    } catch (e) {
      debugPrint('Error deleting entry: $e');
    }
  }

  Future<void> clearHistory() async {
    if (!FirebaseConfig.isAvailable) {
      try {
        await DatabaseService.clearAll();
        _entries = [];
        notifyListeners();
      } catch (e) {
        debugPrint('Error clearing local DB: $e');
      }
      return;
    }

    if (_currentUserId == null) return;
    try {
      await FirestoreService.deleteAllUserQuestions(_currentUserId!);
    } catch (e) {
      debugPrint('Error clearing history: $e');
    }
  }

  void stopListening() {
    _subscription?.cancel();
    _subscription = null;
    _entries = [];
    _currentUserId = null;
    _searchQuery = '';
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
