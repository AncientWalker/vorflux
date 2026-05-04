import 'package:vorflux/models/conversation_thread.dart';

/// Creates a [ConversationThread] with sensible defaults for tests.
ConversationThread makeThread({
  String id = '1',
  String title = 'Test question',
  String lastMessagePreview = 'Test answer',
  String? userName,
  String? userPhotoURL,
  String? userId,
  int messageCount = 2,
  DateTime? createdAt,
  DateTime? updatedAt,
}) {
  final now = DateTime.now();
  return ConversationThread(
    id: id,
    title: title,
    createdAt: createdAt ?? now,
    updatedAt: updatedAt ?? now,
    userId: userId,
    userName: userName,
    userPhotoURL: userPhotoURL,
    messageCount: messageCount,
    lastMessagePreview: lastMessagePreview,
  );
}
