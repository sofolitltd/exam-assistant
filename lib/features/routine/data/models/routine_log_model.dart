enum RoutineLogStatus { done, partial, missed }

/// One block's recorded outcome for a given day.
class RoutineLogEntry {
  final int blockId;
  final RoutineLogStatus status;

  const RoutineLogEntry({required this.blockId, required this.status});

  factory RoutineLogEntry.fromMap(Map<String, dynamic> map) {
    return RoutineLogEntry(
      blockId: (map['blockId'] as num).toInt(),
      status: RoutineLogStatus.values.firstWhere(
        (s) => s.name == map['status'],
        orElse: () => RoutineLogStatus.missed,
      ),
    );
  }

  Map<String, dynamic> toMap() => {'blockId': blockId, 'status': status.name};
}

/// All logged entries for a single calendar date ("YYYY-MM-DD").
class RoutineDailyLog {
  final String date;
  final List<RoutineLogEntry> entries;

  const RoutineDailyLog({required this.date, required this.entries});

  factory RoutineDailyLog.fromMap(Map<String, dynamic> map) {
    return RoutineDailyLog(
      date: map['date'] as String? ?? '',
      entries:
          (map['entries'] as List<dynamic>?)
              ?.map(
                (e) => RoutineLogEntry.fromMap(
                  Map<String, dynamic>.from(e as Map),
                ),
              )
              .toList() ??
          const [],
    );
  }

  RoutineLogStatus? statusFor(int blockId) {
    for (final entry in entries) {
      if (entry.blockId == blockId) return entry.status;
    }
    return null;
  }
}
