import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vorflux/models/conversation_thread.dart';
import 'package:vorflux/providers/searchable_entries_mixin.dart';

import '../helpers/test_factories.dart';

class _TestProvider extends ChangeNotifier with SearchableEntriesMixin {
  List<ConversationThread> _entries = [];

  @override
  List<ConversationThread> get entries => _entries;

  @override
  @visibleForTesting
  set entriesForTesting(List<ConversationThread> entries) {
    _entries = entries;
  }

  @override
  List<String> searchableFields(ConversationThread entry) => [
        entry.title,
        entry.lastMessagePreview,
        entry.userName ?? '',
      ];
}

void main() {
  group('SearchableEntriesMixin', () {
    late _TestProvider provider;

    final testEntries = [
      makeThread(id: '1', title: 'Alpha question', lastMessagePreview: 'Bravo answer', userName: 'Charlie'),
      makeThread(id: '2', title: 'Delta question', lastMessagePreview: 'Echo answer', userName: 'Foxtrot'),
      makeThread(id: '3', title: 'Golf question', lastMessagePreview: 'Hotel answer', userName: null),
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
      var count = 0;
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
      var count = 0;
      provider.addListener(() => count++);
      provider.clearSearch();
      expect(provider.searchQuery, '');
      expect(count, 0);
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
