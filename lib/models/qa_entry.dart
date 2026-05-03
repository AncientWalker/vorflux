class QAEntry {
  final String id;
  final String question;
  final String answer;
  final DateTime timestamp;
  final String? askedBy;
  final String? userPhotoURL;
  final String? userId;

  QAEntry({
    required this.id,
    required this.question,
    required this.answer,
    required this.timestamp,
    this.askedBy,
    this.userPhotoURL,
    this.userId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'question': question,
      'answer': answer,
      'timestamp': timestamp.toIso8601String(),
      'askedBy': askedBy,
      'userPhotoURL': userPhotoURL,
      'userId': userId,
    };
  }

  factory QAEntry.fromMap(Map<String, dynamic> map) {
    return QAEntry(
      id: map['id'] as String,
      question: map['question'] as String,
      answer: map['answer'] as String,
      timestamp: DateTime.parse(map['timestamp'] as String),
      askedBy: map['askedBy'] as String?,
      userPhotoURL: map['userPhotoURL'] as String?,
      userId: map['userId'] as String?,
    );
  }

  String get answerPreview {
    if (answer.length <= 120) return answer;
    return '${answer.substring(0, 120)}...';
  }

  String get formattedTimestamp {
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';

    return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
  }
}
