import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:vorflux/models/conversation_thread.dart';
import 'package:vorflux/providers/auth_provider.dart';
import 'package:vorflux/providers/bookmark_provider.dart';
import 'package:vorflux/screens/saved_screen.dart';
import 'package:vorflux/services/firebase_config.dart';

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
    child: MaterialApp(home: Scaffold(body: child)),
  );
}

ConversationThread makeThread({
  String id = 'thread-1',
  String title = 'What is the meaning of Taqwa?',
  String preview = 'Taqwa means God-consciousness and piety.',
  DateTime? timestamp,
}) {
  final updated = timestamp ?? DateTime.now();
  return ConversationThread(
    id: id,
    title: title,
    createdAt: updated.subtract(const Duration(minutes: 1)),
    updatedAt: updated,
    userName: 'TestUser',
    userId: 'demo-user-001',
    messageCount: 2,
    lastMessagePreview: preview,
  );
}

void main() {
  group('SavedScreen', () {
    testWidgets('shows empty state when no bookmarks', (tester) async {
      final provider = BookmarkProvider();

      await tester.pumpWidget(buildTestWidget(
        bookmarkProvider: provider,
        child: const SavedScreen(),
      ));
      await tester.pumpAndSettle();

      expect(find.text('No Saved Threads Yet'), findsOneWidget);
      expect(find.text('Bookmark conversations to find them here'), findsOneWidget);
      expect(find.byIcon(Icons.bookmark_outline), findsOneWidget);
    });
  });
}
