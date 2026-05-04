import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vorflux/models/qa_entry.dart';
import 'package:vorflux/providers/searchable_entries_mixin.dart';

import '../helpers/test_factories.dart';

/// Minimal concrete implementation to exercise the mixin in isolation.
class _TestProvider extends ChangeNotifier with SearchableEntriesMixin {
  List<QAEntry> _entries = [];

  @override
  List<QAEntry> get entries => _entries;

  @override
  @visibleForTesting
  set entriesForTesting(List<QAEntry> entries) {
    _entries = entries;
  }

  @override
  List<String> searchableFields(QAEntry entry) => [
        entry.question,
        entry.answer,
        entry.askedBy ?? '',
      ];
}

void main() {
  group('SearchableEntriesMixin', () {
    late _TestProvider provider;

    final testEntries = [
      makeEntry(id: '1', question: 'Alpha question', answer: 'Bravo answer', askedBy: 'Charlie'),
      makeEntry(id: '2', question: 'Delta question', answer: 'Echo answer', askedBy: 'Foxtrot'),
      makeEntry(id: '3', question: 'Golf question', answer: 'Hotel answer', askedBy: null),
    ];

    setUp(() {
      provider = _TestProvider();
      provider.entriesForTesting = List.of(testEntries);
    });

    test('initial searchQuery is empty', () {
      expect(provider.searchQuery, '');
    });

    test('filteredEntries returns all when query is empty', () {
      expect(provider.filteredEntries.length, 3);
    });

    test('setSearchQuery notifies listeners', () {
      int count = 0;
      provider.addListener(() => count++);
      provider.setSearchQuery('alpha');
      expect(count, 1);
    });

    test('filters by field returned by searchableFields', () {
      provider.setSearchQuery('charlie');
      final result = provider.filteredEntries;
      expect(result.length, 1);
      expect(result[0].id, '1');
    });

    test('clearSearch resets query without notifying', () {
      provider.setSearchQuery('something');
      int count = 0;
      provider.addListener(() => count++);
      provider.clearSearch();
      expect(provider.searchQuery, '');
      expect(count, 0); // clearSearch does not notify
    });

    test('trims leading/trailing whitespace', () {
      provider.setSearchQuery('  alpha  ');
      expect(provider.filteredEntries.length, 1);
    });

    test('whitespace-only query returns all entries', () {
      provider.setSearchQuery('   ');
      expect(provider.filteredEntries.length, 3);
    });

    test('null field values do not cause errors', () {
      provider.setSearchQuery('golf');
      final result = provider.filteredEntries;
      expect(result.length, 1);
      expect(result[0].id, '3');
    });
  });
}
