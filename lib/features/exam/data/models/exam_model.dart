import 'package:cloud_firestore/cloud_firestore.dart';

enum ExamStatus { draft, published, archived }

class ExamModel {
  final String examId;
  final String title;
  final int durationSeconds;
  final double negativeMarks;
  final ExamStatus status;
  final DateTime? scheduledDate;
  final DateTime createdAt;

  ExamModel({
    required this.examId,
    required this.title,
    required this.durationSeconds,
    required this.negativeMarks,
    this.status = ExamStatus.draft,
    this.scheduledDate,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory ExamModel.fromMap(Map<String, dynamic> map, String id) {
    return ExamModel(
      examId: id,
      title: map['title'] ?? '',
      durationSeconds: map['durationSeconds'] ?? 0,
      negativeMarks: (map['negativeMarks'] ?? 0.0).toDouble(),
      status: map['status'] != null
          ? ExamStatus.values.firstWhere(
              (e) => e.name == map['status'],
              orElse: () => ExamStatus.draft,
            )
          : ExamStatus.draft,
      scheduledDate: (map['scheduledDate'] as dynamic)?.toDate(),
      createdAt: (map['createdAt'] as dynamic)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'durationSeconds': durationSeconds,
      'negativeMarks': negativeMarks,
      'status': status.name,
      if (scheduledDate != null) 'scheduledDate': Timestamp.fromDate(scheduledDate!),
      'createdAt': createdAt,
    };
  }

  bool get isPublished => status == ExamStatus.published;
  bool get isDraft => status == ExamStatus.draft;
  bool get isArchived => status == ExamStatus.archived;
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
