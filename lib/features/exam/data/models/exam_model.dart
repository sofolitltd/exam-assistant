enum ExamStatus { draft, published, archived }

class ExamModel {
  final String examId;
  final String title;
  final int durationSeconds;
  final double negativeMarks;
  final ExamStatus status;
  final DateTime? scheduledDate;
  final DateTime createdAt;
  final int questionCount;

  ExamModel({
    required this.examId,
    required this.title,
    required this.durationSeconds,
    required this.negativeMarks,
    this.status = ExamStatus.draft,
    this.scheduledDate,
    this.questionCount = 0,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory ExamModel.fromMap(Map<String, dynamic> map, String id) {
    final scheduledDate = DateTime.tryParse(
      map['scheduledDate'] as String? ?? '',
    );
    final createdAt =
        DateTime.tryParse(map['createdAt'] as String? ?? '') ?? DateTime.now();
    return ExamModel(
      examId: id,
      title: map['title'] ?? '',
      durationSeconds: (map['durationSeconds'] as num? ?? 0).toInt(),
      negativeMarks: (map['negativeMarks'] as num? ?? 0).toDouble(),
      status: map['status'] != null
          ? ExamStatus.values.firstWhere(
              (e) => e.name == map['status'],
              orElse: () => ExamStatus.draft,
            )
          : ExamStatus.draft,
      scheduledDate: scheduledDate,
      questionCount: (map['questionCount'] as num? ?? 0).toInt(),
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'durationSeconds': durationSeconds,
      'negativeMarks': negativeMarks,
      'status': status.name,
      if (scheduledDate != null)
        'scheduledDate': scheduledDate!.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  bool get isPublished => status == ExamStatus.published;
  bool get isDraft => status == ExamStatus.draft;
  bool get isArchived => status == ExamStatus.archived;

  /// Whether the exam's scheduled sitting window has already closed, so its
  /// answer key can be shown safely. An unscheduled exam has no window to
  /// protect, so it is treated as always available.
  bool get hasEnded {
    final scheduled = scheduledDate;
    if (scheduled == null) return true;
    return DateTime.now().isAfter(
      scheduled.add(Duration(seconds: durationSeconds)),
    );
  }
}

extension ExamStatusX on ExamStatus {
  String get label {
    switch (this) {
      case ExamStatus.draft:
        return 'Draft';
      case ExamStatus.published:
        return 'Published';
      case ExamStatus.archived:
        return 'Archived';
    }
  }
}
