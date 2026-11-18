enum RoutineBlockCategory { study, prayer, meal, rest, other }

extension RoutineBlockCategoryX on RoutineBlockCategory {
  String get label {
    switch (this) {
      case RoutineBlockCategory.study:
        return 'পড়াশোনা';
      case RoutineBlockCategory.prayer:
        return 'নামাজ';
      case RoutineBlockCategory.meal:
        return 'খাবার';
      case RoutineBlockCategory.rest:
        return 'বিশ্রাম';
      case RoutineBlockCategory.other:
        return 'অন্যান্য';
    }
  }
}

/// A single time-boxed entry in a routine, e.g. "Math practice, 06:00-07:30".
class RoutineBlockModel {
  final int? id;
  final String title;
  final RoutineBlockCategory category;
  final String startTime; // "HH:MM", 24-hour
  final String endTime; // "HH:MM", 24-hour
  final List<int> daysOfWeek; // 1 (Monday) .. 7 (Sunday)
  final int sortOrder;

  /// Optional syllabus subject this block studies, so the weekly summary
  /// can set routine adherence beside exam accuracy on that subject.
  final int? syllabusNodeId;
  final String? subjectName;

  const RoutineBlockModel({
    this.id,
    required this.title,
    required this.category,
    required this.startTime,
    required this.endTime,
    required this.daysOfWeek,
    this.sortOrder = 0,
    this.syllabusNodeId,
    this.subjectName,
  });

  factory RoutineBlockModel.fromMap(Map<String, dynamic> map) {
    return RoutineBlockModel(
      id: (map['id'] as num?)?.toInt(),
      title: map['title'] as String? ?? '',
      category: RoutineBlockCategory.values.firstWhere(
        (c) => c.name == map['category'],
        orElse: () => RoutineBlockCategory.other,
      ),
      startTime: map['startTime'] as String? ?? '00:00',
      endTime: map['endTime'] as String? ?? '00:00',
      daysOfWeek:
          (map['daysOfWeek'] as List<dynamic>?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          const [1, 2, 3, 4, 5, 6, 7],
      sortOrder: (map['sortOrder'] as num?)?.toInt() ?? 0,
      syllabusNodeId: (map['syllabusNodeId'] as num?)?.toInt(),
      subjectName: map['subjectName'] as String?,
    );
  }

  /// `id` is sent so the server updates the block in place, which keeps its
  /// check-in history; blocks cloned from a template must drop it first
  /// (see [withoutId]).
  Map<String, dynamic> toMap() {
    return {
      'id': ?id,
      'title': title,
      'category': category.name,
      'startTime': startTime,
      'endTime': endTime,
      'daysOfWeek': daysOfWeek,
      'sortOrder': sortOrder,
      'syllabusNodeId': ?syllabusNodeId,
    };
  }

  RoutineBlockModel copyWith({int? sortOrder}) {
    return RoutineBlockModel(
      id: id,
      title: title,
      category: category,
      startTime: startTime,
      endTime: endTime,
      daysOfWeek: daysOfWeek,
      sortOrder: sortOrder ?? this.sortOrder,
      syllabusNodeId: syllabusNodeId,
      subjectName: subjectName,
    );
  }

  /// A template block's id belongs to the template table, not the user's
  /// routine, so it must not be sent as an existing block id.
  RoutineBlockModel withoutId() {
    return RoutineBlockModel(
      title: title,
      category: category,
      startTime: startTime,
      endTime: endTime,
      daysOfWeek: daysOfWeek,
      sortOrder: sortOrder,
      syllabusNodeId: syllabusNodeId,
      subjectName: subjectName,
    );
  }

  bool appliesOn(DateTime date) => daysOfWeek.contains(date.weekday);
}
