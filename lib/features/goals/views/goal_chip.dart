import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/bangla_digits.dart';
import '../../../core/widgets/ds.dart';
import '../data/goals.dart';
import 'goals_sheet.dart';

/// The primary goal as a small chip at the top of the home and অনুশীলন
/// tabs: "বিশেষ বিসিএস · আর ১৭ দিন ▾". A tap switches the primary goal;
/// with no goal yet it opens the goals sheet. Hidden while loading or on an
/// error, so it never pushes the page down with a spinner.
class GoalChip extends ConsumerWidget {
  const GoalChip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goals = ref.watch(goalsProvider).value;
    if (goals == null) return const SizedBox.shrink();
    final primary = goals.isEmpty ? null : goals.first;
    final label = primary == null
        ? 'কোন পরীক্ষার প্রস্তুতি? বেছে নাও'
        : primary.daysLeft == null
        ? primary.shortTitle
        : '${primary.shortTitle} · আর ${bn(primary.daysLeft!)} দিন';

    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Material(
          color: AppColors.brandSoft,
          borderRadius: BorderRadius.circular(999),
          child: InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: () => primary == null
                ? showGoalsSheet(context)
                : _showSwitcher(context),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 36),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      LucideIcons.target,
                      size: 16,
                      color: AppColors.brandStrong,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: dsText(
                          13,
                          weight: FontWeight.w600,
                          color: AppColors.brandStrong,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      LucideIcons.chevronDown,
                      size: 16,
                      color: AppColors.brandStrong,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> _showSwitcher(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    backgroundColor: AppColors.paper,
    builder: (_) => _GoalSwitcher(parent: context),
  );
}

/// "এখন কোনটা পড়ছ?": one tap makes a goal primary.
class _GoalSwitcher extends ConsumerStatefulWidget {
  /// The page under the sheet, for opening the goals sheet after this one
  /// closes.
  final BuildContext parent;

  const _GoalSwitcher({required this.parent});

  @override
  ConsumerState<_GoalSwitcher> createState() => _GoalSwitcherState();
}

class _GoalSwitcherState extends ConsumerState<_GoalSwitcher> {
  int? _saving;
  String? _error;

  Future<void> _pick(UserGoal goal) async {
    if (goal.isPrimary) {
      Navigator.of(context).pop();
      return;
    }
    setState(() {
      _saving = goal.id;
      _error = null;
    });
    try {
      await ref.read(goalsProvider.notifier).makePrimary(goal.id);
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = null;
          _error = 'বদলানো যায়নি, আবার চেষ্টা করো';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final goals = ref.watch(goalsProvider).value ?? const <UserGoal>[];
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('এখন কোনটা পড়ছ?', style: dsText(18, weight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(
              'প্রধান লক্ষ্যের তারিখ ধরে আজকের পরিকল্পনা সাজে।',
              style: dsText(13, color: AppColors.muted),
            ),
            const SizedBox(height: 12),
            for (final goal in goals)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: DsCard(
                  color: goal.isPrimary ? AppColors.brandSoft : AppColors.paper,
                  borderColor: goal.isPrimary
                      ? AppColors.brand
                      : AppColors.lineStrong,
                  radius: 12,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  onTap: _saving == null ? () => _pick(goal) : null,
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              goal.title,
                              style: dsText(15, weight: FontWeight.w600),
                            ),
                            Text(
                              goal.detail,
                              style: dsText(12, color: AppColors.muted),
                            ),
                          ],
                        ),
                      ),
                      if (_saving == goal.id)
                        const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      else if (goal.isPrimary)
                        const Icon(
                          LucideIcons.check,
                          size: 18,
                          color: AppColors.brand,
                        ),
                    ],
                  ),
                ),
              ),
            if (_error != null)
              Text(_error!, style: dsText(13, color: AppColors.danger)),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                if (widget.parent.mounted) showGoalsSheet(widget.parent);
              },
              child: const Text('লক্ষ্য সাজাও'),
            ),
          ],
        ),
      ),
    );
  }
}
