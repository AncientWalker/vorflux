import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:vorflux/models/qa_entry.dart';
import 'package:vorflux/services/firestore_service.dart';

class HistoryProvider extends ChangeNotifier {
  List<QAEntry> _entries = [];
  bool _isLoading = false;
  StreamSubscription? _subscription;
  String? _currentUserId;

  List<QAEntry> get entries => _entries;
  bool get isLoading => _isLoading;
  bool get isEmpty => _entries.isEmpty;

  void listenToUserQuestions(String userId) {
    _subscription?.cancel();
    _currentUserId = userId;
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

  Future<QAEntry?> addEntry({
    required String question,
    required String answer,
    required String userId,
    required String userName,
    required String userPhotoURL,
  }) async {
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
    try {
      await FirestoreService.deleteQuestion(id);
    } catch (e) {
      debugPrint('Error deleting entry: $e');
    }
  }

  Future<void> clearHistory() async {
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
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
