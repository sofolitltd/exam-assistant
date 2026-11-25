import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/paginated_list.dart';
import '../../../core/riverpod/paged_notifier.dart';
import '../../../core/riverpod/paged_state.dart';
import '../../auth/controllers/auth_controller.dart';
import '../data/learning_api_service.dart';
import '../data/learning_models.dart';
import '../data/practice_models.dart';
import '../data/practice_recorder.dart';

final learningApiServiceProvider = Provider<LearningApiService>((ref) {
  return LearningApiService(ref.watch(accountApiServiceProvider));
});

final examLeaderboardProvider = FutureProvider.autoDispose
    .family<ExamLeaderboard, String>((ref, examId) {
      return ref.read(learningApiServiceProvider).getExamLeaderboard(examId);
    });

/// Mistakes across all exams when [examId] is null, or one exam's.
///
/// Not `autoDispose`: pages already loaded for a given [examId] stay cached
/// in memory for the rest of the app session, so returning to the mistakes
/// screen doesn't refetch from the start. Call `.notifier.refresh()` (e.g.
/// on pull-to-refresh) to force a reload.
class MistakesNotifier extends PagedNotifier<MistakeQuestion> {
  MistakesNotifier(this.examId);

  final String? examId;

  @override
  Future<PaginatedList<MistakeQuestion>> fetchPage(int limit, int offset) {
    return ref
        .read(learningApiServiceProvider)
        .getMistakes(examId: examId, limit: limit, offset: offset);
  }
}

final mistakesProvider =
    NotifierProvider.family<
      MistakesNotifier,
      PagedState<MistakeQuestion>,
      String?
    >(MistakesNotifier.new);

/// Which mistakes to show: where they were made and in which subject.
typedef MistakeFilter = ({String? examId, String? mode, int? subjectId});

/// Wrong answers (not skips) for the আমার ভুল screen, filtered.
class FilteredMistakesNotifier extends PagedNotifier<MistakeQuestion> {
  FilteredMistakesNotifier(this.filter);

  final MistakeFilter filter;

  @override
  Future<PaginatedList<MistakeQuestion>> fetchPage(int limit, int offset) {
    return ref
        .read(learningApiServiceProvider)
        .getMistakes(
          examId: filter.examId,
          mode: filter.mode,
          subjectId: filter.subjectId,
          includeSkipped: false,
          limit: limit,
          offset: offset,
        );
  }
}

final filteredMistakesProvider =
    NotifierProvider.family<
      FilteredMistakesNotifier,
      PagedState<MistakeQuestion>,
      MistakeFilter
    >(FilteredMistakesNotifier.new);

final mistakeSummaryProvider = FutureProvider.autoDispose<MistakeSummary>((
  ref,
) {
  return ref.read(learningApiServiceProvider).getMistakeSummary();
});

final practiceSummaryProvider = FutureProvider.autoDispose<PracticeSummary>((
  ref,
) {
  return ref.read(learningApiServiceProvider).getPracticeSummary();
});

/// Practice progress per paper, keyed by exam id.
final examPracticeProgressProvider =
    FutureProvider.autoDispose<Map<String, ExamPracticeProgress>>((ref) {
      return ref.read(learningApiServiceProvider).getExamPracticeProgress();
    });

/// Subject accuracy over the last [days] days for one [mode]
/// (`exam`, `practice`, or null for both).
final subjectPerformanceByModeProvider = FutureProvider.autoDispose
    .family<List<SubjectPerformance>, ({int days, String? mode})>((ref, key) {
      return ref
          .read(learningApiServiceProvider)
          .getSubjectPerformance(days: key.days, mode: key.mode);
    });

final subjectPerformanceProvider =
    FutureProvider.autoDispose<List<SubjectPerformance>>((ref) {
      return ref.read(learningApiServiceProvider).getSubjectPerformance();
    });

/// Subject accuracy over the last [days] days (use a large number for
/// "all time"), as returned by the API.
final subjectPerformanceByDaysProvider = FutureProvider.autoDispose
    .family<List<SubjectPerformance>, int>((ref, days) {
      return ref
          .read(learningApiServiceProvider)
          .getSubjectPerformance(days: days);
    });

/// Topics ranked by "study first" over the last [papers] general papers.
final topicInsightsProvider = FutureProvider.autoDispose
    .family<TopicInsights, int>((ref, papers) {
      return ref
          .read(learningApiServiceProvider)
          .getTopicInsights(papers: papers);
    });

/// Wrong answers that are due for spaced review today, plus box counts.
final dueReviewsProvider = FutureProvider.autoDispose<DueReviews>((ref) {
  return ref.read(learningApiServiceProvider).getDueReviews();
});

/// Per-subject negative-marking strategy over the last 90 days.
final strategyProvider = FutureProvider.autoDispose<List<SubjectStrategy>>((
  ref,
) {
  return ref.read(learningApiServiceProvider).getStrategy();
});

/// Reloads everything that answers feed: mistakes, review, stats, insights.
/// Call after practice, review or an exam is saved. Takes the container so
/// it also works after the calling widget is gone
/// (`ProviderScope.containerOf(context)`).
void refreshLearningData(ProviderContainer c) {
  c.invalidate(mistakesProvider);
  c.invalidate(filteredMistakesProvider);
  c.invalidate(mistakeSummaryProvider);
  c.invalidate(practiceSummaryProvider);
  c.invalidate(examPracticeProgressProvider);
  c.invalidate(dueReviewsProvider);
  c.invalidate(subjectPerformanceProvider);
  c.invalidate(subjectPerformanceByDaysProvider);
  c.invalidate(subjectPerformanceByModeProvider);
  c.invalidate(topicInsightsProvider);
}

final practiceRecorderFactoryProvider =
    Provider<PracticeRecorder Function(PracticeTarget)>((ref) {
      final api = ref.watch(learningApiServiceProvider);
      return (target) => PracticeRecorder(api, target);
    });
