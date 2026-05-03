import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:vorflux/models/qa_entry.dart';
import 'package:vorflux/services/database_service.dart';

class HistoryProvider extends ChangeNotifier {
  List<QAEntry> _entries = [];
  bool _isLoading = false;

  List<QAEntry> get entries => _entries;
  bool get isLoading => _isLoading;
  bool get isEmpty => _entries.isEmpty;

  Future<void> loadHistory() async {
    _isLoading = true;
    notifyListeners();

    try {
      _entries = await DatabaseService.getAllEntries();
    } catch (e) {
      debugPrint('Error loading history: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<QAEntry> addEntry(String question, String answer) async {
    final entry = QAEntry(
      id: const Uuid().v4(),
      question: question,
      answer: answer,
      timestamp: DateTime.now(),
    );

    await DatabaseService.insertEntry(entry);
    _entries.insert(0, entry);
    notifyListeners();
    return entry;
  }

  Future<void> deleteEntry(String id) async {
    await DatabaseService.deleteEntry(id);
    _entries.removeWhere((e) => e.id == id);
    notifyListeners();
  }

  Future<void> clearHistory() async {
    await DatabaseService.clearAll();
    _entries.clear();
    notifyListeners();
  }
}
