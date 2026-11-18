class RoutineBlockSummary {
  final int blockId;
  final String title;
  final String category;
  final int doneCount;
  final int partialCount;
  final int missedCount;

  /// Only for blocks linked to a syllabus subject: exam accuracy on that
  /// subject this week and the week before (null when nothing was answered).
  final String? subjectName;
  final int examAttempted;
  final double? examAccuracy;
  final int prevExamAttempted;
  final double? prevExamAccuracy;

  const RoutineBlockSummary({
    required this.blockId,
    required this.title,
    required this.category,
    required this.doneCount,
    required this.partialCount,
    required this.missedCount,
    this.subjectName,
    this.examAttempted = 0,
    this.examAccuracy,
    this.prevExamAttempted = 0,
    this.prevExamAccuracy,
  });

  factory RoutineBlockSummary.fromMap(Map<String, dynamic> map) {
    return RoutineBlockSummary(
      blockId: (map['blockId'] as num).toInt(),
      title: map['title'] as String? ?? '',
      category: map['category'] as String? ?? 'other',
      doneCount: (map['doneCount'] as num?)?.toInt() ?? 0,
      partialCount: (map['partialCount'] as num?)?.toInt() ?? 0,
      missedCount: (map['missedCount'] as num?)?.toInt() ?? 0,
      subjectName: map['subjectName'] as String?,
      examAttempted: (map['examAttempted'] as num?)?.toInt() ?? 0,
      examAccuracy: (map['examAccuracy'] as num?)?.toDouble(),
      prevExamAttempted: (map['prevExamAttempted'] as num?)?.toInt() ?? 0,
      prevExamAccuracy: (map['prevExamAccuracy'] as num?)?.toDouble(),
    );
  }

  int get loggedCount => doneCount + partialCount + missedCount;
}

class WeeklySummaryModel {
  final String weekStart;
  final String weekEnd;
  final double completionRate;
  final List<RoutineBlockSummary> blocks;

  const WeeklySummaryModel({
    required this.weekStart,
    required this.weekEnd,
    required this.completionRate,
    required this.blocks,
  });

  factory WeeklySummaryModel.fromMap(Map<String, dynamic> map) {
    return WeeklySummaryModel(
      weekStart: map['weekStart'] as String? ?? '',
      weekEnd: map['weekEnd'] as String? ?? '',
      completionRate: (map['completionRate'] as num?)?.toDouble() ?? 0,
      blocks:
          (map['blocks'] as List<dynamic>?)
              ?.map(
                (e) => RoutineBlockSummary.fromMap(
                  Map<String, dynamic>.from(e as Map),
                ),
              )
              .toList() ??
          const [],
    );
  }

  /// Blocks with at least one missed day, worst-offender first — the
  /// actionable part of the summary ("where am I actually slipping").
  List<RoutineBlockSummary> get weakestBlocks {
    final withMisses = blocks.where((b) => b.missedCount > 0).toList();
    withMisses.sort((a, b) => b.missedCount.compareTo(a.missedCount));
    return withMisses;
  }
}
