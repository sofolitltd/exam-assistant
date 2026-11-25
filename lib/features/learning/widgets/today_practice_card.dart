import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/bangla_digits.dart';
import '../../../core/widgets/ds.dart';
import '../controllers/learning_providers.dart';
import '../data/practice_models.dart';

/// "আজ": questions answered today against the streak target, the streak,
/// and the two things waiting (review due, open mistakes). Shown on home
/// and on the অনুশীলন tab. Hidden while loading; offline it falls back to
/// the two task buttons without counts.
class TodayPracticeCard extends ConsumerWidget {
  const TodayPracticeCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(practiceSummaryProvider);
    final summary = async.value;
    if (summary != null) return _Card(summary: summary);
    if (!async.hasError) return const SizedBox.shrink();
    // Offline: still offer the two tasks, without counts.
    return Row(
      children: [
        Expanded(
          child: _Task(
            icon: LucideIcons.repeat,
            title: 'রিভিশন',
            value: 'আজকের প্রশ্ন',
            urgent: false,
            onTap: () => context.push('/practice/review'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _Task(
            icon: LucideIcons.circleX,
            title: 'আমার ভুল',
            value: 'আবার দাও',
            urgent: false,
            onTap: () => context.push('/practice/mistakes'),
          ),
        ),
      ],
    );
  }
}

class _Card extends StatelessWidget {
  final PracticeSummary summary;

  const _Card({required this.summary});

  @override
  Widget build(BuildContext context) {
    final s = summary;
    final target = s.streak.minAnswers;
    final done = s.streak.todayCounted;
    final headline = done
        ? 'আজকের লক্ষ্য পূরণ হয়েছে'
        : s.todayAll == 0
        ? 'আজ এখনো শুরু করোনি'
        : 'আজ আর ${bn(s.todayLeft)}টি প্রশ্ন';
    return DsCard(
      onTap: () => context.push('/progress'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  headline,
                  style: dsText(16, weight: FontWeight.w700),
                ),
              ),
              _StreakPill(days: s.streak.current, active: done),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'আজ ${bn(s.todayAll)}টি প্রশ্ন · দিনে অন্তত ${bn(target)}টি করলে streak বাড়ে',
            style: dsText(12, color: AppColors.muted, height: 1.5),
          ),
          const SizedBox(height: 10),
          DsBar(
            value: target == 0 ? 1 : (s.todayAll / target).clamp(0, 1),
            color: done ? AppColors.success : AppColors.brand,
            height: 6,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _Task(
                  icon: LucideIcons.repeat,
                  title: 'রিভিশন',
                  value: s.reviewDue == 0
                      ? 'আজ বাকি নেই'
                      : '${bn(s.reviewDue)}টি বাকি',
                  urgent: s.reviewDue > 0,
                  onTap: () => context.push('/practice/review'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _Task(
                  icon: LucideIcons.circleX,
                  title: 'আমার ভুল',
                  value: s.mistakes == 0
                      ? 'কোনো ভুল নেই'
                      : '${bn(s.mistakes)}টি ঠিক করো',
                  urgent: s.mistakes > 0,
                  onTap: () => context.push('/practice/mistakes'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StreakPill extends StatelessWidget {
  final int days;
  final bool active;

  const _StreakPill({required this.days, required this.active});

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.success : AppColors.ink2;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: active ? AppColors.successSoft : AppColors.sunken,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.flame, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            'টানা ${bn(days)} দিন',
            style: dsText(12, weight: FontWeight.w600, color: color),
          ),
        ],
      ),
    );
  }
}

class _Task extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final bool urgent;
  final VoidCallback onTap;

  const _Task({
    required this.icon,
    required this.title,
    required this.value,
    required this.urgent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.canvas,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: urgent ? AppColors.brand : AppColors.muted,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(title, style: dsText(13, weight: FontWeight.w600)),
                      Text(
                        value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: dsText(
                          12,
                          color: urgent ? AppColors.danger : AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
