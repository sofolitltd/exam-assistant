import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../core/utils/bangla_digits.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../bcs/views/bcs_format.dart';
import '../../routine/controllers/study_plan_provider.dart';

/// The exams a learner is preparing for ("আমার লক্ষ্য"), from
/// `/v1/users/me/goals`. Up to [maxGoals], one of them primary. The primary
/// goal drives the daily plan and the profile. Skill is counted per topic on
/// the server, so practice for one goal also counts for the others.
const maxGoals = 3;

/// An exam the learner can pick as a goal (admin console → exam programs).
class GoalProgram {
  final String code;
  final String label;

  /// False while the exam has no published questions yet.
  final bool hasQuestions;

  const GoalProgram({
    required this.code,
    required this.label,
    required this.hasQuestions,
  });

  bool get isBcs => code == 'BCS';

  factory GoalProgram.fromJson(Map<String, dynamic> json) => GoalProgram(
    code: json['code'] as String? ?? '',
    label: json['label'] as String? ?? '',
    hasQuestions: json['hasQuestions'] as bool? ?? false,
  );
}

class GoalEdition {
  final int number;

  /// general or special.
  final String kind;
  final String? specialLabel;

  const GoalEdition({
    required this.number,
    required this.kind,
    required this.specialLabel,
  });

  /// "৫০তম বিসিএস" or "৫১তম বিশেষ (স্বাস্থ্য) বিসিএস".
  String get name => kind == 'special'
      ? '${bnOrdinal(number)} বিশেষ'
            '${specialLabel == null ? '' : ' ($specialLabel)'} বিসিএস'
      : editionName(number);
}

class UserGoal {
  final int id;
  final String programCode;
  final String programLabel;

  /// BCS only: general or special.
  final String? variant;

  /// BCS only: the sitting the learner chose (null: the next one).
  final int? editionNumber;

  /// The sitting this goal counts down to, chosen or next.
  final GoalEdition? edition;

  /// The learner's own date, if they gave one.
  final DateTime? examDate;

  /// The date in effect.
  final DateTime? targetDate;

  /// user, edition, next_bcs or none.
  final String dateSource;
  final int? daysLeft;
  final bool isPrimary;
  final bool hasQuestions;

  const UserGoal({
    required this.id,
    required this.programCode,
    required this.programLabel,
    required this.variant,
    required this.editionNumber,
    required this.edition,
    required this.examDate,
    required this.targetDate,
    required this.dateSource,
    required this.daysLeft,
    required this.isPrimary,
    required this.hasQuestions,
  });

  bool get isBcs => programCode == 'BCS';
  bool get isSpecialBcs => isBcs && variant == 'special';

  /// What the profile shows: "৫০তম বিসিএস প্রিলিমিনারি", "বিশেষ বিসিএস",
  /// "ব্যাংক নিয়োগ".
  String get title {
    if (!isBcs) return programLabel;
    final e = edition;
    if (e != null && (editionNumber != null || dateSource == 'next_bcs')) {
      return e.kind == 'special' ? e.name : '${e.name} প্রিলিমিনারি';
    }
    return isSpecialBcs ? 'বিশেষ বিসিএস' : 'বিসিএস';
  }

  /// Short name for a chip: "বিসিএস", "বিশেষ বিসিএস", "ব্যাংক নিয়োগ".
  String get shortTitle =>
      isBcs ? (isSpecialBcs ? 'বিশেষ বিসিএস' : 'বিসিএস') : programLabel;

  /// "১১ ডিসেম্বর ২০২৬ · আর ১৭ দিন".
  String get detail {
    final date = targetDate;
    if (date == null || daysLeft == null) return 'তারিখ ঠিক করা নেই';
    final guess = dateSource == 'next_bcs' ? ' (পরের বিসিএস ধরা হয়েছে)' : '';
    return '${bnDate(date)} · আর ${bn(daysLeft!)} দিন$guess';
  }

  factory UserGoal.fromJson(Map<String, dynamic> json) {
    final edition = json['edition'];
    return UserGoal(
      id: (json['goalId'] as num).toInt(),
      programCode: json['programCode'] as String? ?? '',
      programLabel: json['programLabel'] as String? ?? '',
      variant: json['variant'] as String?,
      editionNumber: (json['editionNumber'] as num?)?.toInt(),
      edition: edition is Map
          ? GoalEdition(
              number: (edition['number'] as num).toInt(),
              kind: edition['kind'] as String? ?? 'general',
              specialLabel: edition['specialLabel'] as String?,
            )
          : null,
      examDate: DateTime.tryParse(json['examDate'] as String? ?? ''),
      targetDate: DateTime.tryParse(json['targetDate'] as String? ?? ''),
      dateSource: json['dateSource'] as String? ?? 'none',
      daysLeft: (json['daysLeft'] as num?)?.toInt(),
      isPrimary: json['isPrimary'] as bool? ?? false,
      hasQuestions: json['hasQuestions'] as bool? ?? false,
    );
  }
}

String? _isoDate(DateTime? date) => date == null
    ? null
    : '${date.year.toString().padLeft(4, '0')}-'
          '${date.month.toString().padLeft(2, '0')}-'
          '${date.day.toString().padLeft(2, '0')}';

final goalProgramsProvider = FutureProvider.autoDispose<List<GoalProgram>>((
  ref,
) async {
  final json = await ref
      .read(accountApiServiceProvider)
      .getApiJson('/v1/goal-programs');
  if (json is! List) {
    throw const FormatException('Expected a goal program list.');
  }
  return [
    for (final item in json)
      if (item is Map) GoalProgram.fromJson(Map<String, dynamic>.from(item)),
  ];
});

class GoalsNotifier extends AsyncNotifier<List<UserGoal>> {
  /// Where builds before goals kept the sign-up choice (bcs, bank, ntrca,
  /// primary). Moved to the account once, then deleted.
  static const _legacyKey = 'exam_assistant_target_exam';
  static const _storage = FlutterSecureStorage();

  @override
  Future<List<UserGoal>> build() async {
    final goals = await _fetch();
    if (goals.isNotEmpty) return goals;
    return await _moveLegacyChoice() ?? goals;
  }

  Future<List<UserGoal>> _fetch() async => _parse(
    await ref.read(accountApiServiceProvider).getApiJson('/v1/users/me/goals'),
  );

  List<UserGoal> _parse(dynamic json) {
    if (json is! List) throw const FormatException('Expected a goal list.');
    return [
      for (final item in json)
        if (item is Map) UserGoal.fromJson(Map<String, dynamic>.from(item)),
    ];
  }

  Future<List<UserGoal>?> _moveLegacyChoice() async {
    try {
      final legacy = await _storage.read(key: _legacyKey);
      if (legacy == null || legacy.isEmpty) return null;
      final json = await ref.read(accountApiServiceProvider).postApiJson(
        '/v1/users/me/goals',
        {'programCode': legacy.toUpperCase()},
      );
      await _storage.delete(key: _legacyKey);
      return _parse(json);
    } catch (_) {
      // Unknown code or offline: drop it rather than retry forever.
      try {
        await _storage.delete(key: _legacyKey);
      } catch (_) {}
      return null;
    }
  }

  Future<void> _apply(Future<dynamic> Function() call) async {
    final goals = _parse(await call());
    state = AsyncData(goals);
    ref.invalidate(studyPlanProvider);
  }

  Future<void> add(
    String programCode, {
    String? variant,
    int? editionNumber,
    DateTime? examDate,
    bool primary = false,
  }) => _apply(
    () =>
        ref.read(accountApiServiceProvider).postApiJson('/v1/users/me/goals', {
          'programCode': programCode,
          'variant': ?variant,
          'editionNumber': ?editionNumber,
          'examDate': ?_isoDate(examDate),
          'primary': primary,
        }),
  );

  /// Replaces the goal's variant, sitting and date.
  Future<void> edit(
    int goalId, {
    String? variant,
    int? editionNumber,
    DateTime? examDate,
  }) => _apply(
    () => ref
        .read(accountApiServiceProvider)
        .putApiJson('/v1/users/me/goals/$goalId', {
          'variant': ?variant,
          'editionNumber': ?editionNumber,
          'examDate': ?_isoDate(examDate),
        }),
  );

  Future<void> makePrimary(int goalId) => _apply(
    () => ref
        .read(accountApiServiceProvider)
        .putApiJson('/v1/users/me/goals/$goalId/primary', const {}),
  );

  Future<void> remove(int goalId) => _apply(
    () => ref
        .read(accountApiServiceProvider)
        .deleteApiJson('/v1/users/me/goals/$goalId'),
  );
}

final goalsProvider =
    AsyncNotifierProvider.autoDispose<GoalsNotifier, List<UserGoal>>(
      GoalsNotifier.new,
    );
