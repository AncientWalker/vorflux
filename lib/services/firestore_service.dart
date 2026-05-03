import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vorflux/models/qa_entry.dart';

class FirestoreService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _questionsCollection = 'questions';

  static Future<String> saveQuestion({
    required String userId,
    required String userName,
    required String userPhotoURL,
    required String questionText,
    required String answerText,
  }) async {
    final docRef = await _firestore.collection(_questionsCollection).add({
      'userId': userId,
      'userName': userName,
      'userPhotoURL': userPhotoURL,
      'questionText': questionText,
      'answerText': answerText,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return docRef.id;
  }

  static Stream<List<QAEntry>> getUserQuestions(String userId) {
    return _firestore
        .collection(_questionsCollection)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => _docToQAEntry(doc)).toList());
  }

  static Stream<List<QAEntry>> getAllQuestions() {
    return _firestore
        .collection(_questionsCollection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => _docToQAEntry(doc)).toList());
  }

  static Future<void> deleteQuestion(String docId) async {
    await _firestore.collection(_questionsCollection).doc(docId).delete();
  }

  static Future<void> deleteAllUserQuestions(String userId) async {
    final batch = _firestore.batch();
    final snapshot = await _firestore
        .collection(_questionsCollection)
        .where('userId', isEqualTo: userId)
        .get();

    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  static QAEntry _docToQAEntry(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final timestamp = data['createdAt'] as Timestamp?;

    return QAEntry(
      id: doc.id,
      question: data['questionText'] as String? ?? '',
      answer: data['answerText'] as String? ?? '',
      timestamp: timestamp?.toDate() ?? DateTime.now(),
      askedBy: data['userName'] as String?,
      userPhotoURL: data['userPhotoURL'] as String?,
      userId: data['userId'] as String?,
    );
  }
}
