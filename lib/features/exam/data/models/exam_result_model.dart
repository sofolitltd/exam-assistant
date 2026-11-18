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

  factory ExamResultModel.fromJson(Map<String, dynamic> data) {
    return ExamResultModel(
      id: (data['id'] ?? data['resultId'] ?? '').toString(),
      examId: data['examId'] ?? '',
      score: (data['score'] as num? ?? 0).toDouble(),
      totalQuestions: (data['totalQuestions'] as num? ?? 0).toInt(),
      correctCount: (data['correctCount'] as num? ?? 0).toInt(),
      wrongCount: (data['wrongCount'] as num? ?? 0).toInt(),
      skippedCount: (data['skippedCount'] as num? ?? 0).toInt(),
      answeredAt:
          DateTime.tryParse(data['answeredAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
