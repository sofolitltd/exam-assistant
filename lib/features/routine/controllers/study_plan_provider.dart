import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/controllers/auth_controller.dart';
import '../data/models/study_plan_model.dart';

/// The study plan for today. Recomputed on every open, so it follows the
/// learner's latest answers and routine.
final studyPlanProvider = FutureProvider.autoDispose<StudyPlan>((ref) async {
  final json = await ref
      .read(accountApiServiceProvider)
      .getApiJson('/v1/routine/plan');
  return StudyPlan.fromJson(json);
});

/// Saves the target exam date (`null` clears it, which falls back to the
/// next BCS) and refreshes the plan.
Future<void> saveTargetExam(
  WidgetRef ref,
  DateTime? date, {
  String? label,
}) async {
  String? iso;
  if (date != null) {
    iso =
        '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }
  await ref.read(accountApiServiceProvider).putApiJson('/v1/users/me/target', {
    'date': iso,
    'label': ?label,
  });
  ref.invalidate(studyPlanProvider);
}
