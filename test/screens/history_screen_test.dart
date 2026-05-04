import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:vorflux/providers/history_provider.dart';
import 'package:vorflux/screens/history_screen.dart';

import '../helpers/test_factories.dart';

/// Wraps [HistoryScreen] with a [ChangeNotifierProvider] for widget tests.
Widget _buildTestApp(HistoryProvider provider) {
  return MaterialApp(
    home: ChangeNotifierProvider<HistoryProvider>.value(
      value: provider,
      child: const Scaffold(body: HistoryScreen()),
    ),
  );
}

void main() {
  group('HistoryScreen widget tests', () {
    late HistoryProvider provider;

    final testEntries = [
      makeEntry(
        id: '1',
        question: 'What does Islam say about fasting?',
        answer: 'Fasting in Ramadan is one of the five pillars of Islam.',
      ),
      makeEntry(
        id: '2',
        question: 'How to be patient?',
        answer: 'Patience (sabr) is a virtue highly praised in the Quran.',
      ),
      makeEntry(
        id: '3',
        question: 'What is zakat?',
        answer: 'Zakat is the obligatory charity in Islam.',
      ),
    ];

    setUp(() {
      provider = HistoryProvider();
      provider.entriesForTesting = List.of(testEntries);
    });

    testWidgets('displays search field when entries exist', (tester) async {
      await tester.pumpWidget(_buildTestApp(provider));
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Search your questions...'), findsOneWidget);
    });

    testWidgets('displays all entries initially', (tester) async {
      await tester.pumpWidget(_buildTestApp(provider));
      await tester.pumpAndSettle();

      expect(find.text('What does Islam say about fasting?'), findsOneWidget);
      expect(find.text('How to be patient?'), findsOneWidget);
      expect(find.text('What is zakat?'), findsOneWidget);
    });

    testWidgets('typing in search field filters displayed entries',
        (tester) async {
      await tester.pumpWidget(_buildTestApp(provider));
      await tester.pumpAndSettle();

      // Type 'zakat' into search
      await tester.enterText(find.byType(TextField), 'zakat');
      await tester.pumpAndSettle();

      expect(find.text('What is zakat?'), findsOneWidget);
      expect(find.text('What does Islam say about fasting?'), findsNothing);
      expect(find.text('How to be patient?'), findsNothing);
    });

    testWidgets('shows no results state for unmatched query', (tester) async {
      await tester.pumpWidget(_buildTestApp(provider));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'xyznonexistent');
      await tester.pumpAndSettle();

      expect(find.text('No results found'), findsOneWidget);
      expect(find.text('Try a different keyword'), findsOneWidget);
    });

    testWidgets('tapping clear icon restores all entries', (tester) async {
      await tester.pumpWidget(_buildTestApp(provider));
      await tester.pumpAndSettle();

      // Type a query that filters
      await tester.enterText(find.byType(TextField), 'zakat');
      await tester.pumpAndSettle();
      expect(find.text('How to be patient?'), findsNothing);

      // Tap the clear button
      await tester.tap(find.byIcon(Icons.clear));
      await tester.pumpAndSettle();

      // All entries should be visible again
      expect(find.text('What does Islam say about fasting?'), findsOneWidget);
      expect(find.text('How to be patient?'), findsOneWidget);
      expect(find.text('What is zakat?'), findsOneWidget);
    });

    testWidgets('shows empty state when no entries', (tester) async {
      provider.entriesForTesting = [];
      await tester.pumpWidget(_buildTestApp(provider));
      await tester.pumpAndSettle();

      expect(find.text('No History Yet'), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
    });

    testWidgets('header shows correct entry count', (tester) async {
      await tester.pumpWidget(_buildTestApp(provider));
      await tester.pumpAndSettle();

      expect(find.text('3 saved'), findsOneWidget);
    });
  });
}
