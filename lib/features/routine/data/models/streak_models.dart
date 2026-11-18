/// A day counts toward the streak when at least half of that day's checked-in
/// blocks were done (partial counts as half). An unfinished today doesn't
/// break it — the streak counts back from yesterday until today is logged.
class StreakInfo {
  final int current;
  final int best;
  final bool todayCounted;

  /// Oldest first, ending today. `rate` is null for days with no check-in.
  final List<({String date, double? rate})> lastSevenDays;

  const StreakInfo({
    required this.current,
    required this.best,
    required this.todayCounted,
    required this.lastSevenDays,
  });

  factory StreakInfo.fromMap(Map<String, dynamic> map) => StreakInfo(
    current: (map['current'] as num? ?? 0).toInt(),
    best: (map['best'] as num? ?? 0).toInt(),
    todayCounted: map['todayCounted'] as bool? ?? false,
    lastSevenDays: [
      for (final day in map['lastSevenDays'] as List? ?? const [])
        (
          date: (day as Map)['date'] as String? ?? '',
          rate: (day['rate'] as num?)?.toDouble(),
        ),
    ],
  );
}

class StudyGroup {
  final int groupId;
  final String name;
  final String inviteCode;
  final int memberCount;
  final bool isOwner;

  const StudyGroup({
    required this.groupId,
    required this.name,
    required this.inviteCode,
    required this.memberCount,
    required this.isOwner,
  });

  factory StudyGroup.fromMap(Map<String, dynamic> map) => StudyGroup(
    groupId: (map['groupId'] as num).toInt(),
    name: map['name'] as String? ?? '',
    inviteCode: map['inviteCode'] as String? ?? '',
    memberCount: (map['memberCount'] as num? ?? 0).toInt(),
    isOwner: map['isOwner'] as bool? ?? false,
  );
}

class StudyGroupMember {
  final String name;
  final bool isYou;
  final int currentStreak;
  final double weekAdherence;
  final bool checkedInToday;

  const StudyGroupMember({
    required this.name,
    required this.isYou,
    required this.currentStreak,
    required this.weekAdherence,
    required this.checkedInToday,
  });

  factory StudyGroupMember.fromMap(Map<String, dynamic> map) =>
      StudyGroupMember(
        name: map['name'] as String? ?? '',
        isYou: map['isYou'] as bool? ?? false,
        currentStreak: (map['currentStreak'] as num? ?? 0).toInt(),
        weekAdherence: (map['weekAdherence'] as num? ?? 0).toDouble(),
        checkedInToday: map['checkedInToday'] as bool? ?? false,
      );
}

class StudyGroupDetail {
  final StudyGroup group;
  final List<StudyGroupMember> members;

  const StudyGroupDetail({required this.group, required this.members});

  factory StudyGroupDetail.fromMap(Map<String, dynamic> map) =>
      StudyGroupDetail(
        group: StudyGroup.fromMap(
          Map<String, dynamic>.from(map['group'] as Map),
        ),
        members: [
          for (final member in map['members'] as List? ?? const [])
            StudyGroupMember.fromMap(Map<String, dynamic>.from(member as Map)),
        ],
      );
}
