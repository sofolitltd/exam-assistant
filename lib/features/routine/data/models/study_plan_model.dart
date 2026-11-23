import '../../../goals/data/goals.dart';

/// A study plan computed by the server from the countdown to the target
/// exam, the learner's own study time, what past papers ask and where the
/// learner is weak.
class PlanTopic {
  final int nodeId;
  final int syllabusId;
  final String name;

  const PlanTopic({
    required this.nodeId,
    required this.syllabusId,
    required this.name,
  });

  factory PlanTopic.fromJson(Map<String, dynamic> json) => PlanTopic(
    nodeId: (json['nodeId'] as num).toInt(),
    syllabusId: (json['syllabusId'] as num).toInt(),
    name: json['name'] as String? ?? '',
  );
}

class PlanSubject {
  final String name;
  final int minutes;
  final double questionsPerPaper;
  final int attempted;
  final double? accuracy;
  final String reason;
  final List<PlanTopic> topics;

  const PlanSubject({
    required this.name,
    required this.minutes,
    required this.questionsPerPaper,
    required this.attempted,
    required this.accuracy,
    required this.reason,
    required this.topics,
  });

  factory PlanSubject.fromJson(Map<String, dynamic> json) => PlanSubject(
    name: json['name'] as String? ?? '',
    minutes: (json['minutes'] as num).toInt(),
    questionsPerPaper: (json['questionsPerPaper'] as num).toDouble(),
    attempted: (json['attempted'] as num).toInt(),
    accuracy: (json['accuracy'] as num?)?.toDouble(),
    reason: json['reason'] as String? ?? 'steady',
    topics: [
      for (final t in (json['topics'] as List? ?? const []))
        PlanTopic.fromJson(Map<String, dynamic>.from(t as Map)),
    ],
  );
}

/// One goal's share of today's study time.
class GoalMix {
  final int goalId;
  final double share;

  /// marks (the exam's mark split) or papers (BCS question frequency).
  final String weightsFrom;

  const GoalMix({
    required this.goalId,
    required this.share,
    required this.weightsFrom,
  });
}

class StudyPlan {
  final DateTime? targetDate;
  final String? targetLabel;

  /// `user` (chosen), `edition` (the chosen BCS sitting), `default` (the
  /// next BCS from the editions list) or `none`.
  final String targetSource;
  final int? targetEdition;

  /// The primary goal the plan counts down to (null: no goal yet).
  final UserGoal? goal;

  /// All the learner's goals, primary first.
  final List<UserGoal> goals;

  /// Each goal's share of today's time (0 to 1).
  final List<GoalMix> goalMix;

  /// The goal a week or less away, which gets the whole day.
  final int? sprintGoalId;

  /// A close goal, sooner than the primary one, worth making primary.
  final int? suggestPrimaryGoalId;

  UserGoal? goalById(int? id) {
    if (id == null) return null;
    for (final g in goals) {
      if (g.id == id) return g;
    }
    return null;
  }

  final int? daysLeft;

  /// foundation, revision or final.
  final String phase;
  final int minutesPerDay;

  /// `routine` (from the learner's study blocks), `query` or `default`.
  final String minutesSource;
  final int learnMinutes;
  final int practiceMinutes;
  final List<PlanSubject> subjects;

  const StudyPlan({
    required this.targetDate,
    required this.targetLabel,
    required this.targetSource,
    required this.targetEdition,
    this.goal,
    this.goals = const [],
    this.goalMix = const [],
    this.sprintGoalId,
    this.suggestPrimaryGoalId,
    required this.daysLeft,
    required this.phase,
    required this.minutesPerDay,
    required this.minutesSource,
    required this.learnMinutes,
    required this.practiceMinutes,
    required this.subjects,
  });

  factory StudyPlan.fromJson(dynamic json) {
    final map = Map<String, dynamic>.from(json as Map);
    return StudyPlan(
      targetDate: DateTime.tryParse(map['targetDate'] as String? ?? ''),
      targetLabel: map['targetLabel'] as String?,
      targetSource: map['targetSource'] as String? ?? 'none',
      targetEdition: (map['targetEdition'] as num?)?.toInt(),
      goal: map['goal'] is Map
          ? UserGoal.fromJson(Map<String, dynamic>.from(map['goal'] as Map))
          : null,
      goals: [
        for (final g in (map['goals'] as List? ?? const []))
          if (g is Map) UserGoal.fromJson(Map<String, dynamic>.from(g)),
      ],
      goalMix: [
        for (final m in (map['goalMix'] as List? ?? const []))
          if (m is Map)
            GoalMix(
              goalId: (m['goalId'] as num).toInt(),
              share: (m['share'] as num?)?.toDouble() ?? 0,
              weightsFrom: m['weightsFrom'] as String? ?? 'papers',
            ),
      ],
      sprintGoalId: (map['sprintGoalId'] as num?)?.toInt(),
      suggestPrimaryGoalId: (map['suggestPrimaryGoalId'] as num?)?.toInt(),
      daysLeft: (map['daysLeft'] as num?)?.toInt(),
      phase: map['phase'] as String? ?? 'foundation',
      minutesPerDay: (map['minutesPerDay'] as num).toInt(),
      minutesSource: map['minutesSource'] as String? ?? 'default',
      learnMinutes: (map['learnMinutes'] as num).toInt(),
      practiceMinutes: (map['practiceMinutes'] as num).toInt(),
      subjects: [
        for (final s in (map['subjects'] as List? ?? const []))
          PlanSubject.fromJson(Map<String, dynamic>.from(s as Map)),
      ],
    );
  }
}
