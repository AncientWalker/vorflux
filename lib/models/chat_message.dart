import 'package:vorflux/utils/text_utils.dart';

class ChatMessage {
  final String id;
  final String threadId;
  final String role;
  final String content;
  final DateTime timestamp;
  final String? feedback;

  const ChatMessage({
    required this.id,
    required this.threadId,
    required this.role,
    required this.content,
    required this.timestamp,
    this.feedback,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'threadId': threadId,
      'role': role,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'feedback': feedback,
    };
  }

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      id: map['id'] as String,
      threadId: map['threadId'] as String,
      role: map['role'] as String,
      content: map['content'] as String,
      timestamp: DateTime.parse(map['timestamp'] as String),
      feedback: map['feedback'] as String?,
    );
  }

  ChatMessage copyWith({
    String? id,
    String? threadId,
    String? role,
    String? content,
    DateTime? timestamp,
    String? Function()? feedback,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      threadId: threadId ?? this.threadId,
      role: role ?? this.role,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      feedback: feedback != null ? feedback() : this.feedback,
    );
  }

  String get formattedTimestamp => formatRelativeTimestamp(timestamp);
}
