import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/paginated_list.dart';
import '../../../core/riverpod/paged_notifier.dart';
import '../../../core/riverpod/paged_state.dart';
import '../../auth/controllers/auth_controller.dart';
import '../data/models/question_model.dart';
import '../data/services/exam_api_service.dart';
import '../data/services/taxonomy_api_service.dart';

/// Browsing a subject's practice questions, keyed by subject name.
///
/// Not `autoDispose`: pages already loaded for a subject stay cached for the
/// rest of the app session; returning to the screen reuses them instead of
/// refetching from the start. Call `.notifier.refresh()` to force a reload.
class SubjectQuestionsNotifier extends PagedNotifier<QuestionModel> {
  SubjectQuestionsNotifier(this.subject);

  final String subject;

  @override
  Future<PaginatedList<QuestionModel>> fetchPage(int limit, int offset) {
    return ExamApiService(
      accountApi: ref.read(accountApiServiceProvider),
    ).getQuestionsBySubject(subject, limit: limit, offset: offset);
  }
}

final subjectQuestionsProvider =
    NotifierProvider.family<
      SubjectQuestionsNotifier,
      PagedState<QuestionModel>,
      String
    >(SubjectQuestionsNotifier.new);

/// Browsing one taxonomy node's question bank, keyed by (syllabusId, nodeId).
///
/// Not `autoDispose`, for the same reason as [SubjectQuestionsNotifier].
class TaxonomyQuestionsNotifier extends PagedNotifier<QuestionModel> {
  TaxonomyQuestionsNotifier(this.key);

  final (int syllabusId, int nodeId) key;

  @override
  Future<PaginatedList<QuestionModel>> fetchPage(int limit, int offset) {
    return TaxonomyApiService(
      accountApi: ref.read(accountApiServiceProvider),
    ).getQuestionBank(
      syllabusId: key.$1,
      nodeId: key.$2,
      limit: limit,
      offset: offset,
    );
  }
}

final taxonomyQuestionsProvider =
    NotifierProvider.family<
      TaxonomyQuestionsNotifier,
      PagedState<QuestionModel>,
      (int syllabusId, int nodeId)
    >(TaxonomyQuestionsNotifier.new);
