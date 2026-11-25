/// Practice stats and sessions from `/v1/practice/*` and the mistakes
/// summary from `/v1/users/me/mistakes/summary`.
library;

int _int(Object? v) => (v as num?)?.toInt() ?? 0;

class PracticeCount {
  final int answered;
  final int correct;

  const PracticeCount({this.answered = 0, this.correct = 0});

  int get wrong => answered - correct;
  double? get accuracy => answered == 0 ? null : correct / answered;

  factory PracticeCount.fromJson(Object? json) {
    final m = json is Map ? json : const {};
    return PracticeCount(
      answered: _int(m['answered']),
      correct: _int(m['correct']),
    );
  }
}

class PracticeDay {
  final DateTime date;
  final PracticeCount count;

  const PracticeDay(this.date, this.count);
}

class PracticeSessionInfo {
  final int sessionId;

  /// paper, subject, topic or mistakes.
  final String source;
  final String? examId;
  final String label;
  final int answered;
  final int correct;
  final DateTime lastAnswerAt;

  const PracticeSessionInfo({
    required this.sessionId,
    required this.source,
    required this.examId,
    required this.label,
    required this.answered,
    required this.correct,
    required this.lastAnswerAt,
  });

  factory PracticeSessionInfo.fromJson(Map<String, dynamic> json) =>
      PracticeSessionInfo(
        sessionId: _int(json['sessionId']),
        source: json['source'] as String? ?? 'paper',
        examId: json['examId'] as String?,
        label: json['label'] as String? ?? '',
        answered: _int(json['answered']),
        correct: _int(json['correct']),
        lastAnswerAt:
            DateTime.tryParse(
              json['lastAnswerAt'] as String? ?? '',
            )?.toLocal() ??
            DateTime.now(),
      );
}

class PracticeStreak {
  final int current;
  final int best;
  final bool todayCounted;

  /// Questions a day needs before it counts toward the streak.
  final int minAnswers;

  const PracticeStreak({
    this.current = 0,
    this.best = 0,
    this.todayCounted = false,
    this.minAnswers = 10,
  });

  factory PracticeStreak.fromJson(Object? json) {
    final m = json is Map ? json : const {};
    return PracticeStreak(
      current: _int(m['current']),
      best: _int(m['best']),
      todayCounted: m['todayCounted'] as bool? ?? false,
      minAnswers: _int(m['minAnswers']) == 0 ? 10 : _int(m['minAnswers']),
    );
  }
}

class PracticeSummary {
  final PracticeCount today;
  final PracticeCount week;
  final PracticeCount total;

  /// Every answer today, practice or exam; the streak goes by this.
  final int todayAll;

  /// Open wrong answers, from exams and practice.
  final int mistakes;
  final int reviewDue;

  /// Answers given in ranked exams (for the "সব" totals).
  final int examAnswered;
  final List<PracticeDay> days;
  final PracticeStreak streak;
  final List<PracticeSessionInfo> sessions;

  const PracticeSummary({
    required this.today,
    required this.week,
    required this.total,
    required this.todayAll,
    required this.mistakes,
    required this.reviewDue,
    required this.examAnswered,
    required this.days,
    required this.streak,
    required this.sessions,
  });

  /// Answers today (any mode) still needed for today's streak day.
  int get todayLeft => streak.todayCounted
      ? 0
      : (streak.minAnswers - todayAll).clamp(0, streak.minAnswers);

  factory PracticeSummary.fromJson(dynamic json) {
    final m = Map<String, dynamic>.from(json as Map);
    return PracticeSummary(
      today: PracticeCount.fromJson(m['today']),
      week: PracticeCount.fromJson(m['week']),
      total: PracticeCount.fromJson(m['total']),
      todayAll: _int(m['todayAll']),
      mistakes: _int(m['mistakes']),
      reviewDue: _int(m['reviewDue']),
      examAnswered: _int(m['examAnswered']),
      days: [
        for (final d in (m['days'] as List? ?? const []))
          PracticeDay(
            DateTime.tryParse((d as Map)['date'] as String? ?? '') ??
                DateTime.now(),
            PracticeCount.fromJson(d),
          ),
      ],
      streak: PracticeStreak.fromJson(m['streak']),
      sessions: [
        for (final s in (m['sessions'] as List? ?? const []))
          PracticeSessionInfo.fromJson(Map<String, dynamic>.from(s as Map)),
      ],
    );
  }
}

/// How much of one paper the user has practised.
class ExamPracticeProgress {
  final String examId;
  final int answered;
  final int correct;
  final int total;

  const ExamPracticeProgress({
    required this.examId,
    required this.answered,
    required this.correct,
    required this.total,
  });

  factory ExamPracticeProgress.fromJson(Map<String, dynamic> json) =>
      ExamPracticeProgress(
        examId: json['examId'] as String? ?? '',
        answered: _int(json['answered']),
        correct: _int(json['correct']),
        total: _int(json['total']),
      );
}

class MistakeSubjectCount {
  final int subjectId;
  final String name;
  final int count;

  const MistakeSubjectCount(this.subjectId, this.name, this.count);
}

class MistakeSummary {
  final int total;
  final int exam;
  final int practice;
  final int skipped;
  final List<MistakeSubjectCount> subjects;

  const MistakeSummary({
    this.total = 0,
    this.exam = 0,
    this.practice = 0,
    this.skipped = 0,
    this.subjects = const [],
  });

  factory MistakeSummary.fromJson(dynamic json) {
    final m = Map<String, dynamic>.from(json as Map);
    return MistakeSummary(
      total: _int(m['total']),
      exam: _int(m['exam']),
      practice: _int(m['practice']),
      skipped: _int(m['skipped']),
      subjects: [
        for (final s in (m['subjects'] as List? ?? const []))
          MistakeSubjectCount(
            _int((s as Map)['subjectId']),
            s['name'] as String? ?? '',
            _int(s['count']),
          ),
      ],
    );
  }
}

/// Where practice answers are saved: which kind of practice, the paper
/// when there is one, and a short label for the history list.
class PracticeTarget {
  /// paper, subject, topic or mistakes.
  final String source;
  final String? examId;
  final String label;

  const PracticeTarget({
    required this.source,
    required this.label,
    this.examId,
  });
}
