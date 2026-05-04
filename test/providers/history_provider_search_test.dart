import 'package:flutter_test/flutter_test.dart';
import 'package:vorflux/providers/history_provider.dart';

import '../helpers/test_factories.dart';

void main() {
  group('HistoryProvider search/filter', () {
    late HistoryProvider provider;

    setUp(() {
      provider = HistoryProvider();
    });

    test('initial searchQuery is empty', () {
      expect(provider.searchQuery, '');
    });

    test('setSearchQuery updates the query and notifies listeners', () {
      int notifyCount = 0;
      provider.addListener(() => notifyCount++);

      provider.setSearchQuery('fasting');
      expect(provider.searchQuery, 'fasting');
      expect(notifyCount, 1);
    });

    test('setSearchQuery to empty string clears the query', () {
      provider.setSearchQuery('fasting');
      provider.setSearchQuery('');
      expect(provider.searchQuery, '');
    });

    test('filteredEntries returns all entries when query is empty', () {
      expect(provider.filteredEntries, isEmpty);
      expect(provider.searchQuery, '');
    });

    test('filteredEntries returns empty list when no entries and query is set', () {
      provider.setSearchQuery('fasting');
      expect(provider.filteredEntries, isEmpty);
    });

    test('stopListening clears searchQuery', () {
      provider.setSearchQuery('patience');
      provider.stopListening();
      expect(provider.searchQuery, '');
    });
  });

  group('HistoryProvider filteredEntries on real provider', () {
    late HistoryProvider provider;

    final testEntries = [
      makeEntry(id: '1', question: 'What does Islam say about fasting?', answer: 'Fasting in Ramadan is one of the five pillars of Islam.'),
      makeEntry(id: '2', question: 'How to be patient?', answer: 'Patience (sabr) is a virtue highly praised in the Quran.'),
      makeEntry(id: '3', question: 'What is zakat?', answer: 'Zakat is the obligatory charity in Islam, one of the five pillars.'),
      makeEntry(id: '4', question: 'Tell me about prayer', answer: 'Salah is performed five times daily and includes fasting-related supplications during Ramadan.'),
    ];

    setUp(() {
      provider = HistoryProvider();
      provider.entriesForTesting = List.of(testEntries);
    });

    test('empty query returns all entries', () {
      expect(provider.filteredEntries.length, 4);
    });

    test('filters by question keyword', () {
      provider.setSearchQuery('fasting');
      final result = provider.filteredEntries;
      // entry 1 has "fasting" in question, entry 4 has "fasting-related" in answer
      expect(result.length, 2);
      expect(result.map((e) => e.id).toSet(), {'1', '4'});
    });

    test('filters by answer keyword', () {
      provider.setSearchQuery('pillars');
      final result = provider.filteredEntries;
      expect(result.length, 2);
      expect(result.map((e) => e.id).toSet(), {'1', '3'});
    });

    test('search is case-insensitive', () {
      provider.setSearchQuery('FASTING');
      final result = provider.filteredEntries;
      expect(result.length, 2);
      expect(result.map((e) => e.id).toSet(), {'1', '4'});
    });

    test('partial word match works', () {
      provider.setSearchQuery('pat');
      final result = provider.filteredEntries;
      expect(result.length, 1);
      expect(result[0].id, '2');
    });

    test('no match returns empty list', () {
      provider.setSearchQuery('xyz123');
      expect(provider.filteredEntries, isEmpty);
    });

    test('matches across question and answer fields', () {
      provider.setSearchQuery('ramadan');
      final result = provider.filteredEntries;
      expect(result.length, 2);
      expect(result.map((e) => e.id).toSet(), {'1', '4'});
    });

    test('single character query matches expected entries', () {
      provider.setSearchQuery('z');
      final result = provider.filteredEntries;
      // 'z' appears in entry 3 (question: "zakat", answer: "Zakat")
      expect(result.length, 1);
      expect(result[0].id, '3');
    });

    test('whitespace in query is handled', () {
      provider.setSearchQuery('five pillars');
      final result = provider.filteredEntries;
      expect(result.length, 2); // entries 1 and 3 both mention "five pillars"
    });

    test('clearing query restores all entries', () {
      provider.setSearchQuery('fasting');
      expect(provider.filteredEntries.length, 2);
      provider.setSearchQuery('');
      expect(provider.filteredEntries.length, 4);
    });

    test('filteredEntries does not modify original entries list', () {
      provider.setSearchQuery('fasting');
      expect(provider.filteredEntries.length, 2);
      expect(provider.entries.length, 4); // original list unchanged
    });

    test('leading/trailing whitespace in query is trimmed', () {
      provider.setSearchQuery('  fasting  ');
      final result = provider.filteredEntries;
      expect(result.length, 2);
      expect(result.map((e) => e.id).toSet(), {'1', '4'});
    });

    test('whitespace-only query returns all entries', () {
      provider.setSearchQuery('   ');
      expect(provider.filteredEntries.length, 4);
    });
  });
}
