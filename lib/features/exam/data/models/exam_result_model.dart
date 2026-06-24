import 'package:cloud_firestore/cloud_firestore.dart';

class ExamResultModel {
  final String id;
  final String examId;
  final double score;
  final int totalQuestions;
  final int correctCount;
  final int wrongCount;
  final int skippedCount;
  final DateTime answeredAt;

  ExamResultModel({
    required this.id,
    required this.examId,
    required this.score,
    required this.totalQuestions,
    required this.correctCount,
    required this.wrongCount,
    required this.skippedCount,
    required this.answeredAt,
  });

  double get percentage =>
      totalQuestions > 0 ? (correctCount / totalQuestions) * 100 : 0.0;

  factory ExamResultModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ExamResultModel(
      id: doc.id,
      examId: data['examId'] ?? '',
      score: (data['score'] ?? 0.0).toDouble(),
      totalQuestions: data['totalQuestions'] ?? 0,
      correctCount: data['correctCount'] ?? 0,
      wrongCount: data['wrongCount'] ?? 0,
      skippedCount: data['skippedCount'] ?? 0,
      answeredAt: (data['answeredAt'] as dynamic)?.toDate() ?? DateTime.now(),
    );
  }
}
