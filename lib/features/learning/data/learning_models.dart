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

  /// Where the latest (wrong) answer was given: `exam` or `practice`.
  final String mode;
  final int? subjectId;

  const MistakeQuestion({
    required this.question,
    required this.selectedKey,
    this.mode = 'exam',
    this.subjectId,
  });

  factory MistakeQuestion.fromJson(Map<String, dynamic> json) =>
      MistakeQuestion(
        question: QuestionModel.fromMap(json, json['id'] as String? ?? ''),
        selectedKey: json['selectedKey'] as String?,
        mode: json['mode'] as String? ?? 'exam',
        subjectId: (json['subjectId'] as num?)?.toInt(),
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

/// One syllabus topic with how often it appeared in recent past papers and
/// how the user does on it. `priority` is "study this first" (high first).
class TopicInsight {
  final int nodeId;
  final int syllabusId;
  final String name;
  final String subjectName;
  final int total;
  final int papers;
  final double avgPerPaper;
  final int lastEdition;
  final int attempted;
  final double accuracy;
  final double priority;
  final String focusReason;

  const TopicInsight({
    required this.nodeId,
    required this.syllabusId,
    required this.name,
    required this.subjectName,
    required this.total,
    required this.papers,
    required this.avgPerPaper,
    required this.lastEdition,
    required this.attempted,
    required this.accuracy,
    required this.priority,
    required this.focusReason,
  });

  factory TopicInsight.fromJson(Map<String, dynamic> json) => TopicInsight(
    nodeId: (json['nodeId'] as num).toInt(),
    syllabusId: (json['syllabusId'] as num).toInt(),
    name: json['name'] as String? ?? '',
    subjectName: json['subjectName'] as String? ?? '',
    total: (json['total'] as num).toInt(),
    papers: (json['papers'] as num).toInt(),
    avgPerPaper: (json['avgPerPaper'] as num).toDouble(),
    lastEdition: (json['lastEdition'] as num).toInt(),
    attempted: (json['attempted'] as num).toInt(),
    accuracy: (json['accuracy'] as num).toDouble(),
    priority: (json['priority'] as num).toDouble(),
    focusReason: json['focusReason'] as String? ?? 'ok',
  );
}

class TopicInsights {
  final int papers;
  final List<TopicInsight> items;

  const TopicInsights({required this.papers, required this.items});

  factory TopicInsights.fromJson(dynamic json) {
    final map = Map<String, dynamic>.from(json as Map);
    return TopicInsights(
      papers: (map['papers'] as num?)?.toInt() ?? 0,
      items: [
        for (final item in (map['items'] as List? ?? const []))
          TopicInsight.fromJson(Map<String, dynamic>.from(item as Map)),
      ],
    );
  }
}

/// A question to recall from memory. Carries no answer: the server returns
/// it after the learner commits (see [ReviewAnswerResult]).
class ReviewQuestion {
  final String id;
  final String questionText;
  final String subject;
  final List<QuestionOption> options;
  final int box;

  const ReviewQuestion({
    required this.id,
    required this.questionText,
    required this.subject,
    required this.options,
    required this.box,
  });

  factory ReviewQuestion.fromJson(Map<String, dynamic> json) => ReviewQuestion(
    id: json['id'] as String? ?? '',
    questionText: json['questionText'] as String? ?? '',
    subject: json['subject'] as String? ?? '',
    options: [
      for (final o in (json['options'] as List? ?? const []))
        QuestionOption.fromMap(Map<String, dynamic>.from(o as Map)),
    ],
    box: (json['box'] as num?)?.toInt() ?? 0,
  );
}

class ReviewSummary {
  final int due;
  final int learning;
  final int mastered;

  const ReviewSummary({
    required this.due,
    required this.learning,
    required this.mastered,
  });

  factory ReviewSummary.fromJson(Map<String, dynamic> json) => ReviewSummary(
    due: (json['due'] as num?)?.toInt() ?? 0,
    learning: (json['learning'] as num?)?.toInt() ?? 0,
    mastered: (json['mastered'] as num?)?.toInt() ?? 0,
  );
}

class DueReviews {
  final ReviewSummary summary;
  final List<ReviewQuestion> items;

  const DueReviews({required this.summary, required this.items});

  factory DueReviews.fromJson(dynamic json) {
    final map = Map<String, dynamic>.from(json as Map);
    return DueReviews(
      summary: ReviewSummary.fromJson(
        Map<String, dynamic>.from(map['summary'] as Map? ?? const {}),
      ),
      items: [
        for (final item in (map['items'] as List? ?? const []))
          ReviewQuestion.fromJson(Map<String, dynamic>.from(item as Map)),
      ],
    );
  }
}

class ReviewAnswerResult {
  final bool isCorrect;
  final List<String> correctOptionKeys;
  final String? explanation;
  final int box;
  final bool mastered;
  final DateTime? nextDueAt;

  const ReviewAnswerResult({
    required this.isCorrect,
    required this.correctOptionKeys,
    required this.explanation,
    required this.box,
    required this.mastered,
    required this.nextDueAt,
  });

  factory ReviewAnswerResult.fromJson(dynamic json) {
    final map = Map<String, dynamic>.from(json as Map);
    return ReviewAnswerResult(
      isCorrect: map['isCorrect'] as bool? ?? false,
      correctOptionKeys: List<String>.from(
        map['correctOptionKeys'] as List? ?? const [],
      ),
      explanation: map['explanation'] as String?,
      box: (map['box'] as num?)?.toInt() ?? 0,
      mastered: map['mastered'] as bool? ?? false,
      nextDueAt: DateTime.tryParse(map['nextDueAt'] as String? ?? ''),
    );
  }
}

/// How attempting questions has paid off in one subject under negative
/// marking. `advice` is one of need-more-data, skip-when-unsure,
/// guess-with-care or attempt.
class SubjectStrategy {
  final String name;
  final int attempted;
  final int correct;
  final int wrong;
  final int skipped;
  final double accuracy;
  final double netScore;
  final double lostToNegative;
  final double breakEvenAccuracy;
  final double expectedPerAttempt;
  final String advice;
  final int? avgTimeCorrectMs;
  final int? avgTimeWrongMs;

  const SubjectStrategy({
    required this.name,
    required this.attempted,
    required this.correct,
    required this.wrong,
    required this.skipped,
    required this.accuracy,
    required this.netScore,
    required this.lostToNegative,
    required this.breakEvenAccuracy,
    required this.expectedPerAttempt,
    required this.advice,
    required this.avgTimeCorrectMs,
    required this.avgTimeWrongMs,
  });

  factory SubjectStrategy.fromJson(Map<String, dynamic> json) =>
      SubjectStrategy(
        name: json['name'] as String? ?? '',
        attempted: (json['attempted'] as num).toInt(),
        correct: (json['correct'] as num).toInt(),
        wrong: (json['wrong'] as num).toInt(),
        skipped: (json['skipped'] as num).toInt(),
        accuracy: (json['accuracy'] as num).toDouble(),
        netScore: (json['netScore'] as num).toDouble(),
        lostToNegative: (json['lostToNegative'] as num).toDouble(),
        breakEvenAccuracy: (json['breakEvenAccuracy'] as num).toDouble(),
        expectedPerAttempt: (json['expectedPerAttempt'] as num).toDouble(),
        advice: json['advice'] as String? ?? 'need-more-data',
        avgTimeCorrectMs: (json['avgTimeCorrectMs'] as num?)?.toInt(),
        avgTimeWrongMs: (json['avgTimeWrongMs'] as num?)?.toInt(),
      );
}
