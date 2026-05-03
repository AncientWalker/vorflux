import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:vorflux/models/qa_entry.dart';
import 'package:vorflux/services/firestore_service.dart';

class FeedProvider extends ChangeNotifier {
  List<QAEntry> _entries = [];
  bool _isLoading = false;
  bool _hasError = false;
  StreamSubscription? _subscription;

  List<QAEntry> get entries => _entries;
  bool get isLoading => _isLoading;
  bool get hasError => _hasError;
  bool get isEmpty => _entries.isEmpty;

  void listenToFeed() {
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

  Future<void> refreshFeed() async {
    listenToFeed();
  }

  void stopListening() {
    _subscription?.cancel();
    _subscription = null;
    _entries = [];
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
