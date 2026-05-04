import 'package:flutter/foundation.dart';
import 'package:vorflux/models/conversation_thread.dart';

/// Shared search/filter support for providers that expose conversation threads.
///
/// Concrete providers must expose their backing list via [entries] and define
/// which thread fields are searchable via [searchableFields].
mixin SearchableEntriesMixin on ChangeNotifier {
  String _searchQuery = '';

  String get searchQuery => _searchQuery;

  List<ConversationThread> get entries;

  List<String> searchableFields(ConversationThread entry);

  List<ConversationThread> get filteredEntries {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) return entries;

    return entries.where((entry) {
      return searchableFields(entry)
          .any((field) => field.toLowerCase().contains(query));
    }).toList();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void clearSearch() {
    _searchQuery = '';
  }

  @visibleForTesting
  set entriesForTesting(List<ConversationThread> entries);
}
