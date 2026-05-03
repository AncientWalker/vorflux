import 'package:vorflux/models/chat_message.dart';

class ConversationThread {
  final String id;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? userId;
  final String? userName;
  final String? userPhotoURL;
  final List<ChatMessage> messages;
  final int messageCount;
  final String lastMessagePreview;

  const ConversationThread({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    this.userId,
    this.userName,
    this.userPhotoURL,
    this.messages = const [],
    this.messageCount = 0,
    this.lastMessagePreview = '',
  });

  ConversationThread copyWith({
    String? id,
    String? title,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? userId,
    String? userName,
    String? userPhotoURL,
    List<ChatMessage>? messages,
    int? messageCount,
    String? lastMessagePreview,
  }) {
    return ConversationThread(
      id: id ?? this.id,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userPhotoURL: userPhotoURL ?? this.userPhotoURL,
      messages: messages ?? this.messages,
      messageCount: messageCount ?? this.messageCount,
      lastMessagePreview: lastMessagePreview ?? this.lastMessagePreview,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'userId': userId,
      'userName': userName,
      'userPhotoURL': userPhotoURL,
      'messageCount': messageCount,
      'lastMessagePreview': lastMessagePreview,
    };
  }

  factory ConversationThread.fromMap(Map<String, dynamic> map) {
    return ConversationThread(
      id: map['id'] as String,
      title: map['title'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
      userId: map['userId'] as String?,
      userName: map['userName'] as String?,
      userPhotoURL: map['userPhotoURL'] as String?,
      messageCount: (map['messageCount'] as int?) ?? 0,
      lastMessagePreview: (map['lastMessagePreview'] as String?) ?? '',
    );
  }

  String get formattedTimestamp {
    final now = DateTime.now();
    final diff = now.difference(updatedAt);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';

    return '${updatedAt.day.toString().padLeft(2, '0')}/${updatedAt.month.toString().padLeft(2, '0')}/${updatedAt.year}';
  }
}
