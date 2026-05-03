import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:vorflux/providers/auth_provider.dart';
import 'package:vorflux/providers/bookmark_provider.dart';
import 'package:vorflux/providers/history_provider.dart';
import 'package:vorflux/screens/history_screen.dart';
import 'package:vorflux/services/firebase_config.dart';

import '../helpers/test_factories.dart';

Widget _buildTestApp(HistoryProvider historyProvider) {
  FirebaseConfig.setAvailable(false);
  return MaterialApp(
    home: MultiProvider(
      providers: [
        ChangeNotifierProvider<HistoryProvider>.value(value: historyProvider),
        ChangeNotifierProvider<BookmarkProvider>(create: (_) => BookmarkProvider()),
        ChangeNotifierProvider<AuthProvider>(create: (_) => AuthProvider()),
      ],
      child: const Scaffold(body: HistoryScreen()),
    ),
  );
}

void main() {
  group('HistoryScreen widget tests', () {
    late HistoryProvider provider;

    final testEntries = [
      makeThread(
        id: '1',
        title: 'What does Islam say about fasting?',
        lastMessagePreview: 'Fasting in Ramadan is one of the five pillars of Islam.',
      ),
      makeThread(
        id: '2',
        title: 'How to be patient?',
        lastMessagePreview:
            'Patience (sabr) is a virtue highly praised in the Quran.',
      ),
      makeThread(
        id: '3',
        title: 'What is zakat?',
        lastMessagePreview: 'Zakat is the obligatory charity in Islam.',
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

    testWidgets('typing in search field filters displayed entries', (tester) async {
      await tester.pumpWidget(_buildTestApp(provider));
      await tester.pumpAndSettle();

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

      expect(find.text('3 threads'), findsOneWidget);
    });
  });
}
