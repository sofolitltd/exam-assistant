import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/bangla_digits.dart';
import '../../../core/widgets/ds.dart';
import '../../bcs/views/bcs_format.dart';
import '../../dashboard/controllers/stats_controller.dart';
import '../../dashboard/views/profile_view.dart';
import '../controllers/learning_providers.dart';
import '../data/learning_models.dart';
import '../widgets/accuracy_chart.dart';

enum _Range { week, month, all }

/// আমার অগ্রগতি: accuracy over time, then every subject weakest first.
class ProgressScreen extends ConsumerStatefulWidget {
  const ProgressScreen({super.key});

  @override
  ConsumerState<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends ConsumerState<ProgressScreen> {
  _Range _range = _Range.month;
  int? _selected;
  bool _showAll = false;

  int get _days => switch (_range) {
    _Range.week => 7,
    _Range.month => 30,
    _Range.all => 3650,
  };

  @override
  Widget build(BuildContext context) {
    final cutoff = DateTime.now().subtract(Duration(days: _days));
    final results = [
      ...?ref
          .watch(userExamResultsProvider)
          .value
          ?.where((r) => r.answeredAt.isAfter(cutoff)),
    ]..sort((a, b) => a.answeredAt.compareTo(b.answeredAt));
    final values = [for (final r in results) r.percentage];
    final sel = values.isEmpty
        ? null
        : (_selected ?? values.length - 1).clamp(0, values.length - 1);

    final subjectsAsync = ref.watch(subjectPerformanceByDaysProvider(_days));
    final subjects = [...?subjectsAsync.value?.where((s) => s.attempted > 0)]
      ..sort((a, b) => a.accuracy.compareTo(b.accuracy));
    final shown = _showAll ? subjects : subjects.take(6).toList();
    final rangeLabel = switch (_range) {
      _Range.week => 'গত ৭ দিন',
      _Range.month => 'গত ৩০ দিন',
      _Range.all => 'সব সময়',
    };

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: const DsHeader(title: 'আমার অগ্রগতি'),
      body: DsPage(
        children: [
          DsCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'পরীক্ষায় সঠিক উত্তরের হার',
                  style: dsText(15, weight: FontWeight.w600),
                ),
                const SizedBox(height: 10),
                DsSegmented<_Range>(
                  value: _range,
                  onChanged: (r) => setState(() {
                    _range = r;
                    _selected = null;
                    _showAll = false;
                  }),
                  items: const [
                    (_Range.week, '৭ দিন', null),
                    (_Range.month, '৩০ দিন', null),
                    (_Range.all, 'সব', null),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  sel == null
                      ? '$rangeLabel কোনো পরীক্ষা নেই'
                      : 'পরীক্ষা ${bn(sel + 1)} · ${bnDayMonthShort(results[sel].answeredAt)} · '
                            'সঠিক ${bn(values[sel].round())}%',
                  style: dsText(13, color: AppColors.ink2),
                ),
                const SizedBox(height: 8),
                AccuracyChart(
                  values: values,
                  selected: sel,
                  onSelect: (i) => setState(() => _selected = i),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: SectionLabel(
              'বিষয়ভিত্তিক · দুর্বল আগে',
              trailing: rangeLabel,
            ),
          ),
          if (subjectsAsync.isLoading && subjects.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (subjectsAsync.hasError)
            Text(
              'বিষয়ের হিসাব লোড করা যায়নি: ${subjectsAsync.error}',
              style: dsText(13, color: AppColors.danger),
            )
          else if (subjects.isEmpty)
            DsCard(
              child: Text(
                '$rangeLabel কোনো বিষয়ের প্রশ্নের উত্তর দাওনি।',
                style: dsText(14, color: AppColors.muted),
              ),
            )
          else
            DsCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  for (final s in shown) _SubjectRow(subject: s),
                  if (subjects.length > 6)
                    TextButton(
                      onPressed: () => setState(() => _showAll = !_showAll),
                      child: Text(
                        _showAll
                            ? 'কম দেখাও'
                            : 'আরও ${bn(subjects.length - 6)}টি বিষয়',
                        style: dsText(
                          13,
                          weight: FontWeight.w600,
                          color: AppColors.brand,
                        ),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _SubjectRow extends StatelessWidget {
  final SubjectPerformance subject;

  const _SubjectRow({required this.subject});

  @override
  Widget build(BuildContext context) {
    final s = subject;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.lineSoft)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(s.name, style: dsText(15, weight: FontWeight.w600)),
              ),
              Text(
                '${bn((s.accuracy * 100).round())}%',
                style: dsText(15, weight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 8),
          DsBar(value: s.accuracy, height: 6, track: AppColors.lineSoft),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${bn(s.attempted)} প্রশ্ন · ঠিক ${bn(s.correct)} · '
                  'ভুল ${bn(s.wrong)} · বাদ ${bn(s.skipped)}',
                  style: dsText(12, color: AppColors.muted),
                ),
              ),
              DsSmallButton(
                label: 'শোনো',
                onPressed: () => context.push(
                  '/listen?syllabusId=${s.syllabusId}&nodeId=${s.nodeId}'
                  '&title=${Uri.encodeComponent(s.name)}',
                ),
              ),
              const SizedBox(width: 6),
              DsButton(
                label: 'অনুশীলন',
                height: 36,
                fontSize: 12,
                onPressed: () => context.push(practicePath(s)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
