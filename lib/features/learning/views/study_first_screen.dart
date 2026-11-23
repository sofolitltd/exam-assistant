import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/bangla_digits.dart';
import '../../../core/widgets/ds.dart';
import '../controllers/learning_providers.dart';
import '../data/learning_models.dart';

/// কোনটা আগে পড়ব: topics ranked by how often they appear in recent past
/// papers and how weak the user is on them.
class StudyFirstScreen extends ConsumerStatefulWidget {
  const StudyFirstScreen({super.key});

  @override
  ConsumerState<StudyFirstScreen> createState() => _StudyFirstScreenState();
}

class _StudyFirstScreenState extends ConsumerState<StudyFirstScreen> {
  int _papers = 10;
  bool _showAll = false;

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(topicInsightsProvider(_papers));
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: const DsHeader(title: 'কোনটা আগে পড়ব'),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('লোড করা যায়নি', style: dsText(15)),
                const SizedBox(height: 12),
                DsButton(
                  label: 'আবার চেষ্টা করো',
                  onPressed: () => ref.invalidate(topicInsightsProvider),
                ),
              ],
            ),
          ),
        ),
        data: (data) => _body(context, data),
      ),
    );
  }

  Widget _body(BuildContext context, TopicInsights data) {
    if (data.items.isEmpty) {
      return Center(
        child: Text(
          'এখনো বিগত প্রশ্নের হিসাব নেই',
          style: dsText(14, color: AppColors.muted),
        ),
      );
    }
    final shown = _showAll ? data.items : data.items.take(15).toList();
    return DsPage(
      children: [
        DsCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'গত ${bn(data.papers)}টি বিসিএসের হিসাব',
                style: dsText(15, weight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                'যে টপিক থেকে বেশি প্রশ্ন আসে আর তুমি বেশি ভুল করো, সেটা উপরে।',
                style: dsText(12, color: AppColors.muted),
              ),
              const SizedBox(height: 10),
              DsSegmented<int>(
                value: _papers,
                onChanged: (v) => setState(() {
                  _papers = v;
                  _showAll = false;
                }),
                items: const [
                  (5, '৫টি', null),
                  (10, '১০টি', null),
                  (20, '২০টি', null),
                ],
              ),
            ],
          ),
        ),
        DsListCard(
          radius: 16,
          children: [for (final t in shown) _row(context, t)],
        ),
        if (!_showAll && data.items.length > shown.length)
          DsButton(
            label: 'সব টপিক দেখো',
            onPressed: () => setState(() => _showAll = true),
          ),
      ],
    );
  }

  Widget _row(BuildContext context, TopicInsight t) {
    final (label, color) = switch (t.focusReason) {
      'weak-and-frequent' => ('দুর্বল ও বারবার আসে', AppColors.danger),
      'weak' => ('দুর্বল', AppColors.danger),
      'frequent' => ('বারবার আসে', AppColors.accent),
      'new' => ('এখনো চেষ্টা করোনি', AppColors.muted),
      _ => ('ঠিক আছে', AppColors.success),
    };
    final avg = t.avgPerPaper.toStringAsFixed(1);
    final accuracy = t.attempted < 3
        ? ''
        : ' · তোমার সঠিক ${bn((t.accuracy * 100).round())}%';
    return InkWell(
      onTap: () => context.push(
        '/taxonomy-questions/${t.syllabusId}/${t.nodeId}'
        '?title=${Uri.encodeComponent(t.name)}',
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t.name, style: dsText(15, weight: FontWeight.w600)),
            const SizedBox(height: 2),
            Text(
              '${t.subjectName} · গড়ে ${bn(avg)}টি প্রশ্ন/পেপার$accuracy',
              style: dsText(12, color: AppColors.muted),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: dsText(12, color: color, weight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
