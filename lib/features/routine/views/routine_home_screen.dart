import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/bangla_digits.dart';
import '../../../core/widgets/ds.dart';
import '../../bcs/data/bcs_models.dart';
import '../../bcs/data/bcs_sample_data.dart';
import '../../bcs/data/bcs_api.dart';
import '../../bcs/views/bcs_format.dart';
import '../controllers/routine_controller.dart';
import '../data/models/routine_block_model.dart';
import '../data/models/routine_log_model.dart';
import '../data/models/streak_models.dart';
import '../data/models/user_routine_model.dart';
import '../widgets/routine_ui.dart';
import 'routine_setup_screen.dart';

/// রুটিন tab: streak on top, then today's blocks with one-tap check-in.
class RoutineHomeScreen extends ConsumerWidget {
  const RoutineHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routineAsync = ref.watch(myRoutineProvider);
    return routineAsync.when(
      data: (routine) {
        if (routine == null || routine.blocks.isEmpty) {
          return const RoutineSetupScreen();
        }
        return _TodayView(routine: routine);
      },
      loading: () => const Scaffold(
        backgroundColor: AppColors.canvas,
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        backgroundColor: AppColors.canvas,
        body: Center(child: Text('রুটিন লোড করা যায়নি: $error')),
      ),
    );
  }
}

/// One row in today's list: a routine block, or the edition's live exam
/// placed automatically from the schedule.
class _Row {
  final RoutineBlockModel? block;
  final LiveSlot? slot;
  final int minutes;

  _Row.block(RoutineBlockModel this.block)
    : slot = null,
      minutes = minutesOf(block.startTime);

  _Row.slot(LiveSlot this.slot)
    : block = null,
      minutes = slot.date.hour * 60 + slot.date.minute;
}

class _TodayView extends ConsumerStatefulWidget {
  final UserRoutineModel routine;

  const _TodayView({required this.routine});

  @override
  ConsumerState<_TodayView> createState() => _TodayViewState();
}

class _TodayViewState extends ConsumerState<_TodayView> {
  /// Taps not yet confirmed by a reload of today's log.
  final Map<int, RoutineLogStatus> _pending = {};

  Future<void> _set(int blockId, RoutineLogStatus status) async {
    final previous = _pending[blockId];
    setState(() => _pending[blockId] = status);
    try {
      await ref
          .read(routineControllerProvider.notifier)
          .submitDailyLog(
            date: formatLogDate(DateTime.now()),
            entries: [RoutineLogEntry(blockId: blockId, status: status)],
          );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        if (previous == null) {
          _pending.remove(blockId);
        } else {
          _pending[blockId] = previous;
        }
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('সেভ করা যায়নি: $error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final blocks = widget.routine.sortedBlocks
        .where((b) => b.appliesOn(now) && b.id != null)
        .toList();
    final log = ref.watch(todayLogProvider).value;
    final streakAsync = ref.watch(streakProvider);

    RoutineLogStatus? statusOf(int id) => _pending[id] ?? log?.statusFor(id);

    var score = 0.0;
    for (final b in blocks) {
      final s = statusOf(b.id!);
      if (s == RoutineLogStatus.done) score += 1;
      if (s == RoutineLogStatus.partial) score += 0.5;
    }

    // The running edition's live exam joins today's list on its own.
    final repo = ref.watch(bcsRepositoryProvider);
    final slot = repo.todaySlot();
    final rows = <_Row>[
      for (final b in blocks) _Row.block(b),
      if (isToday(slot.date)) _Row.slot(slot),
    ]..sort((a, b) => a.minutes.compareTo(b.minutes));

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: Column(
        children: [
          _Header(date: now),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                _pending.clear();
                ref.invalidate(todayLogProvider);
                ref.invalidate(streakProvider);
                ref.invalidate(myRoutineProvider);
              },
              child: DsPage(
                children: [
                  _StreakCard(
                    streak: streakAsync.value,
                    blocks: blocks.length,
                    score: score,
                  ),
                  DsCard(
                    onTap: () => context.push('/study-plan'),
                    child: Row(
                      children: [
                        const IconSquare(LucideIcons.calendarClock),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'আজকের পরিকল্পনা',
                                style: dsText(15, weight: FontWeight.w600),
                              ),
                              Text(
                                'পরীক্ষার দিন গুনে কোন বিষয়ে কত সময়',
                                style: dsText(12, color: AppColors.muted),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          LucideIcons.chevronRight,
                          size: 18,
                          color: AppColors.muted,
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: SectionLabel(
                      'আজকের ব্লক',
                      trailing: '✓ করেছি · ½ অর্ধেক · ✕ miss',
                    ),
                  ),
                  if (rows.isEmpty)
                    DsCard(
                      child: Text(
                        'আজ কোনো ব্লক নেই। এডিট-এ গিয়ে আজকের দিনে ব্লক যোগ করো।',
                        style: dsText(14, color: AppColors.muted),
                      ),
                    )
                  else
                    DsListCard(
                      radius: 16,
                      children: [
                        for (final row in rows)
                          row.block != null
                              ? _BlockRow(
                                  block: row.block!,
                                  status: statusOf(row.block!.id!),
                                  now: isNow(row.block!, now),
                                  onSet: (s) => _set(row.block!.id!, s),
                                )
                              : _SlotRow(
                                  slot: row.slot!,
                                  edition: ref.watch(bcsRunningNumberProvider),
                                ),
                      ],
                    ),
                  const _BottomTiles(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final DateTime date;

  const _Header({required this.date});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.paper,
        border: Border(bottom: BorderSide(color: AppColors.line)),
      ),
      child: SafeArea(
        bottom: false,
        child: Container(
          height: 60,
          padding: const EdgeInsets.only(left: 16, right: 8),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'রুটিন',
                      style: dsText(19, weight: FontWeight.w700, height: 1.2),
                    ),
                    Text(
                      bnLongDate(date),
                      style: dsText(12, color: AppColors.muted),
                    ),
                  ],
                ),
              ),
              Material(
                color: AppColors.paper,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: const BorderSide(color: AppColors.lineStrong),
                ),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => context.push('/routine/builder'),
                  child: Container(
                    height: 36,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: [
                        const Icon(LucideIcons.pencil, size: 15),
                        const SizedBox(width: 6),
                        Text(
                          'এডিট',
                          style: dsText(13, weight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StreakCard extends StatelessWidget {
  final StreakInfo? streak;
  final int blocks;
  final double score;

  const _StreakCard({
    required this.streak,
    required this.blocks,
    required this.score,
  });

  @override
  Widget build(BuildContext context) {
    final days = streak?.lastSevenDays ?? const [];
    final pct = blocks == 0 ? 0 : (score / blocks * 100).round();
    final counted = blocks > 0 && score >= blocks / 2;
    final need = blocks == 0 ? 0 : (blocks / 2 - score).ceil().clamp(0, blocks);

    return DsCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(
                child: Text(
                  '${bn(streak?.current ?? 0)} দিনের streak',
                  style: dsText(18, weight: FontWeight.w700),
                ),
              ),
              Text(
                'সেরা ${bn(streak?.best ?? 0)} দিন',
                style: dsText(12, color: AppColors.muted),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              for (var i = 0; i < 7; i++)
                Expanded(child: _dayDot(days, i, pct, counted)),
            ],
          ),
          const SizedBox(height: 12),
          DsBar(
            value: blocks == 0 ? 0 : score / blocks,
            height: 6,
            color: AppColors.success,
            track: AppColors.lineSoft,
          ),
          const SizedBox(height: 6),
          Text(
            blocks == 0
                ? 'আজ কোনো ব্লক নেই।'
                : counted
                ? 'আজকের দিন streak-এ গোনা হয়েছে। বাকি ব্লকগুলোও শেষ করো।'
                : 'আর ${bn(need)}টা ব্লক করলে আজকের দিন streak-এ গোনা হবে।',
            style: dsText(13, color: AppColors.ink2),
          ),
        ],
      ),
    );
  }

  Widget _dayDot(
    List<({String date, double? rate})> days,
    int i,
    int pct,
    bool counted,
  ) {
    final today = i == 6;
    final date = DateTime.now().subtract(Duration(days: 6 - i));
    Widget dot;
    if (today) {
      dot = Container(
        width: 30,
        height: 30,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: counted ? AppColors.success : AppColors.paper,
          border: counted
              ? null
              : Border.all(color: AppColors.success, width: 2),
        ),
        child: Text(
          '${bn(pct)}%',
          style: dsText(
            10,
            weight: FontWeight.w700,
            color: counted ? Colors.white : AppColors.successInk,
          ),
        ),
      );
    } else {
      // lastSevenDays is oldest first and ends today.
      final idx = days.length - 7 + i;
      final rate = idx >= 0 && idx < days.length ? days[idx].rate : null;
      final ok = rate != null && rate >= 0.5;
      dot = Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: ok
              ? AppColors.success
              : rate == null
              ? AppColors.sunken
              : AppColors.paper,
          border: rate != null && !ok
              ? Border.all(color: AppColors.lineStrong)
              : null,
        ),
        child: ok
            ? const Icon(LucideIcons.check, size: 14, color: Colors.white)
            : null,
      );
    }
    return Column(
      children: [
        dot,
        const SizedBox(height: 4),
        Text(
          today ? 'আজ' : weekdayShort(date.weekday),
          style: dsText(
            11,
            weight: today ? FontWeight.w700 : FontWeight.w400,
            color: today ? AppColors.ink : AppColors.muted,
          ),
        ),
      ],
    );
  }
}

class _BlockRow extends StatelessWidget {
  final RoutineBlockModel block;
  final RoutineLogStatus? status;
  final bool now;
  final ValueChanged<RoutineLogStatus> onSet;

  const _BlockRow({
    required this.block,
    required this.status,
    required this.now,
    required this.onSet,
  });

  @override
  Widget build(BuildContext context) {
    final (time, part) = bnClockParts(block.startTime);
    final meta = [
      block.category.label,
      if (block.category == RoutineBlockCategory.study) bnDuration(block),
      ?block.subjectName,
    ].join(' · ');

    return Container(
      color: now ? const Color(0xFFF3F6FE) : null,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          SizedBox(
            width: 58,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(time, style: dsText(13, weight: FontWeight.w600)),
                Text(part, style: dsText(11, color: AppColors.muted)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  block.title,
                  style: dsText(15, weight: FontWeight.w600, height: 1.3),
                ),
                const SizedBox(height: 3),
                Wrap(
                  spacing: 6,
                  runSpacing: 2,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(meta, style: dsText(12, color: AppColors.muted)),
                    if (now) const _Tag('এখন', AppColors.brand, Colors.white),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          _CheckButton(
            label: '✓',
            tooltip: 'করেছি',
            on: status == RoutineLogStatus.done,
            color: AppColors.success,
            onTap: () => onSet(RoutineLogStatus.done),
          ),
          const SizedBox(width: 4),
          _CheckButton(
            label: '½',
            tooltip: 'অর্ধেক',
            on: status == RoutineLogStatus.partial,
            color: const Color(0xFFB45309),
            onTap: () => onSet(RoutineLogStatus.partial),
          ),
          const SizedBox(width: 4),
          _CheckButton(
            label: '✕',
            tooltip: 'miss',
            on: status == RoutineLogStatus.missed,
            color: AppColors.danger,
            onTap: () => onSet(RoutineLogStatus.missed),
          ),
        ],
      ),
    );
  }
}

class _SlotRow extends StatelessWidget {
  final LiveSlot slot;
  final int edition;

  const _SlotRow({required this.slot, required this.edition});

  @override
  Widget build(BuildContext context) {
    final t = bnTime(slot.date).split(' ');
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          SizedBox(
            width: 58,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.last, style: dsText(13, weight: FontWeight.w600)),
                Text(t.first, style: dsText(11, color: AppColors.muted)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Live exam: ${slot.subject.split(' ').first}',
                  style: dsText(15, weight: FontWeight.w600, height: 1.3),
                ),
                const SizedBox(height: 3),
                Wrap(
                  spacing: 6,
                  runSpacing: 2,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      '${editionName(edition)} · ${bn(slot.minutes)} মিনিট',
                      style: dsText(12, color: AppColors.muted),
                    ),
                    const _Tag(
                      'সূচি থেকে',
                      AppColors.liveSoft,
                      AppColors.liveInk,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          DsButton(
            label: 'খোলো',
            height: 34,
            fontSize: 13,
            onPressed: () => context.push('/bcs/$edition'),
          ),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String text;
  final Color bg;
  final Color fg;

  const _Tag(this.text, this.bg, this.fg);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: dsText(11, weight: FontWeight.w700, color: fg),
      ),
    );
  }
}

class _CheckButton extends StatelessWidget {
  final String label;
  final String tooltip;
  final bool on;
  final Color color;
  final VoidCallback onTap;

  const _CheckButton({
    required this.label,
    required this.tooltip,
    required this.on,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: on,
      label: tooltip,
      child: Material(
        color: on ? color : AppColors.paper,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: on
              ? BorderSide.none
              : const BorderSide(color: Color(0xFFDADDE1)),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: on ? null : onTap,
          child: SizedBox(
            width: 34,
            height: 34,
            child: Center(
              child: Text(
                label,
                style: dsText(
                  15,
                  weight: FontWeight.w700,
                  color: on ? Colors.white : const Color(0xFF8A919C),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Weekly summary and study group shortcuts, each with one live number.
class _BottomTiles extends ConsumerWidget {
  const _BottomTiles();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final monday = mostRecentMonday(DateTime.now());
    final week = ref.watch(weeklySummaryProvider(monday)).value;
    final prev = ref
        .watch(weeklySummaryProvider(monday.subtract(const Duration(days: 7))))
        .value;
    final groups = ref.watch(studyGroupsProvider).value ?? const [];
    final detail = groups.isEmpty
        ? null
        : ref.watch(studyGroupDetailProvider(groups.first.groupId)).value;

    String weekText = 'এই সপ্তাহের হিসাব';
    Color weekColor = AppColors.muted;
    if (week != null) {
      final pct = (week.completionRate * 100).round();
      weekText = 'এই সপ্তাহ ${bn(pct)}%';
      if (prev != null && prev.blocks.isNotEmpty) {
        final delta = pct - (prev.completionRate * 100).round();
        weekText += delta >= 0 ? ' · ▲ ${bn(delta)}%' : ' · ▼ ${bn(-delta)}%';
        weekColor = delta >= 0 ? AppColors.success : AppColors.danger;
      }
    }

    String groupText = 'বন্ধুদের সাথে পড়ো';
    if (detail != null) {
      final done = detail.members.where((m) => m.checkedInToday).length;
      groupText = '${bn(detail.members.length)} জনের ${bn(done)} জন আজ করেছে';
    }

    return DsGrid(
      children: [
        InfoTile(
          title: 'সাপ্তাহিক সামারি',
          subtitle: weekText,
          subtitleColor: weekColor,
          onTap: () => context.push('/routine/weekly-summary'),
        ),
        InfoTile(
          title: 'স্টাডি গ্রুপ',
          subtitle: groupText,
          onTap: () => context.push('/routine/groups'),
        ),
      ],
    );
  }
}
