import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/bangla_digits.dart';
import '../../../core/widgets/ds.dart';
import '../../bcs/views/bcs_format.dart';
import '../controllers/study_plan_provider.dart';
import '../data/models/study_plan_model.dart';

/// আজকের পড়ার পরিকল্পনা: how many days are left, which phase that puts the
/// learner in, and how today's study time should be split across subjects.
class StudyPlanScreen extends ConsumerWidget {
  const StudyPlanScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(studyPlanProvider);
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: const DsHeader(title: 'আজকের পরিকল্পনা'),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(
          child: DsButton(
            label: 'আবার চেষ্টা করো',
            onPressed: () => ref.invalidate(studyPlanProvider),
          ),
        ),
        data: (plan) => _body(context, ref, plan),
      ),
    );
  }

  Widget _body(BuildContext context, WidgetRef ref, StudyPlan plan) {
    final (phaseLabel, phaseHint) = switch (plan.phase) {
      'final' => (
        'শেষ ধাপ',
        'নতুন কিছু কম, বেশিরভাগ সময় বিগত প্রশ্ন আর মডেল টেস্টে।',
      ),
      'revision' => ('রিভিশন', 'শেখা আর অনুশীলন প্রায় সমান সমান।'),
      _ => ('ভিত্তি গড়ো', 'এখন সময় আছে। টপিক ধরে ধরে শেখার দিকে জোর দাও।'),
    };
    final target = plan.targetDate;
    final targetName =
        plan.targetLabel ??
        (plan.targetEdition != null
            ? editionName(plan.targetEdition!)
            : 'পরীক্ষা');
    final minutesNote = switch (plan.minutesSource) {
      'routine' => 'তোমার রুটিনের পড়ার ব্লক থেকে',
      'query' => 'তোমার বেছে নেওয়া সময়',
      _ => 'ধরে নেওয়া সময়। রুটিনে পড়ার ব্লক দিলে সেটা ধরবে',
    };
    return DsPage(
      children: [
        DsCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (plan.daysLeft == null)
                Text(
                  'পরীক্ষার তারিখ দাওনি',
                  style: dsText(18, weight: FontWeight.w700),
                )
              else
                Text(
                  '$targetName: ${bn(plan.daysLeft!)} দিন বাকি',
                  style: dsText(18, weight: FontWeight.w700),
                ),
              const SizedBox(height: 4),
              if (target != null)
                Text(
                  plan.targetSource == 'default'
                      ? '${bnDate(target)} · পরবর্তী বিসিএসের তারিখ ধরা হয়েছে'
                      : bnDate(target),
                  style: dsText(12, color: AppColors.muted),
                ),
              const SizedBox(height: 8),
              Text(
                '$phaseLabel · $phaseHint',
                style: dsText(13, height: 1.5, color: AppColors.ink2),
              ),
              const SizedBox(height: 12),
              DsButton.secondary(
                label: 'নিজের পরীক্ষার তারিখ দাও',
                onPressed: () => _pickDate(context, ref),
              ),
              if (plan.targetSource == 'user')
                TextButton(
                  onPressed: () => saveTargetExam(ref, null),
                  child: const Text('তারিখ মুছে ফেলো'),
                ),
            ],
          ),
        ),
        DsCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'প্রতিদিন ${bn(plan.minutesPerDay)} মিনিট',
                style: dsText(15, weight: FontWeight.w600),
              ),
              Text(minutesNote, style: dsText(12, color: AppColors.muted)),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _split('শেখা', plan.learnMinutes, AppColors.brand),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _split(
                      'অনুশীলন',
                      plan.practiceMinutes,
                      AppColors.accent,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SectionLabel('কোন বিষয়ে কত সময়'),
        if (plan.subjects.isEmpty)
          Text(
            'বিগত প্রশ্নের হিসাব এলে এখানে বিষয় ধরে সময় ভাগ হবে।',
            style: dsText(14, color: AppColors.muted),
          )
        else
          DsListCard(
            radius: 16,
            children: [for (final s in plan.subjects) _subject(context, s)],
          ),
      ],
    );
  }

  Widget _split(String label, int minutes, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.sunken,
        borderRadius: BorderRadius.circular(AppRadii.sm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: dsText(12, color: AppColors.muted)),
          Text(
            '${bn(minutes)} মিনিট',
            style: dsText(16, weight: FontWeight.w700, color: color),
          ),
        ],
      ),
    );
  }

  Widget _subject(BuildContext context, PlanSubject s) {
    final reason = switch (s.reason) {
      'weak-and-heavy' => 'দুর্বল, আবার প্রশ্নও বেশি আসে',
      'weak' => 'দুর্বল',
      'heavy' => 'প্রশ্ন বেশি আসে',
      'new' => 'এখনো অনুশীলন করোনি',
      _ => 'ঠিক আছে',
    };
    final accuracy = s.accuracy == null
        ? ''
        : ' · তোমার সঠিক ${bn((s.accuracy! * 100).round())}%';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(s.name, style: dsText(15, weight: FontWeight.w600)),
              ),
              Text(
                '${bn(s.minutes)} মিনিট',
                style: dsText(
                  15,
                  weight: FontWeight.w700,
                  color: AppColors.brand,
                ),
              ),
            ],
          ),
          Text(
            '$reason · গড়ে ${bn(s.questionsPerPaper.toStringAsFixed(1))}টি '
            'প্রশ্ন/পেপার$accuracy',
            style: dsText(12, color: AppColors.muted),
          ),
          if (s.topics.isNotEmpty) ...[
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final t in s.topics)
                  ActionChip(
                    label: Text(t.name, style: dsText(12)),
                    onPressed: () => context.push(
                      '/taxonomy-questions/${t.syllabusId}/${t.nodeId}'
                      '?title=${Uri.encodeComponent(t.name)}',
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _pickDate(BuildContext context, WidgetRef ref) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 30)),
      firstDate: now,
      lastDate: DateTime(now.year + 3, now.month, now.day),
    );
    if (picked == null) return;
    try {
      await saveTargetExam(ref, picked);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('তারিখ সংরক্ষণ করা যায়নি')),
        );
      }
    }
  }
}
