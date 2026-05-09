import 'package:vorflux/models/chat_message.dart';
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

/// Creates a [ChatMessage] with sensible defaults for tests.
ChatMessage makeMessage({
  String id = 'msg-1',
  String threadId = 'thread-1',
  String role = 'assistant',
  String content = 'Test answer',
  DateTime? timestamp,
  String? feedback,
}) {
  return ChatMessage(
    id: id,
    threadId: threadId,
    role: role,
    content: content,
    timestamp: timestamp ?? DateTime(2025, 1, 1),
    feedback: feedback,
  );
}
