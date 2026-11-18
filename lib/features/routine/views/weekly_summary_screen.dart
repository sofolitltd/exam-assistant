import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../controllers/routine_controller.dart';
import '../data/models/weekly_summary_model.dart';

class WeeklySummaryScreen extends ConsumerWidget {
  const WeeklySummaryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weekStart = mostRecentMonday(DateTime.now());
    final summaryAsync = ref.watch(weeklySummaryProvider(weekStart));

    return Scaffold(
      appBar: AppBar(title: const Text('সাপ্তাহিক সামারি')),
      body: summaryAsync.when(
        data: (summary) => _SummaryBody(summary: summary),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) =>
            Center(child: Text('সামারি লোড করা যায়নি: $error')),
      ),
    );
  }
}

/// "Routine effort vs exam result" line for a block linked to a subject.
class _ExamLink extends StatelessWidget {
  final RoutineBlockSummary block;

  const _ExamLink({required this.block});

  @override
  Widget build(BuildContext context) {
    final now = block.examAccuracy;
    final before = block.prevExamAccuracy;
    if (now == null) {
      return Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          '${block.subjectName}: এই সপ্তাহে এই বিষয়ে কোনো পরীক্ষার প্রশ্ন দাওনি।',
          style: const TextStyle(fontSize: 12, color: AppColors.muted),
        ),
      );
    }
    final percent = (now * 100).round();
    final delta = before == null ? null : ((now - before) * 100).round();
    final color = delta == null || delta == 0
        ? AppColors.muted
        : delta > 0
        ? AppColors.success
        : AppColors.danger;
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          const Icon(Icons.quiz_outlined, size: 14, color: AppColors.brand),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              '${block.subjectName}: পরীক্ষায় সঠিক $percent% '
              '(${block.examAttempted} প্রশ্ন)'
              '${before == null ? '' : ' · গত সপ্তাহ ${(before * 100).round()}%'}',
              style: const TextStyle(fontSize: 12),
            ),
          ),
          if (delta != null && delta != 0)
            Text(
              '${delta > 0 ? '▲' : '▼'} ${delta.abs()}%',
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
        ],
      ),
    );
  }
}

class _SummaryBody extends StatelessWidget {
  final WeeklySummaryModel summary;

  const _SummaryBody({required this.summary});

  @override
  Widget build(BuildContext context) {
    final percent = (summary.completionRate * 100).round();
    final weakest = summary.weakestBlocks;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          color: AppTheme.primaryColor.withValues(alpha: 0.08),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Text('${summary.weekStart} — ${summary.weekEnd}'),
                const SizedBox(height: 8),
                Text(
                  '$percent%',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text('এই সপ্তাহে routine মানা হয়েছে'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        if (weakest.isNotEmpty) ...[
          Text(
            'কোথায় বেশি miss হচ্ছে',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          ...weakest.map(
            (b) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                title: Text(b.title),
                trailing: Text(
                  '${b.missedCount} দিন miss',
                  style: const TextStyle(
                    color: AppTheme.errorColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
        Text(
          'ব্লক-ভিত্তিক বিস্তারিত',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        ...summary.blocks.map((b) {
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              title: Text(b.title),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'সম্পন্ন: ${b.doneCount} · আংশিক: ${b.partialCount} · miss: ${b.missedCount}',
                  ),
                  if (b.subjectName != null) _ExamLink(block: b),
                ],
              ),
            ),
          );
        }),
        if (!summary.blocks.any((b) => b.subjectName != null)) ...[
          const SizedBox(height: 12),
          Text(
            'টিপ: রুটিন এডিট করে পড়ার ব্লকে সিলেবাসের বিষয় যুক্ত করো — তাহলে '
            'এখানে ওই বিষয়ে পরীক্ষার ফলাফলও পাশাপাশি দেখা যাবে।',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ],
    );
  }
}
