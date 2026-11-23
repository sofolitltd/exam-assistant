import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/bangla_digits.dart';
import '../../../core/widgets/ds.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../bcs/views/bcs_format.dart';
import '../../exam/data/models/exam_result_model.dart';
import '../../exam/data/services/exam_api_service.dart';
import '../controllers/stats_controller.dart';

/// exam id → title, for naming rows in the history.
final _examTitlesProvider = FutureProvider.autoDispose<Map<String, String>>((
  ref,
) async {
  final service = ExamApiService(
    accountApi: ref.watch(accountApiServiceProvider),
  );
  final exams = await service.getExams(publishedOnly: true);
  return {for (final e in exams) e.examId: e.title};
});

/// আমার ফল: every exam the learner has sat, newest first.
class ResultsHistoryScreen extends ConsumerWidget {
  const ResultsHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final results = ref.watch(userExamResultsProvider);
    final titles = ref.watch(_examTitlesProvider).value ?? const {};

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: const DsHeader(title: 'আমার ফল'),
      body: results.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'ফল লোড করা যায়নি। ইন্টারনেট দেখে আবার চেষ্টা করো।',
                  textAlign: TextAlign.center,
                  style: dsText(15, color: AppColors.ink2),
                ),
                const SizedBox(height: 16),
                DsSmallButton(
                  label: 'আবার চেষ্টা',
                  onPressed: () => ref.invalidate(userExamResultsProvider),
                ),
              ],
            ),
          ),
        ),
        data: (all) {
          final list = [...all]
            ..sort((a, b) => b.answeredAt.compareTo(a.answeredAt));
          if (list.isEmpty) {
            return Center(
              child: Text(
                'এখনো কোনো পরীক্ষা দাওনি।',
                style: dsText(15, color: AppColors.muted),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(userExamResultsProvider),
            child: DsPage(
              gap: 10,
              children: [
                for (final r in list)
                  _ResultRow(result: r, title: titles[r.examId]),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  final ExamResultModel result;
  final String? title;

  const _ResultRow({required this.result, required this.title});

  @override
  Widget build(BuildContext context) {
    final pct = result.percentage.round();
    final name = title ?? result.examId;
    return DsCard(
      onTap: () => context.push(
        '/exam/${Uri.encodeComponent(result.examId)}/leaderboard'
        '?title=${Uri.encodeComponent(name)}',
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: dsText(15, weight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  '${bnDate(result.answeredAt.toLocal())} · '
                  'ঠিক ${bn(result.correctCount)}, ভুল ${bn(result.wrongCount)}, '
                  'ফাঁকা ${bn(result.skippedCount)}',
                  style: dsText(12, color: AppColors.muted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${bn(pct)}%', style: dsText(18, weight: FontWeight.w700)),
              Text(
                bnScore(result.score),
                style: dsText(11, color: AppColors.muted),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
