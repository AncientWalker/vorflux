import 'package:flutter/foundation.dart';
import 'package:vorflux/models/qa_entry.dart';

/// Mixin that provides search/filter functionality for providers managing
/// lists of [QAEntry]. The provider must mix in [ChangeNotifier].
///
/// Subclasses specify which fields to search by overriding
/// [searchableFields]. The mixin provides [searchQuery],
/// [setSearchQuery], [filteredEntries], and [clearSearch].
mixin SearchableEntriesMixin on ChangeNotifier {
  String _searchQuery = '';

  /// The current search query (untrimmed value stored by [setSearchQuery]).
  String get searchQuery => _searchQuery;

  /// The backing list of entries to search within.
  /// Concrete providers must override this to return their entry list.
  List<QAEntry> get entries;

  /// Returns the list of string values to match against for a given entry.
  /// Override in concrete providers to control which fields are searchable.
  ///
  /// Example — search question, answer, and author:
  /// ```dart
  /// @override
  /// List<String> searchableFields(QAEntry entry) => [
  ///   entry.question,
  ///   entry.answer,
  ///   entry.askedBy ?? '',
  /// ];
  /// ```
  List<String> searchableFields(QAEntry entry);

  /// Returns entries filtered by the current search query.
  /// Matches against the fields returned by [searchableFields]
  /// (case-insensitive, trimmed).
  List<QAEntry> get filteredEntries {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) return entries;
    return entries.where((entry) {
      return searchableFields(entry)
          .any((field) => field.toLowerCase().contains(query));
    }).toList();
  }

  /// Updates the search query and calls [notifyListeners].
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  /// Resets the search query to empty.
  void clearSearch() {
    _searchQuery = '';
  }

  @visibleForTesting
  set entriesForTesting(List<QAEntry> entries);
}
