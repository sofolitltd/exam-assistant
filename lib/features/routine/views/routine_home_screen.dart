import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../controllers/routine_controller.dart';
import '../data/models/routine_block_model.dart';
import '../data/models/routine_log_model.dart';
import '../data/models/streak_models.dart';
import '../data/models/user_routine_model.dart';
import 'routine_checkin_sheet.dart';
import 'routine_setup_screen.dart';

class RoutineHomeScreen extends ConsumerWidget {
  const RoutineHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routineAsync = ref.watch(myRoutineProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('রুটিন'),
        actions: [
          IconButton(
            icon: const Icon(Icons.groups_outlined),
            tooltip: 'স্টাডি গ্রুপ',
            onPressed: () => context.push('/routine/groups'),
          ),
          IconButton(
            icon: const Icon(Icons.bar_chart),
            tooltip: 'সাপ্তাহিক সামারি',
            onPressed: () => context.push('/routine/weekly-summary'),
          ),
        ],
      ),
      body: routineAsync.when(
        data: (routine) {
          if (routine == null || routine.blocks.isEmpty) {
            return const RoutineSetupScreen();
          }
          return _TodayView(routine: routine);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) =>
            Center(child: Text('রুটিন লোড করা যায়নি: $error')),
      ),
      floatingActionButton: routineAsync.maybeWhen(
        data: (routine) => (routine == null || routine.blocks.isEmpty)
            ? null
            : FloatingActionButton.extended(
                onPressed: () => context.push('/routine/builder'),
                icon: const Icon(Icons.edit),
                label: const Text('এডিট'),
              ),
        orElse: () => null,
      ),
    );
  }
}

class _TodayView extends ConsumerWidget {
  final UserRoutineModel routine;

  const _TodayView({required this.routine});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = DateTime.now();
    final todaysBlocks = routine.sortedBlocks
        .where((b) => b.appliesOn(today))
        .toList();
    final logAsync = ref.watch(todayLogProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(todayLogProvider);
        ref.invalidate(streakProvider);
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ref
              .watch(streakProvider)
              .maybeWhen(
                data: (streak) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _StreakCard(streak: streak),
                ),
                orElse: () => const SizedBox.shrink(),
              ),
          logAsync.when(
            data: (log) => _DailyProgressCard(blocks: todaysBlocks, log: log),
            loading: () => const SizedBox(
              height: 80,
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, _) => Text('আজকের log লোড করা যায়নি: $error'),
          ),
          const SizedBox(height: 16),
          if (todaysBlocks.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: Text('আজ কোনো ব্লক নির্ধারিত নেই।')),
            )
          else
            ...todaysBlocks.map((block) {
              final status = logAsync.value?.statusFor(block.id!);
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: _StatusIcon(status: status),
                  title: Text(block.title),
                  subtitle: Text(
                    '${block.startTime} - ${block.endTime} · ${block.category.label}',
                  ),
                ),
              );
            }),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: todaysBlocks.isEmpty
                ? null
                : () => showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) => RoutineCheckInSheet(
                      blocks: todaysBlocks,
                      existingLog: logAsync.value,
                    ),
                  ),
            icon: const Icon(Icons.fact_check_outlined),
            label: const Text('Check-in করো'),
          ),
        ],
      ),
    );
  }
}

class _StreakCard extends StatelessWidget {
  final StreakInfo streak;

  const _StreakCard({required this.streak});

  static const _dayLetters = ['সো', 'ম', 'বু', 'বৃ', 'শু', 'শ', 'র'];

  @override
  Widget build(BuildContext context) {
    final message = streak.current == 0
        ? 'আজ দিনের অর্ধেক routine মানো — streak শুরু হবে।'
        : streak.todayCounted
        ? 'আজকের দিন গোনা হয়েছে। কাল আবার!'
        : 'আজ check-in করে streak বাঁচাও।';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.accentSoft,
        borderRadius: BorderRadius.circular(AppRadii.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.local_fire_department,
                color: Color(0xFFE07B12),
                size: 30,
              ),
              const SizedBox(width: 8),
              Text(
                '${streak.current} দিনের streak',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const Spacer(),
              Text(
                'সেরা: ${streak.best}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(message, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (final day in streak.lastSevenDays)
                _DayDot(
                  label: _dayLetters[(DateTime.parse(day.date).weekday - 1)],
                  rate: day.rate,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DayDot extends StatelessWidget {
  final String label;
  final double? rate;

  const _DayDot({required this.label, required this.rate});

  @override
  Widget build(BuildContext context) {
    final counted = rate != null && rate! >= 0.5;
    return Column(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: counted
                ? const Color(0xFFE07B12)
                : rate != null
                ? const Color(0xFFF6C98E)
                : Colors.white,
            border: Border.all(color: const Color(0xFFF0D2A8)),
          ),
          child: counted
              ? const Icon(Icons.check, size: 16, color: Colors.white)
              : null,
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 11)),
      ],
    );
  }
}

class _DailyProgressCard extends StatelessWidget {
  final List<dynamic> blocks;
  final RoutineDailyLog log;

  const _DailyProgressCard({required this.blocks, required this.log});

  @override
  Widget build(BuildContext context) {
    final total = blocks.length;
    final done = log.entries
        .where((e) => e.status == RoutineLogStatus.done)
        .length;
    final percent = total == 0 ? 0 : ((done / total) * 100).round();

    return Card(
      color: AppTheme.primaryColor.withValues(alpha: 0.08),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: AppTheme.primaryColor,
              child: Text(
                '$percent%',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                'আজ $done/$total ব্লক সম্পন্ন হয়েছে',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusIcon extends StatelessWidget {
  final RoutineLogStatus? status;

  const _StatusIcon({this.status});

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case RoutineLogStatus.done:
        return const Icon(Icons.check_circle, color: AppTheme.successColor);
      case RoutineLogStatus.partial:
        return const Icon(Icons.remove_circle, color: Colors.orange);
      case RoutineLogStatus.missed:
        return const Icon(Icons.cancel, color: AppTheme.errorColor);
      case null:
        return const Icon(Icons.radio_button_unchecked, color: Colors.grey);
    }
  }
}
