import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:vorflux/models/conversation_thread.dart';
import 'package:vorflux/providers/auth_provider.dart';
import 'package:vorflux/providers/bookmark_provider.dart';
import 'package:vorflux/services/firebase_config.dart';
import 'package:vorflux/widgets/bookmark_toggle_button.dart';

Widget buildTestWidget({
  required BookmarkProvider bookmarkProvider,
  required Widget child,
}) {
  FirebaseConfig.setAvailable(false);
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<BookmarkProvider>.value(value: bookmarkProvider),
      ChangeNotifierProvider<AuthProvider>(create: (_) => AuthProvider()),
    ],
    child: MaterialApp(
      home: Scaffold(body: child),
    ),
  );
}

ConversationThread makeThread({String id = 'thread-1'}) {
  final now = DateTime.now();
  return ConversationThread(
    id: id,
    title: 'What is Taqwa?',
    createdAt: now,
    updatedAt: now,
    userName: 'TestUser',
    userId: 'demo-user-001',
    messageCount: 2,
    lastMessagePreview: 'Taqwa means God-consciousness.',
  );
}

void main() {
  group('BookmarkToggleButton', () {
    testWidgets('shows outline icon when not bookmarked', (tester) async {
      final provider = BookmarkProvider();
      final thread = makeThread();

      await tester.pumpWidget(buildTestWidget(
        bookmarkProvider: provider,
        child: BookmarkToggleButton(thread: thread),
      ));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.bookmark_outline), findsOneWidget);
      expect(find.byIcon(Icons.bookmark), findsNothing);
    });

    testWidgets('shows label when showLabel is true', (tester) async {
      final provider = BookmarkProvider();
      final thread = makeThread();

      await tester.pumpWidget(buildTestWidget(
        bookmarkProvider: provider,
        child: BookmarkToggleButton(thread: thread, showLabel: true),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Save'), findsOneWidget);
    });

    testWidgets('does not show label by default', (tester) async {
      final provider = BookmarkProvider();
      final thread = makeThread();

      await tester.pumpWidget(buildTestWidget(
        bookmarkProvider: provider,
        child: BookmarkToggleButton(thread: thread),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Save'), findsNothing);
      expect(find.text('Saved'), findsNothing);
    });

    testWidgets('respects custom iconSize', (tester) async {
      final provider = BookmarkProvider();
      final thread = makeThread();

      await tester.pumpWidget(buildTestWidget(
        bookmarkProvider: provider,
        child: BookmarkToggleButton(thread: thread, iconSize: 18),
      ));
      await tester.pumpAndSettle();

      final icon = tester.widget<Icon>(find.byIcon(Icons.bookmark_outline));
      expect(icon.size, 18);
    });
  });
}
