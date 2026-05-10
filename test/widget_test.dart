// Vorflux widget tests.
// Tests run on host (Flutter for linux/desktop) with sqflite FFI bootstrapped
// via flutter_test_config.dart.
//
// Architecture constraint: AuthProvider constructs AuthService.authStateChanges
// eagerly when FirebaseConfig.isAvailable==true, which calls FirebaseAuth.instance
// and throws [core/no-app] in tests (Firebase has not been initialised by
// Firebase.initializeApp()). We therefore test:
//   a) All QAEntry model logic  — no Flutter / no Firebase needed.
//   b) AskScreen in demo mode  — FirebaseConfig.isAvailable is false so
//      AuthProvider never touches FirebaseAuth.
//
// Widget tests that require a full Firebase mock are out of scope until a
// firebase_mock package is added. See known-issues.md for details.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:vorflux/models/qa_entry.dart';
import 'package:vorflux/providers/auth_provider.dart';
import 'package:vorflux/providers/history_provider.dart';
import 'package:vorflux/providers/feed_provider.dart';
import 'package:vorflux/screens/ask_screen.dart';
import 'package:vorflux/services/firebase_config.dart';
import 'package:vorflux/theme/app_theme.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Wraps [child] in the providers AskScreen needs, with Firebase disabled
/// so AuthProvider never calls FirebaseAuth.instance.
Widget _wrapAskScreen() {
  // Ensure demo mode before building the widget tree
  FirebaseConfig.setAvailable(false);

  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => AuthProvider()),
      ChangeNotifierProvider(create: (_) => HistoryProvider()),
      ChangeNotifierProvider(create: (_) => FeedProvider()),
    ],
    child: MaterialApp(
      theme: AppTheme.lightTheme,
      home: const Scaffold(body: AskScreen()),
    ),
  );
}

// ---------------------------------------------------------------------------
// QAEntry model tests
// ---------------------------------------------------------------------------

void main() {
  group('QAEntry model', () {
    test('toMap / fromMap round-trip preserves all fields', () {
      final entry = QAEntry(
        id: 'test-id-1',
        question: 'What is Tawhid?',
        answer: '**Tawhid** is the concept of monotheism in Islam.',
        timestamp: DateTime(2025, 12, 15, 10, 30),
        askedBy: 'Yusuf Al-Farouqi',
        userPhotoURL: 'https://example.com/photo.jpg',
        userId: 'user-001',
      );

      final map = entry.toMap();
      final restored = QAEntry.fromMap(map);

      expect(restored.id, entry.id);
      expect(restored.question, entry.question);
      expect(restored.answer, entry.answer);
      expect(restored.timestamp, entry.timestamp);
      expect(restored.askedBy, entry.askedBy);
      expect(restored.userPhotoURL, entry.userPhotoURL);
      expect(restored.userId, entry.userId);
    });

    test('answerPreview truncates at 120 characters and appends ellipsis', () {
      final longAnswer = 'A' * 200;
      final entry = QAEntry(
        id: 'id-2',
        question: 'Q',
        answer: longAnswer,
        timestamp: DateTime.now(),
      );
      expect(entry.answerPreview.length, 123); // 120 chars + '...'
      expect(entry.answerPreview.endsWith('...'), isTrue);
    });

    test('answerPreview returns full text when answer is under 120 characters', () {
      const shortAnswer = 'Brief Islamic guidance.';
      final entry = QAEntry(
        id: 'id-3',
        question: 'Q',
        answer: shortAnswer,
        timestamp: DateTime.now(),
      );
      expect(entry.answerPreview, shortAnswer);
    });

    test('answerPreview returns full text when answer is exactly 120 characters', () {
      final exactAnswer = 'X' * 120;
      final entry = QAEntry(
        id: 'id-3b',
        question: 'Q',
        answer: exactAnswer,
        timestamp: DateTime.now(),
      );
      expect(entry.answerPreview, exactAnswer);
      expect(entry.answerPreview.endsWith('...'), isFalse);
    });

    test('formattedTimestamp → "Just now" for very recent entries', () {
      final entry = QAEntry(
        id: 'id-4',
        question: 'Q',
        answer: 'A',
        timestamp: DateTime.now(),
      );
      expect(entry.formattedTimestamp, 'Just now');
    });

    test('formattedTimestamp → "Xm ago" for entries under 1 hour old', () {
      final entry = QAEntry(
        id: 'id-5',
        question: 'Q',
        answer: 'A',
        timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
      );
      expect(entry.formattedTimestamp, '30m ago');
    });

    test('formattedTimestamp → "Xh ago" for entries under 1 day old', () {
      final entry = QAEntry(
        id: 'id-6',
        question: 'Q',
        answer: 'A',
        timestamp: DateTime.now().subtract(const Duration(hours: 5)),
      );
      expect(entry.formattedTimestamp, '5h ago');
    });

    test('formattedTimestamp → "Xd ago" for entries under 7 days old', () {
      final entry = QAEntry(
        id: 'id-7',
        question: 'Q',
        answer: 'A',
        timestamp: DateTime.now().subtract(const Duration(days: 3)),
      );
      expect(entry.formattedTimestamp, '3d ago');
    });

    test('formattedTimestamp → "d/m/yyyy" for entries 7+ days old', () {
      final ts = DateTime(2025, 6, 1);
      final entry = QAEntry(
        id: 'id-8',
        question: 'Q',
        answer: 'A',
        timestamp: ts,
      );
      expect(entry.formattedTimestamp, '1/6/2025');
    });

    test('QAEntry handles null optional fields gracefully', () {
      final entry = QAEntry(
        id: 'id-9',
        question: 'Q',
        answer: 'A',
        timestamp: DateTime.now(),
      );
      expect(entry.askedBy, isNull);
      expect(entry.userPhotoURL, isNull);
      expect(entry.userId, isNull);
    });

    test('toMap includes all 7 expected keys', () {
      final entry = QAEntry(
        id: 'id-10',
        question: 'Q',
        answer: 'A',
        timestamp: DateTime.now(),
        askedBy: 'Aisha',
        userPhotoURL: '',
        userId: 'u-1',
      );
      final map = entry.toMap();
      expect(map.keys.toSet(), containsAll([
        'id', 'question', 'answer', 'timestamp', 'askedBy', 'userPhotoURL', 'userId',
      ]));
    });
  });

  // ---------------------------------------------------------------------------
  // AskScreen widget tests — demo mode only (no Firebase)
  // ---------------------------------------------------------------------------

  group('AskScreen widget (demo mode)', () {
    setUp(() => FirebaseConfig.setAvailable(false));
    tearDown(() => FirebaseConfig.setAvailable(false));

    testWidgets('renders welcome banner with personalised greeting', (tester) async {
      await tester.pumpWidget(_wrapAskScreen());
      await tester.pump();

      // In demo mode AuthProvider.displayName == 'Demo User', first name == 'Demo'
      expect(find.textContaining('Assalamu Alaikum'), findsOneWidget);
      expect(find.textContaining('Demo'), findsWidgets);
    });

    testWidgets('renders all three suggestion chips', (tester) async {
      await tester.pumpWidget(_wrapAskScreen());
      await tester.pump();

      expect(find.textContaining('patience'), findsWidgets);
      expect(find.textContaining('prayer'), findsWidgets);
      expect(find.textContaining('parents'), findsWidgets);
    });

    testWidgets('input field shows placeholder hint text', (tester) async {
      await tester.pumpWidget(_wrapAskScreen());
      await tester.pump();

      expect(find.text('Ask a question about Islam...'), findsOneWidget);
    });

    testWidgets('send button is present and enabled', (tester) async {
      await tester.pumpWidget(_wrapAskScreen());
      await tester.pump();

      // The send button renders an Icon — look for send_rounded icon
      expect(find.byIcon(Icons.send_rounded), findsOneWidget);
    });

    testWidgets('mosque icon prefix is present in input field', (tester) async {
      await tester.pumpWidget(_wrapAskScreen());
      await tester.pump();

      expect(find.byIcon(Icons.mosque_outlined), findsOneWidget);
    });

    testWidgets('empty question tap does not crash the app', (tester) async {
      await tester.pumpWidget(_wrapAskScreen());
      await tester.pump();

      // Tap send without typing anything
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pump();

      // App should still show the welcome banner — no crash
      expect(find.textContaining('Assalamu Alaikum'), findsOneWidget);
    });
  });
}
