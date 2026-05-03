import 'package:vorflux/models/qa_entry.dart';

/// Creates a [QAEntry] with sensible defaults for tests.
QAEntry makeEntry({
  String id = '1',
  String question = 'Test question',
  String answer = 'Test answer',
  String? askedBy,
  String? userPhotoURL,
  String? userId,
}) {
  return QAEntry(
    id: id,
    question: question,
    answer: answer,
    timestamp: DateTime.now(),
    askedBy: askedBy,
    userPhotoURL: userPhotoURL,
    userId: userId,
  );
}
