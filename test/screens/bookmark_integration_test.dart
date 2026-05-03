import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:vorflux/models/conversation_thread.dart';
import 'package:vorflux/providers/auth_provider.dart';
import 'package:vorflux/providers/bookmark_provider.dart';
import 'package:vorflux/providers/feed_provider.dart';
import 'package:vorflux/providers/history_provider.dart';
import 'package:vorflux/screens/detail_screen.dart';
import 'package:vorflux/services/firebase_config.dart';

Widget buildTestWidget({
  required Widget child,
  BookmarkProvider? bookmarkProvider,
}) {
  FirebaseConfig.setAvailable(false);
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<BookmarkProvider>.value(
        value: bookmarkProvider ?? BookmarkProvider(),
      ),
      ChangeNotifierProvider<AuthProvider>(create: (_) => AuthProvider()),
      ChangeNotifierProvider<HistoryProvider>(create: (_) => HistoryProvider()),
      ChangeNotifierProvider<FeedProvider>(create: (_) => FeedProvider()),
    ],
    child: MaterialApp(home: child),
  );
}

ConversationThread makeThread({
  String id = 'thread-1',
  String title = 'What is the meaning of Taqwa?',
  String preview = 'Taqwa means God-consciousness and piety.',
}) {
  return ConversationThread(
    id: id,
    title: title,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
    userName: 'TestUser',
    userId: 'demo-user-001',
    messageCount: 2,
    lastMessagePreview: preview,
  );
}

void main() {
  group('DetailScreen bookmark integration', () {
    testWidgets('shows bookmark_outline icon when thread is not bookmarked',
        (tester) async {
      final provider = BookmarkProvider();
      final thread = makeThread();

      await tester.pumpWidget(
        buildTestWidget(
          bookmarkProvider: provider,
          child: DetailScreen(thread: thread),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.bookmark_outline), findsOneWidget);
      expect(find.byIcon(Icons.copy), findsOneWidget);
    });

    testWidgets('both bookmark and copy buttons are in AppBar actions',
        (tester) async {
      final provider = BookmarkProvider();
      final thread = makeThread();

      await tester.pumpWidget(
        buildTestWidget(
          bookmarkProvider: provider,
          child: DetailScreen(thread: thread),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(IconButton), findsAtLeast(2));
    });

    testWidgets('DetailScreen shows Conversation title', (tester) async {
      final thread = makeThread();

      await tester.pumpWidget(
        buildTestWidget(
          child: DetailScreen(thread: thread),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Conversation'), findsOneWidget);
    });

    testWidgets('DetailScreen shows thread title text', (tester) async {
      final thread = makeThread(title: 'What is Salah?');

      await tester.pumpWidget(
        buildTestWidget(
          child: DetailScreen(thread: thread),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('What is Salah?'), findsOneWidget);
    });
  });
}
