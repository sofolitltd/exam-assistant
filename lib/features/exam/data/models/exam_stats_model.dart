/// One question most people got wrong in an exam.
class ExamHardQuestion {
  final String questionId;
  final String questionText;
  final int attempts;
  final int correctPercent;

  ExamHardQuestion({
    required this.questionId,
    required this.questionText,
    required this.attempts,
    required this.correctPercent,
  });

  factory ExamHardQuestion.fromMap(Map<String, dynamic> map) {
    return ExamHardQuestion(
      questionId: map['questionId'] as String? ?? '',
      questionText: map['questionText'] as String? ?? '',
      attempts: (map['attempts'] as num?)?.toInt() ?? 0,
      correctPercent: (map['correctPercent'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Everyone's average score and the hardest questions in an exam, available
/// once its sitting window has closed (mirrors the answer key).
class ExamStats {
  final int participants;
  final double average;
  final List<ExamHardQuestion> hardest;

  ExamStats({
    required this.participants,
    required this.average,
    required this.hardest,
  });

  factory ExamStats.fromMap(Map<String, dynamic> map) {
    return ExamStats(
      participants: (map['participants'] as num?)?.toInt() ?? 0,
      average: (map['average'] as num?)?.toDouble() ?? 0,
      hardest: [
        for (final item in (map['hardest'] as List? ?? const []))
          ExamHardQuestion.fromMap(Map<String, dynamic>.from(item as Map)),
      ],
    );
  }
}
