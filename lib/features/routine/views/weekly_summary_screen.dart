import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/bangla_digits.dart';
import '../../../core/widgets/ds.dart';
import '../controllers/routine_controller.dart';
import '../data/models/weekly_summary_model.dart';
import '../widgets/routine_ui.dart';

class WeeklySummaryScreen extends ConsumerStatefulWidget {
  const WeeklySummaryScreen({super.key});

  @override
  ConsumerState<WeeklySummaryScreen> createState() =>
      _WeeklySummaryScreenState();
}

class _WeeklySummaryScreenState extends ConsumerState<WeeklySummaryScreen> {
  /// 0 = this week, 1 = last week, …
  int _weeksBack = 0;
  int? _selectedDay;

  @override
  Widget build(BuildContext context) {
    final monday = mostRecentMonday(
      DateTime.now(),
    ).subtract(Duration(days: 7 * _weeksBack));
    final sunday = monday.add(const Duration(days: 6));
    final summaryAsync = ref.watch(weeklySummaryProvider(monday));
    final prev = ref
        .watch(weeklySummaryProvider(monday.subtract(const Duration(days: 7))))
        .value;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: DsHeader(
        title: 'সাপ্তাহিক সামারি',
        subtitle:
            '${bnRange(monday, sunday)}${_weeksBack == 0 ? ' · এই সপ্তাহ' : ''}',
        trailing: Row(
          children: [
            _navButton(
              LucideIcons.chevronLeft,
              'আগের সপ্তাহ',
              () => setState(() {
                _weeksBack++;
                _selectedDay = null;
              }),
            ),
            if (_weeksBack > 0) ...[
              const SizedBox(width: 6),
              _navButton(
                LucideIcons.chevronRight,
                'পরের সপ্তাহ',
                () => setState(() {
                  _weeksBack--;
                  _selectedDay = null;
                }),
              ),
            ],
          ],
        ),
      ),
      body: summaryAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) =>
            Center(child: Text('সামারি লোড করা যায়নি: $error')),
        data: (summary) => _body(summary, prev),
      ),
    );
  }

  Widget _navButton(IconData icon, String label, VoidCallback onTap) {
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: AppColors.paper,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: Color(0xFFDADDE1)),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(width: 40, height: 40, child: Icon(icon, size: 18)),
        ),
      ),
    );
  }

  Widget _body(WeeklySummaryModel s, WeeklySummaryModel? prev) {
    final pct = (s.completionRate * 100).round();
    final hasPrev = prev != null && prev.blocks.any((b) => b.loggedCount > 0);
    final delta = hasPrev ? pct - (prev.completionRate * 100).round() : null;
    final subjectBlocks = s.blocks.where((b) => b.subjectName != null).toList();
    final weakest = s.weakestBlocks.firstOrNull;
    final routine = ref.watch(myRoutineProvider).value;
    final weakBlock = weakest == null
        ? null
        : routine?.blocks.where((b) => b.id == weakest.blockId).firstOrNull;

    return DsPage(
      children: [
        DsCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'রুটিন মানা হয়েছে',
                          style: dsText(12, color: AppColors.muted),
                        ),
                        Text(
                          '${bn(pct)}%',
                          style: dsText(
                            34,
                            weight: FontWeight.w700,
                            height: 1.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (delta != null)
                    Text(
                      delta >= 0
                          ? '▲ ${bn(delta)}% গত সপ্তাহের চেয়ে'
                          : '▼ ${bn(-delta)}% গত সপ্তাহের চেয়ে',
                      style: dsText(
                        13,
                        weight: FontWeight.w600,
                        color: delta >= 0
                            ? AppColors.successInk
                            : AppColors.danger,
                      ),
                    ),
                ],
              ),
              if (_weeksBack == 0) ...[
                const SizedBox(height: 12),
                _DailyBars(
                  selected: _selectedDay,
                  onSelect: (i) => setState(() => _selectedDay = i),
                ),
              ],
            ],
          ),
        ),
        if (subjectBlocks.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: SectionLabel('পড়া আর পরীক্ষার ফল'),
          ),
          DsListCard(
            radius: 16,
            children: [for (final b in subjectBlocks) _subjectRow(b)],
          ),
        ],
        if (weakest != null) ...[
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: SectionLabel('কোথায় বেশি miss হচ্ছে'),
          ),
          DsCard(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        weakBlock == null
                            ? weakest.title
                            : '${weakest.title} · ${bnClock12(weakBlock.startTime)}',
                        style: dsText(15, weight: FontWeight.w600),
                      ),
                      Text(
                        '${bn(weakest.loggedCount)} দিনে ${bn(weakest.missedCount)} দিন miss। '
                        'সময়টা কি তোমার জন্য ঠিক?',
                        style: dsText(12, color: AppColors.muted),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                DsButton(
                  label: 'সময় বদলাও',
                  height: 34,
                  fontSize: 13,
                  onPressed: () => context.push('/routine/builder'),
                ),
              ],
            ),
          ),
        ],
        if (s.blocks.every((b) => b.loggedCount == 0))
          DsCard(
            child: Text(
              'এই সপ্তাহে এখনো কোনো check-in নেই।',
              style: dsText(14, color: AppColors.muted),
            ),
          ),
      ],
    );
  }

  Widget _subjectRow(RoutineBlockSummary b) {
    final studied = b.doneCount + b.partialCount;
    final studiedText = b.loggedCount == 0
        ? 'এই সপ্তাহে check-in নেই'
        : '${bn(b.loggedCount)} দিনের ${bn(studied)} দিন পড়েছ';

    Widget trailing;
    if (b.examAttempted == 0 || b.examAccuracy == null) {
      trailing = DsSmallButton(
        label: 'অনুশীলন',
        onPressed: () => context.push('/bcs/pyq'),
      );
    } else {
      final acc = (b.examAccuracy! * 100).round();
      final prevAcc = b.prevExamAccuracy == null
          ? null
          : (b.prevExamAccuracy! * 100).round();
      final diff = prevAcc == null ? null : acc - prevAcc;
      trailing = Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text('${bn(acc)}%', style: dsText(15, weight: FontWeight.w700)),
          Text(
            diff == null
                ? 'সঠিক'
                : diff >= 0
                ? '▲ ${bn(diff)}% সঠিক'
                : '▼ ${bn(-diff)}% সঠিক',
            style: dsText(
              12,
              weight: FontWeight.w600,
              color: diff == null
                  ? AppColors.muted
                  : diff >= 0
                  ? AppColors.successInk
                  : AppColors.danger,
            ),
          ),
        ],
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(b.title, style: dsText(15, weight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(
                  b.examAttempted == 0
                      ? '$studiedText · এই সপ্তাহে পরীক্ষা দাওনি'
                      : studiedText,
                  style: dsText(12, color: AppColors.muted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          trailing,
        ],
      ),
    );
  }
}

/// Last seven days' adherence as bars, with the 50% streak line.
class _DailyBars extends ConsumerWidget {
  final int? selected;
  final ValueChanged<int> onSelect;

  const _DailyBars({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final days = ref.watch(streakProvider).value?.lastSevenDays ?? const [];
    if (days.isEmpty) return const SizedBox.shrink();
    final sel = selected ?? days.length - 1;
    final now = DateTime.now();

    String name(int i) {
      if (i == days.length - 1) return 'আজ';
      final d = now.subtract(Duration(days: days.length - 1 - i));
      return weekdayShort(d.weekday);
    }

    final rate = days[sel].rate;
    final label = rate == null
        ? '${name(sel)}: check-in নেই'
        : '${name(sel)}: ${bn((rate * 100).round())}% · '
              '${rate >= 0.5 ? 'streak-এ গোনা হয়েছে' : 'streak-এ গোনা হয়নি'}';

    const chartH = 140.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(label, style: dsText(13, color: AppColors.ink2)),
        const SizedBox(height: 8),
        SizedBox(
          height: chartH,
          child: Stack(
            children: [
              Positioned(
                left: 0,
                right: 0,
                bottom: chartH * 0.5,
                child: Container(height: 1, color: const Color(0xFFC4C8CE)),
              ),
              Positioned(
                right: 0,
                bottom: chartH * 0.5 + 2,
                child: Container(
                  color: AppColors.paper,
                  padding: const EdgeInsets.only(left: 4),
                  child: Text(
                    'streak-এর সীমা ৫০%',
                    style: dsText(11, color: AppColors.muted),
                  ),
                ),
              ),
              Positioned.fill(
                child: Container(
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Color(0xFFC4C8CE)),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      for (var i = 0; i < days.length; i++)
                        Expanded(
                          child: Semantics(
                            button: true,
                            label: name(i),
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () => onSelect(i),
                              child: Align(
                                alignment: Alignment.bottomCenter,
                                child: Container(
                                  width: 22,
                                  height: ((days[i].rate ?? 0) * chartH).clamp(
                                    2,
                                    chartH,
                                  ),
                                  decoration: BoxDecoration(
                                    color: days[i].rate == null
                                        ? AppColors.line
                                        : AppColors.brand.withValues(
                                            alpha: i == sel ? 1 : 0.85,
                                          ),
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(4),
                                    ),
                                    border: i == sel
                                        ? Border.all(
                                            color: AppColors.ink,
                                            width: 2,
                                          )
                                        : null,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            for (var i = 0; i < days.length; i++)
              Expanded(
                child: Text(
                  name(i),
                  textAlign: TextAlign.center,
                  style: dsText(
                    11,
                    weight: i == sel ? FontWeight.w700 : FontWeight.w400,
                    color: i == sel ? AppColors.ink : AppColors.muted,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
