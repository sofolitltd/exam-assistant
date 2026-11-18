import '../../../core/models/paginated_list.dart';
import '../../auth/data/services/account_api_service.dart';
import 'learning_models.dart';

class LearningApiService {
  final AccountApiService _api;

  LearningApiService(this._api);

  Future<ExamLeaderboard> getExamLeaderboard(String examId) async {
    final json = await _api.getApiJson(
      '/v1/exams/${Uri.encodeComponent(examId)}/leaderboard',
    );
    return ExamLeaderboard.fromJson(Map<String, dynamic>.from(json as Map));
  }

  Future<PaginatedList<MistakeQuestion>> getMistakes({
    String? examId,
    int limit = 100,
    int offset = 0,
  }) async {
    final json = await _api.getApiJson(
      '/v1/users/me/mistakes',
      query: {'examId': ?examId, 'limit': '$limit', 'offset': '$offset'},
    );
    return PaginatedList.fromJson(json, MistakeQuestion.fromJson);
  }

  Future<List<SubjectPerformance>> getSubjectPerformance({
    int days = 30,
  }) async {
    final json = await _api.getApiJson(
      '/v1/users/me/subject-performance',
      query: {'days': '$days'},
    );
    return _list(json, SubjectPerformance.fromJson);
  }

  List<T> _list<T>(dynamic json, T Function(Map<String, dynamic>) parse) {
    if (json is! List) {
      throw const FormatException('Expected a list response.');
    }
    return json
        .map((item) => parse(Map<String, dynamic>.from(item as Map)))
        .toList();
  }
}
