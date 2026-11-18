import '../../exam/data/models/question_model.dart';

/// Where the user's *first* attempt at an exam stands. `provisional` is true
/// while the exam's scheduled window is still open (more people may sit it).
class ExamRankInfo {
  final int rank;
  final int participants;
  final double percentile;
  final double score;
  final bool isFirstAttempt;
  final bool provisional;

  const ExamRankInfo({
    required this.rank,
    required this.participants,
    required this.percentile,
    required this.score,
    required this.isFirstAttempt,
    required this.provisional,
  });

  factory ExamRankInfo.fromJson(Map<String, dynamic> json) => ExamRankInfo(
    rank: (json['rank'] as num).toInt(),
    participants: (json['participants'] as num).toInt(),
    percentile: (json['percentile'] as num).toDouble(),
    score: (json['score'] as num).toDouble(),
    isFirstAttempt: json['isFirstAttempt'] as bool? ?? true,
    provisional: json['provisional'] as bool? ?? false,
  );
}

/// The server-graded outcome of a submitted exam.
class ExamSubmission {
  final double score;
  final int totalQuestions;
  final int correctCount;
  final int wrongCount;
  final int skippedCount;
  final bool answersAvailable;
  final DateTime? answersAvailableAt;
  final ExamRankInfo? rank;

  const ExamSubmission({
    required this.score,
    required this.totalQuestions,
    required this.correctCount,
    required this.wrongCount,
    required this.skippedCount,
    required this.answersAvailable,
    required this.answersAvailableAt,
    required this.rank,
  });

  factory ExamSubmission.fromJson(Map<String, dynamic> json) => ExamSubmission(
    score: (json['score'] as num).toDouble(),
    totalQuestions: (json['totalQuestions'] as num).toInt(),
    correctCount: (json['correctCount'] as num).toInt(),
    wrongCount: (json['wrongCount'] as num).toInt(),
    skippedCount: (json['skippedCount'] as num).toInt(),
    answersAvailable: json['answersAvailable'] as bool? ?? false,
    answersAvailableAt: DateTime.tryParse(
      json['answersAvailableAt'] as String? ?? '',
    )?.toLocal(),
    rank: json['rank'] is Map
        ? ExamRankInfo.fromJson(Map<String, dynamic>.from(json['rank'] as Map))
        : null,
  );
}

class ExamLeaderboardEntry {
  final int rank;
  final String name;
  final double score;
  final bool isYou;

  const ExamLeaderboardEntry({
    required this.rank,
    required this.name,
    required this.score,
    required this.isYou,
  });

  factory ExamLeaderboardEntry.fromJson(Map<String, dynamic> json) =>
      ExamLeaderboardEntry(
        rank: (json['rank'] as num).toInt(),
        name: json['name'] as String? ?? '',
        score: (json['score'] as num).toDouble(),
        isYou: json['isYou'] as bool? ?? false,
      );
}

class ExamLeaderboard {
  final List<ExamLeaderboardEntry> entries;
  final bool provisional;

  const ExamLeaderboard({required this.entries, required this.provisional});

  factory ExamLeaderboard.fromJson(Map<String, dynamic> json) =>
      ExamLeaderboard(
        entries: (json['entries'] as List? ?? const [])
            .map(
              (e) => ExamLeaderboardEntry.fromJson(
                Map<String, dynamic>.from(e as Map),
              ),
            )
            .toList(),
        provisional: json['provisional'] as bool? ?? false,
      );
}

/// A question whose latest answer was wrong (or skipped, when [selectedKey]
/// is null), with its correct answer and explanation.
class MistakeQuestion {
  final QuestionModel question;
  final String? selectedKey;

  const MistakeQuestion({required this.question, required this.selectedKey});

  factory MistakeQuestion.fromJson(Map<String, dynamic> json) =>
      MistakeQuestion(
        question: QuestionModel.fromMap(json, json['id'] as String? ?? ''),
        selectedKey: json['selectedKey'] as String?,
      );
}

class SubjectPerformance {
  final int nodeId;
  final int syllabusId;
  final String name;
  final int attempted;
  final int correct;
  final int wrong;
  final int skipped;
  final double accuracy;

  const SubjectPerformance({
    required this.nodeId,
    required this.syllabusId,
    required this.name,
    required this.attempted,
    required this.correct,
    required this.wrong,
    required this.skipped,
    required this.accuracy,
  });

  factory SubjectPerformance.fromJson(Map<String, dynamic> json) =>
      SubjectPerformance(
        nodeId: (json['nodeId'] as num).toInt(),
        syllabusId: (json['syllabusId'] as num).toInt(),
        name: json['name'] as String? ?? '',
        attempted: (json['attempted'] as num? ?? 0).toInt(),
        correct: (json['correct'] as num? ?? 0).toInt(),
        wrong: (json['wrong'] as num? ?? 0).toInt(),
        skipped: (json['skipped'] as num? ?? 0).toInt(),
        accuracy: (json['accuracy'] as num? ?? 0).toDouble(),
      );
}
