import '../../../auth/data/services/account_api_service.dart';
import '../models/routine_block_model.dart';
import '../models/routine_log_model.dart';
import '../models/routine_template_model.dart';
import '../models/streak_models.dart';
import '../models/user_routine_model.dart';
import '../models/weekly_summary_model.dart';

class RoutineApiService {
  final AccountApiService _accountApi;

  RoutineApiService({required AccountApiService accountApi})
    : _accountApi = accountApi;

  Future<List<RoutineTemplateModel>> getTemplates() async {
    final response = await _accountApi.getApiJson('/v1/routine-templates');
    if (response is! List) {
      throw const FormatException(
        'Expected a routine templates list response.',
      );
    }
    return response
        .map(
          (e) =>
              RoutineTemplateModel.fromMap(Map<String, dynamic>.from(e as Map)),
        )
        .toList();
  }

  Future<RoutineTemplateModel> getTemplate(String templateId) async {
    final response = await _accountApi.getApiJson(
      '/v1/routine-templates/${Uri.encodeComponent(templateId)}',
    );
    return RoutineTemplateModel.fromMap(
      Map<String, dynamic>.from(response as Map),
    );
  }

  /// Returns null when the user has not set up a routine yet.
  Future<UserRoutineModel?> getMyRoutine() async {
    try {
      final response = await _accountApi.getApiJson('/v1/routine');
      return UserRoutineModel.fromMap(
        Map<String, dynamic>.from(response as Map),
      );
    } on ApiException catch (error) {
      if (error.statusCode == 404) return null;
      rethrow;
    }
  }

  Future<UserRoutineModel> saveMyRoutine({
    required String title,
    String? sourceTemplateId,
    required List<RoutineBlockModel> blocks,
  }) async {
    final response = await _accountApi.putApiJson('/v1/routine', {
      'title': title,
      'sourceTemplateId': sourceTemplateId,
      'blocks': blocks.map((b) => b.toMap()).toList(),
    });
    return UserRoutineModel.fromMap(Map<String, dynamic>.from(response as Map));
  }

  Future<RoutineDailyLog> getDailyLog(String date) async {
    final response = await _accountApi.getApiJson(
      '/v1/routine/logs',
      query: {'date': date},
    );
    return RoutineDailyLog.fromMap(Map<String, dynamic>.from(response as Map));
  }

  Future<RoutineDailyLog> saveDailyLog({
    required String date,
    required List<RoutineLogEntry> entries,
  }) async {
    final response = await _accountApi.postApiJson('/v1/routine/logs', {
      'date': date,
      'entries': entries.map((e) => e.toMap()).toList(),
    });
    return RoutineDailyLog.fromMap(Map<String, dynamic>.from(response as Map));
  }

  Future<WeeklySummaryModel> getWeeklySummary(String weekStartDate) async {
    final response = await _accountApi.getApiJson(
      '/v1/routine/summary',
      query: {'weekStart': weekStartDate},
    );
    return WeeklySummaryModel.fromMap(
      Map<String, dynamic>.from(response as Map),
    );
  }

  /// [today] is the device's local date, matching how check-ins are dated.
  Future<StreakInfo> getStreak(String today) async {
    final response = await _accountApi.getApiJson(
      '/v1/routine/streak',
      query: {'today': today},
    );
    return StreakInfo.fromMap(Map<String, dynamic>.from(response as Map));
  }

  Future<List<StudyGroup>> getStudyGroups() async {
    return _groups(await _accountApi.getApiJson('/v1/study-groups'));
  }

  Future<StudyGroup> createStudyGroup(String name) async {
    final response = await _accountApi.postApiJson('/v1/study-groups', {
      'name': name,
    });
    return StudyGroup.fromMap(Map<String, dynamic>.from(response as Map));
  }

  /// Returns the caller's groups after joining.
  Future<List<StudyGroup>> joinStudyGroup(String inviteCode) async {
    return _groups(
      await _accountApi.postApiJson('/v1/study-groups/join', {
        'inviteCode': inviteCode,
      }),
    );
  }

  Future<StudyGroupDetail> getStudyGroup(int groupId, String today) async {
    final response = await _accountApi.getApiJson(
      '/v1/study-groups/$groupId',
      query: {'today': today},
    );
    return StudyGroupDetail.fromMap(Map<String, dynamic>.from(response as Map));
  }

  Future<void> leaveStudyGroup(int groupId) async {
    await _accountApi.deleteApiJson('/v1/study-groups/$groupId/membership');
  }

  List<StudyGroup> _groups(dynamic response) {
    if (response is! List) {
      throw const FormatException('Expected a study groups list response.');
    }
    return [
      for (final item in response)
        StudyGroup.fromMap(Map<String, dynamic>.from(item as Map)),
    ];
  }
}
