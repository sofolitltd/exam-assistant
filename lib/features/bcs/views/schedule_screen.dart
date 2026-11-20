import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/bangla_digits.dart';
import '../../../core/widgets/ds.dart';
import '../data/bcs_models.dart';
import '../data/bcs_sample_data.dart';
import 'bcs_format.dart';

enum _Filter { all, upcoming, done, missed }

class ScheduleScreen extends ConsumerStatefulWidget {
  final int number;

  const ScheduleScreen({required this.number, super.key});

  @override
  ConsumerState<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends ConsumerState<ScheduleScreen> {
  _Filter _filter = _Filter.all;

  bool _matches(LiveSlot s) {
    switch (_filter) {
      case _Filter.all:
        return true;
      case _Filter.upcoming:
        return s.state == SlotState.today || s.state == SlotState.upcoming;
      case _Filter.done:
        return s.state == SlotState.done;
      case _Filter.missed:
        return s.state == SlotState.missed;
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(bcsRepositoryProvider);
    final edition = repo.edition(widget.number);
    final all = repo.schedule();
    final (done, total) = repo.preparationProgress();
    final missed = all.where((s) => s.state == SlotState.missed).length;
    final slots = all.where(_matches).toList();

    final now = DateTime.now();
    final weekEnd = DateTime(
      now.year,
      now.month,
      now.day,
    ).add(Duration(days: 7 - now.weekday % 7));
    final thisWeek = slots.where((s) => s.date.isBefore(weekEnd)).toList();
    final later = slots.where((s) => !s.date.isBefore(weekEnd)).toList();

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: DsHeader(
        title: 'পরীক্ষার সূচি',
        subtitle: editionName(widget.number),
        trailing: edition.status == EditionStatus.running
            ? const LivePill('চলছে')
            : const NeutralPill('শেষ'),
      ),
      body: DsPage(
        gap: 10,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '১০০ দিনের প্রস্তুতি',
                  style: dsText(13, weight: FontWeight.w600),
                ),
              ),
              Text(
                '${bn(total)}টার মধ্যে ${bn(done)}টা হয়েছে',
                style: dsText(13, color: AppColors.muted),
              ),
            ],
          ),
          DsBar(value: done / total, height: 6),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final (f, label) in [
                  (_Filter.all, 'সব'),
                  (_Filter.upcoming, 'সামনে'),
                  (_Filter.done, 'দিয়েছি'),
                  (_Filter.missed, 'মিস (${bn(missed)})'),
                ]) ...[
                  DsChip(
                    label: label,
                    height: 32,
                    selected: _filter == f,
                    onTap: () => setState(() => _filter = f),
                  ),
                  const SizedBox(width: 6),
                ],
              ],
            ),
          ),
          if (thisWeek.isNotEmpty) ...[
            _weekLabel('এই সপ্তাহ'),
            DsListCard(children: [for (final s in thisWeek) _row(s)]),
          ],
          if (later.isNotEmpty) ...[
            _weekLabel('সামনের সপ্তাহ'),
            DsListCard(children: [for (final s in later) _row(s)]),
          ],
          if (slots.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'এখানে কিছু নেই',
                textAlign: TextAlign.center,
                style: dsText(13, color: AppColors.muted),
              ),
            ),
        ],
      ),
    );
  }

  Widget _weekLabel(String text) => Padding(
    padding: const EdgeInsets.only(top: 4),
    child: Text(
      text,
      style: dsText(12, weight: FontWeight.w600, color: AppColors.muted),
    ),
  );

  Widget _row(LiveSlot s) {
    final n = widget.number;
    final today = s.state == SlotState.today;
    String sub;
    Color subColor = AppColors.muted;
    Widget? trailing;
    VoidCallback? onTap;

    switch (s.state) {
      case SlotState.missed:
        sub = 'মিস করেছ';
        subColor = AppColors.danger;
        trailing = DsSmallButton(
          label: 'অনুশীলন',
          onPressed: () => context.push('/bcs/$n/practice'),
        );
      case SlotState.done:
        sub = 'মেধাক্রম ${bn(s.rank ?? 0)}';
        trailing = Text(
          '${bnScore(s.score ?? 0)}/${bnScore(s.fullMarks ?? 0)}',
          style: dsText(14, weight: FontWeight.w700, color: AppColors.success),
        );
        onTap = () => context.push('/bcs/$n/merit');
      case SlotState.today:
      case SlotState.upcoming:
        sub =
            '${bn(s.questions)} প্রশ্ন · ${bn(s.minutes)} মিনিট'
            '${s.materials > 0 ? ' · উপকরণ ${bn(s.materials)}' : ''}';
        if (today) {
          trailing = Text(
            bnTime(s.date),
            style: dsText(
              13,
              weight: FontWeight.w600,
              color: AppColors.liveInk,
            ),
          );
          onTap = () => context.pop();
        }
    }

    return Material(
      color: today ? AppColors.brandSoft : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              SizedBox(
                width: 44,
                child: Column(
                  children: [
                    Text(
                      bnDay(s.date),
                      style: dsText(
                        17,
                        weight: FontWeight.w700,
                        height: 1.1,
                        color: today ? AppColors.brand : AppColors.ink,
                      ),
                    ),
                    Text(
                      today ? 'আজ' : bnWeekday(s.date),
                      style: dsText(
                        11,
                        color: today ? AppColors.brand : AppColors.muted,
                        weight: today ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.subject, style: dsText(14, weight: FontWeight.w600)),
                    Text(sub, style: dsText(12, color: subColor)),
                  ],
                ),
              ),
              ?trailing,
            ],
          ),
        ),
      ),
    );
  }
}
