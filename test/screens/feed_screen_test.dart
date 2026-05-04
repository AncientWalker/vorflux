import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:vorflux/providers/feed_provider.dart';
import 'package:vorflux/screens/feed_screen.dart';

import '../helpers/test_factories.dart';

Widget _buildTestApp(FeedProvider provider) {
  return MaterialApp(
    home: ChangeNotifierProvider<FeedProvider>.value(
      value: provider,
      child: const Scaffold(body: FeedScreen()),
    ),
  );
}

void main() {
  group('FeedScreen widget tests', () {
    late FeedProvider provider;

    final testEntries = [
      makeThread(id: '1', title: 'What does Islam say about fasting?', lastMessagePreview: 'Fasting in Ramadan is one of the five pillars.', userName: 'Ahmed'),
      makeThread(id: '2', title: 'How to be patient?', lastMessagePreview: 'Patience (sabr) is a virtue praised in the Quran.', userName: 'Fatima'),
      makeThread(id: '3', title: 'What is zakat?', lastMessagePreview: 'Zakat is obligatory charity.', userName: 'Omar'),
    ];

    setUp(() {
      provider = FeedProvider();
      provider.entriesForTesting = List.of(testEntries);
    });

    testWidgets('displays search field when entries exist', (tester) async {
      await tester.pumpWidget(_buildTestApp(provider));
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Search the community feed...'), findsOneWidget);
    });

    testWidgets('displays all entries initially', (tester) async {
      await tester.pumpWidget(_buildTestApp(provider));
      await tester.pumpAndSettle();

      expect(find.text('What does Islam say about fasting?'), findsOneWidget);
      expect(find.text('How to be patient?'), findsOneWidget);
      expect(find.text('What is zakat?'), findsOneWidget);
    });

    testWidgets('typing in search field filters displayed entries', (tester) async {
      await tester.pumpWidget(_buildTestApp(provider));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'zakat');
      await tester.pumpAndSettle();

      expect(find.text('What is zakat?'), findsOneWidget);
      expect(find.text('What does Islam say about fasting?'), findsNothing);
      expect(find.text('How to be patient?'), findsNothing);
    });

    testWidgets('can filter by author name', (tester) async {
      await tester.pumpWidget(_buildTestApp(provider));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'fatima');
      await tester.pumpAndSettle();

      expect(find.text('How to be patient?'), findsOneWidget);
      expect(find.text('What is zakat?'), findsNothing);
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

      await tester.enterText(find.byType(TextField), 'zakat');
      await tester.pumpAndSettle();
      expect(find.text('How to be patient?'), findsNothing);

      await tester.tap(find.byIcon(Icons.clear));
      await tester.pumpAndSettle();

      expect(find.text('What does Islam say about fasting?'), findsOneWidget);
      expect(find.text('How to be patient?'), findsOneWidget);
      expect(find.text('What is zakat?'), findsOneWidget);
    });

    testWidgets('shows empty state when no entries', (tester) async {
      provider.entriesForTesting = [];
      await tester.pumpWidget(_buildTestApp(provider));
      await tester.pumpAndSettle();

      expect(find.text('No Conversations Yet'), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
    });

    testWidgets('header shows correct entry count', (tester) async {
      await tester.pumpWidget(_buildTestApp(provider));
      await tester.pumpAndSettle();

      expect(find.text('3'), findsOneWidget);
    });
  });
}
