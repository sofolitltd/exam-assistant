import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/bangla_digits.dart';
import '../../../core/widgets/ds.dart';
import '../controllers/learning_providers.dart';
import '../data/learning_models.dart';

/// স্কোর কৌশল: with negative marking, a guess only pays when you are right
/// often enough. This shows, per subject, whether attempting has gained or
/// lost marks and where it is safer to leave a question blank.
class StrategyScreen extends ConsumerWidget {
  const StrategyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(strategyProvider);
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: const DsHeader(title: 'স্কোর কৌশল'),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(
          child: DsButton(
            label: 'আবার চেষ্টা করো',
            onPressed: () => ref.invalidate(strategyProvider),
          ),
        ),
        data: (items) => _body(items),
      ),
    );
  }

  Widget _body(List<SubjectStrategy> items) {
    final explainer = DsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ভুল উত্তরে নম্বর কাটা যায়',
            style: dsText(15, weight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            '০.৫ নম্বর কাটলে প্রতি ৩টায় অন্তত ১টা ঠিক না হলে আন্দাজ করে '
            'লাভ নেই। একটা অপশন বাদ দিতে পারলে সম্ভাবনা বাড়ে।',
            style: dsText(12, height: 1.5, color: AppColors.muted),
          ),
        ],
      ),
    );
    if (items.isEmpty) {
      return DsPage(
        children: [
          explainer,
          Text(
            'পরীক্ষা দিলে এখানে বিষয় ধরে হিসাব দেখাবে।',
            style: dsText(14, color: AppColors.muted),
          ),
        ],
      );
    }
    return DsPage(
      children: [
        explainer,
        DsListCard(radius: 16, children: [for (final s in items) _row(s)]),
      ],
    );
  }

  Widget _row(SubjectStrategy s) {
    final (label, color) = switch (s.advice) {
      'skip-when-unsure' => ('না জানলে ছেড়ে দাও', AppColors.danger),
      'guess-with-care' => ('একটা অপশন বাদ দিতে পারলে দাও', AppColors.accent),
      'attempt' => ('নির্ভয়ে দাও', AppColors.success),
      _ => ('আরও প্রশ্ন দিলে বোঝা যাবে', AppColors.muted),
    };
    final net = s.netScore >= 0
        ? '+${bnScore(s.netScore)}'
        : bnScore(s.netScore);
    final time = (s.avgTimeCorrectMs != null && s.avgTimeWrongMs != null)
        ? '\nঠিক উত্তরে গড় ${_sec(s.avgTimeCorrectMs!)}, ভুলে ${_sec(s.avgTimeWrongMs!)}'
        : '';
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
                net,
                style: dsText(
                  15,
                  weight: FontWeight.w700,
                  color: s.netScore >= 0 ? AppColors.success : AppColors.danger,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            'দিয়েছ ${bn(s.attempted)}টি · ঠিক ${bn(s.correct)} · ভুল ${bn(s.wrong)}'
            ' (${bnScore(s.lostToNegative)} কাটা গেছে)'
            '\nসঠিক ${bn((s.accuracy * 100).round())}%, লাভ-ক্ষতির সীমা '
            '${bn((s.breakEvenAccuracy * 100).round())}%$time',
            style: dsText(12, height: 1.5, color: AppColors.muted),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: dsText(12, weight: FontWeight.w600, color: color),
          ),
        ],
      ),
    );
  }

  String _sec(int ms) => '${bn((ms / 1000).round())} সেকেন্ড';
}
