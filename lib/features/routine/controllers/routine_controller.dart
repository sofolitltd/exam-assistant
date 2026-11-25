import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../auth/controllers/auth_controller.dart';
import '../data/models/routine_block_model.dart';
import '../data/models/routine_log_model.dart';
import '../data/models/routine_template_model.dart';
import '../data/models/streak_models.dart';
import '../data/models/user_routine_model.dart';
import '../data/models/weekly_summary_model.dart';
import '../data/services/routine_api_service.dart';
import '../services/routine_notification_service.dart';

part 'routine_controller.g.dart';

final routineApiServiceProvider = Provider<RoutineApiService>((ref) {
  return RoutineApiService(accountApi: ref.watch(accountApiServiceProvider));
});

final routineNotificationServiceProvider = Provider<RoutineNotificationService>(
  (ref) {
    return RoutineNotificationService();
  },
);

/// The signed-in user's routine, or null if they haven't set one up yet.
final myRoutineProvider = FutureProvider<UserRoutineModel?>((ref) async {
  final user = ref.watch(authStateChangesProvider).value;
  if (user == null) return null;
  return ref.read(routineApiServiceProvider).getMyRoutine();
});

final routineTemplatesProvider = FutureProvider<List<RoutineTemplateModel>>((
  ref,
) async {
  return ref.read(routineApiServiceProvider).getTemplates();
});

String formatLogDate(DateTime date) {
  return '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}

DateTime mostRecentMonday(DateTime date) {
  final d = DateTime(date.year, date.month, date.day);
  return d.subtract(Duration(days: d.weekday - 1));
}

final todayLogProvider = FutureProvider.autoDispose<RoutineDailyLog>((
  ref,
) async {
  final date = formatLogDate(DateTime.now());
  return ref.read(routineApiServiceProvider).getDailyLog(date);
});

final weeklySummaryProvider = FutureProvider.autoDispose
    .family<WeeklySummaryModel, DateTime>((ref, weekStart) async {
      return ref
          .read(routineApiServiceProvider)
          .getWeeklySummary(formatLogDate(weekStart));
    });

final streakProvider = FutureProvider.autoDispose<StreakInfo>((ref) {
  return ref
      .read(routineApiServiceProvider)
      .getStreak(formatLogDate(DateTime.now()));
});

final studyGroupsProvider = FutureProvider.autoDispose<List<StudyGroup>>((ref) {
  return ref.read(routineApiServiceProvider).getStudyGroups();
});

final studyGroupDetailProvider = FutureProvider.autoDispose
    .family<StudyGroupDetail, int>((ref, groupId) {
      return ref
          .read(routineApiServiceProvider)
          .getStudyGroup(groupId, formatLogDate(DateTime.now()));
    });

@Riverpod(keepAlive: true)
class RoutineController extends _$RoutineController {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  Future<void> saveRoutine({
    required String title,
    String? sourceTemplateId,
    required List<RoutineBlockModel> blocks,
  }) async {
    state = const AsyncValue.loading();
    try {
      await ref
          .read(routineApiServiceProvider)
          .saveMyRoutine(
            title: title,
            sourceTemplateId: sourceTemplateId,
            blocks: blocks,
          );
      await ref
          .read(routineNotificationServiceProvider)
          .scheduleRoutineReminders();
      ref.invalidate(myRoutineProvider);
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  Future<void> submitDailyLog({
    required String date,
    required List<RoutineLogEntry> entries,
  }) async {
    state = const AsyncValue.loading();
    try {
      await ref
          .read(routineApiServiceProvider)
          .saveDailyLog(date: date, entries: entries);
      ref.invalidate(todayLogProvider);
      ref.invalidate(streakProvider);
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }
}
