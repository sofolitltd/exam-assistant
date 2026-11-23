import '../../../../core/models/paginated_list.dart';
import '../../../auth/data/services/account_api_service.dart';
import '../models/exam_model.dart';
import '../models/exam_stats_model.dart';
import '../models/question_model.dart';

class ExamApiService {
  final AccountApiService _accountApi;

  ExamApiService({required this._accountApi});

  Future<List<ExamModel>> getExams({bool publishedOnly = false}) async {
    final response = await _accountApi.getApiJson(
      '/v1/exams',
      query: {'publishedOnly': '$publishedOnly'},
    );
    if (response is! List) {
      throw const FormatException('Expected an exams list response.');
    }
    return response.map((item) {
      final data = Map<String, dynamic>.from(item as Map);
      return ExamModel.fromMap(data, data['examId'] as String? ?? '');
    }).toList();
  }

  Future<List<ExamModel>> getRecentExams(
    int limit, {
    bool publishedOnly = false,
  }) async {
    final exams = await getExams(publishedOnly: publishedOnly);
    return exams.take(limit).toList();
  }

  Future<ExamModel?> getExam(String examId) async {
    final response = await _accountApi.getApiJson(
      '/v1/exams/${Uri.encodeComponent(examId)}',
    );
    if (response == null) return null;
    final data = Map<String, dynamic>.from(response as Map);
    return ExamModel.fromMap(data, data['examId'] as String? ?? examId);
  }

  Future<List<QuestionModel>> getExamQuestions(String examId) async {
    final response = await _accountApi.getApiJson(
      '/v1/exams/${Uri.encodeComponent(examId)}/questions',
    );
    return _questions(response);
  }

  /// Full review copy of an exam's questions, with correct answers and
  /// explanations included. The API only returns this once the exam's
  /// scheduled sitting window has closed.
  Future<List<QuestionModel>> getExamAnswerKey(String examId) async {
    final response = await _accountApi.getApiJson(
      '/v1/exams/${Uri.encodeComponent(examId)}/answer-key',
    );
    return _questions(response);
  }

  /// Everyone's average score and the hardest questions, once the exam's
  /// scheduled sitting window has closed.
  Future<ExamStats> getExamStats(String examId) async {
    final response = await _accountApi.getApiJson(
      '/v1/exams/${Uri.encodeComponent(examId)}/stats',
    );
    return ExamStats.fromMap(Map<String, dynamic>.from(response as Map));
  }

  Future<int> getExamQuestionCount(String examId) async {
    final exam = await getExam(examId);
    return exam?.questionCount ?? 0;
  }

  Future<PaginatedList<QuestionModel>> getQuestionsBySubject(
    String subject, {
    int limit = 50,
    int offset = 0,
  }) async {
    final response = await _accountApi.getApiJson(
      '/v1/questions',
      query: {'subject': subject, 'limit': '$limit', 'offset': '$offset'},
    );
    return PaginatedList.fromJson(
      response,
      (item) => QuestionModel.fromMap(item, item['id'] as String? ?? ''),
    );
  }

  List<QuestionModel> _questions(dynamic response) {
    if (response is! List) {
      throw const FormatException('Expected a questions list response.');
    }
    return response.map((item) {
      final data = Map<String, dynamic>.from(item as Map);
      return QuestionModel.fromMap(data, data['id'] as String? ?? '');
    }).toList();
  }
}
