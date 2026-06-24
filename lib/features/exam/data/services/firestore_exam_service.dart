import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/app_constants.dart';
import '../models/exam_model.dart';
import '../models/question_model.dart';

class FirestoreQuizService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ─── Exams ─────────────────────────────────────────────

  Future<List<ExamModel>> getExams({bool publishedOnly = false}) async {
    final snapshot =
        await _firestore.collection(AppConstants.examsCollection).get();
    var exams = snapshot.docs
        .map((doc) => ExamModel.fromMap(doc.data(), doc.id))
        .toList();
    if (publishedOnly) {
      exams = exams.where((e) => e.status == ExamStatus.published).toList();
    }
    return exams;
  }

  Future<ExamModel?> getExam(String examId) async {
    final doc =
        await _firestore.collection(AppConstants.examsCollection).doc(examId).get();
    if (!doc.exists) return null;
    return ExamModel.fromMap(doc.data()!, doc.id);
  }

  Future<void> saveExam(ExamModel exam) async {
    final batch = _firestore.batch();
    batch.set(
      _firestore.collection(AppConstants.examsCollection).doc(exam.examId),
      exam.toMap(),
    );
    await batch.commit();
  }

  Future<void> updateExam(ExamModel exam) async {
    // TODO: Send FCM notification when exam status changes to published
    // if (exam.status == ExamStatus.published) { ... }
    await _firestore
        .collection(AppConstants.examsCollection)
        .doc(exam.examId)
        .update(exam.toMap());
  }

  // ─── Questions ──────────────────────────────────────────

  Future<List<QuestionModel>> getExamQuestions(String examId) async {
    final snapshot = await _firestore
        .collection(AppConstants.questionsCollection)
        .where('examId', isEqualTo: examId)
        .get();
    return snapshot.docs
        .map((doc) => QuestionModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  Future<List<QuestionModel>> getQuestionsBySubject(String subject) async {
    final snapshot = await _firestore
        .collection(AppConstants.questionsCollection)
        .where('subject', isEqualTo: subject)
        .get();
    return snapshot.docs
        .map((doc) => QuestionModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  Future<int> getExamQuestionCount(String examId) async {
    final snapshot = await _firestore
        .collection(AppConstants.questionsCollection)
        .where('examId', isEqualTo: examId)
        .get();
    return snapshot.docs.length;
  }

  Future<List<ExamModel>> getRecentExams(int limit, {bool publishedOnly = false}) async {
    final snapshot = await _firestore
        .collection(AppConstants.examsCollection)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();
    var exams = snapshot.docs
        .map((doc) => ExamModel.fromMap(doc.data(), doc.id))
        .toList();
    if (publishedOnly) {
      exams = exams.where((e) => e.status == ExamStatus.published).toList();
    }
    return exams;
  }

  Future<void> saveQuestions(
      String examId, List<QuestionModel> questions) async {
    final batch = _firestore.batch();
    for (final q in questions) {
      batch.set(
        _firestore.collection(AppConstants.questionsCollection).doc(q.id),
        q.toMap(),
      );
    }
    await batch.commit();
  }

  Future<void> deleteAllQuestions(String examId) async {
    final snapshot = await _firestore
        .collection(AppConstants.questionsCollection)
        .where('examId', isEqualTo: examId)
        .get();
    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  Future<void> deleteQuestionsByIds(String examId, List<String> ids) async {
    final batch = _firestore.batch();
    for (final id in ids) {
      batch.delete(
        _firestore.collection(AppConstants.questionsCollection).doc(id),
      );
    }
    await batch.commit();
  }

  // ─── Exam Creation (batch exam + questions) ────────────

  Future<String> createExamWithQuestions({
    required ExamModel exam,
    required List<QuestionModel> questions,
  }) async {
    final batch = _firestore.batch();

    batch.set(
      _firestore.collection(AppConstants.examsCollection).doc(exam.examId),
      exam.toMap(),
    );

    for (final q in questions) {
      batch.set(
        _firestore.collection(AppConstants.questionsCollection).doc(q.id),
        q.toMap(),
      );
    }

    await batch.commit();
    return exam.examId;
  }

  Future<void> updateExamWithQuestions({
    required ExamModel exam,
    required List<QuestionModel> questions,
  }) async {
    final batch = _firestore.batch();

    // Delete old questions
    final oldSnapshot = await _firestore
        .collection(AppConstants.questionsCollection)
        .where('examId', isEqualTo: exam.examId)
        .get();
    for (final doc in oldSnapshot.docs) {
      batch.delete(doc.reference);
    }

    // Save exam
    batch.set(
      _firestore.collection(AppConstants.examsCollection).doc(exam.examId),
      exam.toMap(),
    );

    // Save new questions
    for (final q in questions) {
      batch.set(
        _firestore.collection(AppConstants.questionsCollection).doc(q.id),
        q.toMap(),
      );
    }

    await batch.commit();
  }

  // ─── Cascade Delete ─────────────────────────────────────

  Future<void> deleteExamCascade(String examId) async {
    final batch = _firestore.batch();

    // Questions
    final qSnapshot = await _firestore
        .collection(AppConstants.questionsCollection)
        .where('examId', isEqualTo: examId)
        .get();
    for (final doc in qSnapshot.docs) {
      batch.delete(doc.reference);
    }

    // Results
    final rSnapshot = await _firestore
        .collection(AppConstants.examResultsCollection)
        .where('examId', isEqualTo: examId)
        .get();
    for (final doc in rSnapshot.docs) {
      batch.delete(doc.reference);
    }

    // Exam itself
    batch.delete(
      _firestore.collection(AppConstants.examsCollection).doc(examId),
    );

    await batch.commit();
  }

  // ─── Results ────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getExamResults(String examId) async {
    final snapshot = await _firestore
        .collection(AppConstants.examResultsCollection)
        .where('examId', isEqualTo: examId)
        .orderBy('score', descending: true)
        .get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return data;
    }).toList();
  }

  Future<void> saveExamResult({
    required String examId,
    required String userId,
    required String userName,
    required double score,
    required int totalQuestions,
    required int correctCount,
    required int wrongCount,
    required int skippedCount,
  }) async {
    await _firestore.collection(AppConstants.examResultsCollection).add({
      'examId': examId,
      'userId': userId,
      'userName': userName,
      'score': score,
      'totalQuestions': totalQuestions,
      'correctCount': correctCount,
      'wrongCount': wrongCount,
      'skippedCount': skippedCount,
      'answeredAt': FieldValue.serverTimestamp(),
    });
  }

  // ─── Question Bank ──────────────────────────────────────

  Future<List<QuestionModel>> getQuestionBank() async {
    final snapshot =
        await _firestore.collection(AppConstants.questionBankCollection).get();
    return snapshot.docs
        .map((doc) => QuestionModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  // ─── Users (for admin) ──────────────────────────────────

  Future<List<Map<String, dynamic>>> getAllUsers() async {
    final snapshot =
        await _firestore.collection(AppConstants.usersCollection).get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['uid'] = doc.id;
      return data;
    }).toList();
  }

  // ─── Stats ──────────────────────────────────────────────

  Future<int> getQuestionCount() async {
    final snapshot =
        await _firestore.collection(AppConstants.questionsCollection).get();
    return snapshot.docs.length;
  }

  Future<int> getExamCount() async {
    final snapshot =
        await _firestore.collection(AppConstants.examsCollection).get();
    return snapshot.docs.length;
  }
}
