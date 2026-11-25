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
import '../data/practice_models.dart';
import '../widgets/accuracy_chart.dart';

enum _Range { week, month, all }

enum _Tab { practice, exam, all }

/// আমার অগ্রগতি, in three tabs. অনুশীলন: today, the week, streak and past
/// practice sittings. প্রতিযোগিতা: score over ranked exams. সব: both. Each
/// tab ends with its subjects, weakest first.
class ProgressScreen extends ConsumerStatefulWidget {
  const ProgressScreen({super.key});

  @override
  ConsumerState<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends ConsumerState<ProgressScreen> {
  _Tab _tab = _Tab.practice;
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

    final mode = switch (_tab) {
      _Tab.practice => 'practice',
      _Tab.exam => 'exam',
      _Tab.all => null,
    };
    final subjectsAsync = ref.watch(
      subjectPerformanceByModeProvider((days: _days, mode: mode)),
    );
    final summary = ref.watch(practiceSummaryProvider);
    final mistakes = ref.watch(mistakeSummaryProvider).value;
    final mistakeCount = mistakes == null
        ? null
        : switch (_tab) {
            _Tab.practice => mistakes.practice,
            _Tab.exam => mistakes.exam,
            _Tab.all => mistakes.total,
          };
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
      body: RefreshIndicator(
        onRefresh: () async {
          refreshLearningData(
            ProviderScope.containerOf(context, listen: false),
          );
          ref.invalidate(userExamResultsProvider);
        },
        child: DsPage(
          children: [
            DsSegmented<_Tab>(
              value: _tab,
              onChanged: (t) => setState(() {
                _tab = t;
                _showAll = false;
              }),
              items: const [
                (_Tab.practice, 'অনুশীলন', null),
                (_Tab.exam, 'প্রতিযোগিতা', null),
                (_Tab.all, 'সব', null),
              ],
            ),
            if (_tab != _Tab.exam)
              summary.when(
                data: (s) => _PracticeCard(summary: s, all: _tab == _Tab.all),
                loading: () => const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (_, _) => DsCard(
                  child: Text(
                    'অনুশীলনের হিসাব লোড করা যায়নি। টেনে নামিয়ে আবার চেষ্টা করো।',
                    style: dsText(13, color: AppColors.danger),
                  ),
                ),
              ),
            if (mistakeCount != null)
              InfoTile(
                title: switch (_tab) {
                  _Tab.practice => 'অনুশীলনের ভুল',
                  _Tab.exam => 'প্রতিযোগিতার ভুল',
                  _Tab.all => 'আমার ভুল',
                },
                subtitle: mistakeCount == 0
                    ? 'ঠিক করার মতো কোনো ভুল নেই'
                    : '${bn(mistakeCount)}টি ঠিক করা বাকি · আবার দাও',
                subtitleColor: mistakeCount == 0 ? null : AppColors.danger,
                onTap: () => context.push(
                  mode == null
                      ? '/practice/mistakes'
                      : '/practice/mistakes?mode=$mode',
                ),
              ),
            if (_tab != _Tab.practice)
              DsCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'প্রতিযোগিতায় সঠিক উত্তরের হার',
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
            if (_tab == _Tab.practice)
              DsSegmented<_Range>(
                value: _range,
                onChanged: (r) => setState(() {
                  _range = r;
                  _showAll = false;
                }),
                items: const [
                  (_Range.week, '৭ দিন', null),
                  (_Range.month, '৩০ দিন', null),
                  (_Range.all, 'সব', null),
                ],
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
            if (_tab != _Tab.exam)
              summary.maybeWhen(
                data: (s) => s.sessions.isEmpty
                    ? const SizedBox.shrink()
                    : _SessionList(sessions: s.sessions),
                orElse: () => const SizedBox.shrink(),
              ),
          ],
        ),
      ),
    );
  }
}

/// Today, this week, all time, a 7-day strip and the streak.
class _PracticeCard extends StatelessWidget {
  final PracticeSummary summary;

  /// On the সব tab: also show answers from ranked exams.
  final bool all;

  const _PracticeCard({required this.summary, required this.all});

  @override
  Widget build(BuildContext context) {
    final s = summary;
    final streak = s.streak;
    String pct(PracticeCount c) =>
        c.accuracy == null ? '—' : '${bn((c.accuracy! * 100).round())}%';
    return DsCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: StatBox(
                  label: 'আজ',
                  value: bn(s.today.answered),
                  valueColor: AppColors.brand,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: StatBox(label: '৭ দিনে', value: bn(s.week.answered)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: StatBox(
                  label: all ? 'মোট (সব মিলিয়ে)' : 'মোট',
                  value: bn(s.total.answered + (all ? s.examAnswered : 0)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'অনুশীলনে নির্ভুলতা: আজ ${pct(s.today)} · ৭ দিনে ${pct(s.week)} · মোট ${pct(s.total)}',
            style: dsText(13, color: AppColors.ink2, height: 1.5),
          ),
          const SizedBox(height: 14),
          PracticeWeekBars(days: s.days),
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.lineSoft),
          const SizedBox(height: 10),
          Text(
            streak.current > 0
                ? 'টানা ${bn(streak.current)} দিন · সেরা ${bn(streak.best)} দিন'
                : 'আজ থেকে streak শুরু করো',
            style: dsText(14, weight: FontWeight.w600),
          ),
          const SizedBox(height: 2),
          Text(
            streak.todayCounted
                ? 'আজকের দিন গোনা হয়েছে।'
                : 'দিনে অন্তত ${bn(streak.minAnswers)}টি প্রশ্ন করলে দিনটা গোনা হয়। আজ আর ${bn(s.todayLeft)}টি।',
            style: dsText(12, color: AppColors.muted, height: 1.5),
          ),
        ],
      ),
    );
  }
}

/// Seven small bars, one per day, oldest first; today in brand colour.
class PracticeWeekBars extends StatelessWidget {
  final List<PracticeDay> days;

  const PracticeWeekBars({required this.days, super.key});

  static const _weekday = ['সোম', 'মঙ্গল', 'বুধ', 'বৃহ', 'শুক্র', 'শনি', 'রবি'];

  @override
  Widget build(BuildContext context) {
    final most = days.fold<int>(
      0,
      (m, d) => d.count.answered > m ? d.count.answered : m,
    );
    return SizedBox(
      height: 92,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < days.length; i++)
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    days[i].count.answered == 0
                        ? ''
                        : bn(days[i].count.answered),
                    style: dsText(10, color: AppColors.muted),
                  ),
                  const SizedBox(height: 2),
                  Container(
                    width: 18,
                    height: most == 0
                        ? 3
                        : 3 + 47 * days[i].count.answered / most,
                    decoration: BoxDecoration(
                      color: i == days.length - 1
                          ? AppColors.brand
                          : days[i].count.answered == 0
                          ? AppColors.lineSoft
                          : AppColors.brandSoft,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _weekday[days[i].date.weekday - 1],
                    style: dsText(10, color: AppColors.muted),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Recent practice sittings, newest first.
class _SessionList extends StatelessWidget {
  final List<PracticeSessionInfo> sessions;

  const _SessionList({required this.sessions});

  static String _source(String s) => switch (s) {
    'paper' => 'প্রশ্নপত্র',
    'topic' => 'টপিক',
    'subject' => 'বিষয়',
    'mistakes' => 'ভুল',
    _ => 'অনুশীলন',
  };

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 2),
          child: SectionLabel('আগের অনুশীলন'),
        ),
        DsCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (final s in sessions)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 11,
                  ),
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: AppColors.lineSoft),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s.label.isEmpty ? _source(s.source) : s.label,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: dsText(14, weight: FontWeight.w600),
                            ),
                            Text(
                              '${bnDayMonthShort(s.lastAnswerAt)} · ${_source(s.source)} · '
                              '${bn(s.answered)} প্রশ্ন · ভুল ${bn(s.answered - s.correct)}',
                              style: dsText(12, color: AppColors.muted),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${bn((s.correct * 100 / (s.answered == 0 ? 1 : s.answered)).round())}%',
                        style: dsText(15, weight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
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
