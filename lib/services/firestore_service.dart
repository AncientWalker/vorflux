import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vorflux/models/conversation_thread.dart';
import 'package:vorflux/models/chat_message.dart';
import 'package:vorflux/utils/text_utils.dart';

class FirestoreService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _threadsCollection = 'threads';
  static const String _messagesSubcollection = 'messages';
  static const String _legacyQuestionsCollection = 'questions';

  static Future<String> createThread({
    required String userId,
    required String userName,
    required String userPhotoURL,
    required String title,
  }) async {
    final docRef = await _firestore.collection(_threadsCollection).add({
      'title': title,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'userId': userId,
      'userName': userName,
      'userPhotoURL': userPhotoURL,
      'messageCount': 0,
      'lastMessagePreview': '',
    });
    return docRef.id;
  }

  static Future<void> addMessage({
    required String threadId,
    required String role,
    required String content,
  }) async {
    final threadRef =
        _firestore.collection(_threadsCollection).doc(threadId);
    await threadRef.collection(_messagesSubcollection).add({
      'role': role,
      'content': content,
      'timestamp': FieldValue.serverTimestamp(),
    });
    final preview = truncatePreview(content);
    await threadRef.update({
      'updatedAt': FieldValue.serverTimestamp(),
      'messageCount': FieldValue.increment(1),
      'lastMessagePreview': preview,
    });
  }

  static Stream<List<ConversationThread>> getUserThreads(String userId) {
    return _firestore
        .collection(_threadsCollection)
        .where('userId', isEqualTo: userId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => _docToThread(doc)).toList());
  }

  static Stream<List<ConversationThread>> getAllThreads() {
    return _firestore
        .collection(_threadsCollection)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => _docToThread(doc)).toList());
  }

  static Future<List<ChatMessage>> getThreadMessages(
      String threadId) async {
    final snapshot = await _firestore
        .collection(_threadsCollection)
        .doc(threadId)
        .collection(_messagesSubcollection)
        .orderBy('timestamp')
        .get();
    return snapshot.docs
        .map((doc) => _docToMessage(doc, threadId))
        .toList();
  }

  static Future<void> deleteThread(String threadId) async {
    final threadRef =
        _firestore.collection(_threadsCollection).doc(threadId);
    final messagesSnapshot =
        await threadRef.collection(_messagesSubcollection).get();
    final batch = _firestore.batch();
    for (final doc in messagesSnapshot.docs) {
      batch.delete(doc.reference);
    }
    batch.delete(threadRef);
    await batch.commit();
  }

  static Future<void> deleteAllUserThreads(String userId) async {
    final threadsSnapshot = await _firestore
        .collection(_threadsCollection)
        .where('userId', isEqualTo: userId)
        .get();
    for (final threadDoc in threadsSnapshot.docs) {
      await deleteThread(threadDoc.id);
    }
  }

  static Future<void> migrateLegacyQuestions(String userId) async {
    final legacySnapshot = await _firestore
        .collection(_legacyQuestionsCollection)
        .where('userId', isEqualTo: userId)
        .get();

    for (final doc in legacySnapshot.docs) {
      final data = doc.data();
      if (data['migratedToThread'] == true) continue;

      final questionText = data['questionText'] as String? ?? '';
      final answerText = data['answerText'] as String? ?? '';
      final createdAt = data['createdAt'] as Timestamp?;
      final userName = data['userName'] as String? ?? '';
      final userPhotoURL = data['userPhotoURL'] as String? ?? '';
      final title = truncateTitle(questionText);
      final preview = truncatePreview(answerText);

      final threadRef =
          await _firestore.collection(_threadsCollection).add({
        'title': title,
        'createdAt': createdAt ?? FieldValue.serverTimestamp(),
        'updatedAt': createdAt ?? FieldValue.serverTimestamp(),
        'userId': userId,
        'userName': userName,
        'userPhotoURL': userPhotoURL,
        'messageCount': 2,
        'lastMessagePreview': preview,
      });

      await threadRef.collection(_messagesSubcollection).add({
        'role': 'user',
        'content': questionText,
        'timestamp': createdAt ?? FieldValue.serverTimestamp(),
      });

      final assistantTimestamp = createdAt != null
          ? Timestamp.fromDate(
              createdAt.toDate().add(const Duration(seconds: 1)))
          : FieldValue.serverTimestamp();
      await threadRef.collection(_messagesSubcollection).add({
        'role': 'assistant',
        'content': answerText,
        'timestamp': assistantTimestamp,
      });

      await doc.reference.update({'migratedToThread': true});
    }
  }

  static ConversationThread _docToThread(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final createdAt = data['createdAt'] as Timestamp?;
    final updatedAt = data['updatedAt'] as Timestamp?;
    return ConversationThread(
      id: doc.id,
      title: data['title'] as String? ?? '',
      createdAt: createdAt?.toDate() ?? DateTime.now(),
      updatedAt: updatedAt?.toDate() ?? DateTime.now(),
      userId: data['userId'] as String?,
      userName: data['userName'] as String?,
      userPhotoURL: data['userPhotoURL'] as String?,
      messageCount: (data['messageCount'] as int?) ?? 0,
      lastMessagePreview:
          (data['lastMessagePreview'] as String?) ?? '',
    );
  }

  static ChatMessage _docToMessage(
      QueryDocumentSnapshot doc, String threadId) {
    final data = doc.data() as Map<String, dynamic>;
    final timestamp = data['timestamp'] as Timestamp?;
    return ChatMessage(
      id: doc.id,
      threadId: threadId,
      role: data['role'] as String? ?? 'user',
      content: data['content'] as String? ?? '',
      timestamp: timestamp?.toDate() ?? DateTime.now(),
    );
  }
}
