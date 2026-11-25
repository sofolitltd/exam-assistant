import '../../../core/models/paginated_list.dart';
import '../../auth/data/services/account_api_service.dart';
import 'learning_models.dart';
import 'practice_models.dart';

class LearningApiService {
  final AccountApiService _api;

  LearningApiService(this._api);

  Future<ExamLeaderboard> getExamLeaderboard(String examId) async {
    final json = await _api.getApiJson(
      '/v1/exams/${Uri.encodeComponent(examId)}/leaderboard',
    );
    return ExamLeaderboard.fromJson(Map<String, dynamic>.from(json as Map));
  }

  /// [mode] is `exam` or `practice` (null for both); [subjectId] is a
  /// syllabus subject node; [includeSkipped] false leaves out unanswered.
  Future<PaginatedList<MistakeQuestion>> getMistakes({
    String? examId,
    String? mode,
    int? subjectId,
    bool includeSkipped = true,
    int limit = 100,
    int offset = 0,
  }) async {
    final json = await _api.getApiJson(
      '/v1/users/me/mistakes',
      query: {
        'examId': ?examId,
        'mode': ?mode,
        if (subjectId != null) 'subjectId': '$subjectId',
        if (!includeSkipped) 'includeSkipped': 'false',
        'limit': '$limit',
        'offset': '$offset',
      },
    );
    return PaginatedList.fromJson(json, MistakeQuestion.fromJson);
  }

  Future<MistakeSummary> getMistakeSummary() async {
    return MistakeSummary.fromJson(
      await _api.getApiJson('/v1/users/me/mistakes/summary'),
    );
  }

  Future<({int sessionId, int saved})> recordPracticeAnswers({
    required int? sessionId,
    required PracticeTarget target,
    required List<Map<String, dynamic>> answers,
  }) async {
    final json = await _api.postApiJson('/v1/practice/answers', {
      if (sessionId != null)
        'sessionId': sessionId
      else ...{
        'source': target.source,
        'examId': ?target.examId,
        'label': target.label,
      },
      'answers': answers,
    });
    final m = json as Map;
    return (
      sessionId: (m['sessionId'] as num).toInt(),
      saved: (m['saved'] as num?)?.toInt() ?? 0,
    );
  }

  Future<PracticeSummary> getPracticeSummary() async {
    final now = DateTime.now();
    final today =
        '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
    return PracticeSummary.fromJson(
      await _api.getApiJson('/v1/practice/summary', query: {'today': today}),
    );
  }

  Future<Map<String, ExamPracticeProgress>> getExamPracticeProgress() async {
    final json = await _api.getApiJson('/v1/practice/exams');
    return {
      for (final item in _list(json, ExamPracticeProgress.fromJson))
        item.examId: item,
    };
  }

  Future<List<SubjectPerformance>> getSubjectPerformance({
    int days = 30,
    String? mode,
  }) async {
    final json = await _api.getApiJson(
      '/v1/users/me/subject-performance',
      query: {'days': '$days', 'mode': ?mode},
    );
    return _list(json, SubjectPerformance.fromJson);
  }

  Future<TopicInsights> getTopicInsights({int papers = 10}) async {
    final json = await _api.getApiJson(
      '/v1/insights/topics',
      query: {'papers': '$papers'},
    );
    return TopicInsights.fromJson(json);
  }

  Future<DueReviews> getDueReviews({int limit = 20}) async {
    final json = await _api.getApiJson(
      '/v1/review/due',
      query: {'limit': '$limit'},
    );
    return DueReviews.fromJson(json);
  }

  Future<ReviewAnswerResult> answerReview({
    required String questionId,
    required String selectedKey,
  }) async {
    final json = await _api.postApiJson('/v1/review/answers', {
      'questionId': questionId,
      'selectedKey': selectedKey,
    });
    return ReviewAnswerResult.fromJson(json);
  }

  Future<List<SubjectStrategy>> getStrategy({int days = 90}) async {
    final json = await _api.getApiJson(
      '/v1/insights/strategy',
      query: {'days': '$days'},
    );
    final items = (json as Map)['items'] as List? ?? const [];
    return [
      for (final item in items)
        SubjectStrategy.fromJson(Map<String, dynamic>.from(item as Map)),
    ];
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
