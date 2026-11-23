import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/bangla_digits.dart';
import '../../../core/widgets/ds.dart';
import '../data/goals.dart';

/// The goals card on the profile: the primary goal, its countdown, and the
/// other goals. Tapping it opens [showGoalsSheet].
class GoalsCard extends ConsumerWidget {
  const GoalsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(goalsProvider);
    final goals = async.value;
    final primary = goals == null || goals.isEmpty ? null : goals.first;
    final others = goals == null ? const <UserGoal>[] : goals.skip(1).toList();

    final String title;
    final String? detail;
    if (goals == null) {
      title = async.hasError ? 'লক্ষ্য লোড করা যায়নি' : 'লোড হচ্ছে…';
      detail = async.hasError ? 'আবার চেষ্টা করতে চাপো' : null;
    } else if (primary == null) {
      title = 'কোন পরীক্ষার প্রস্তুতি নিচ্ছ?';
      detail = 'বেছে নিলে আজকের পরিকল্পনা সেই হিসাবে সাজবে';
    } else {
      title = primary.title;
      detail = primary.detail;
    }

    return DsCard(
      color: AppColors.brandSoft,
      borderWidth: 0,
      radius: 12,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      onTap: () {
        if (goals == null) {
          ref.invalidate(goalsProvider);
        } else {
          showGoalsSheet(context);
        }
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      others.isEmpty ? 'আমার লক্ষ্য' : 'প্রধান লক্ষ্য',
                      style: dsText(12, color: AppColors.brandInk2),
                    ),
                    Text(
                      title,
                      style: dsText(
                        15,
                        weight: FontWeight.w600,
                        color: AppColors.brandStrong,
                      ),
                    ),
                    if (detail != null)
                      Text(
                        detail,
                        style: dsText(12, color: AppColors.brandInk2),
                      ),
                  ],
                ),
              ),
              Text(
                primary == null && goals != null ? 'বেছে নাও' : 'বদলাও',
                style: dsText(
                  13,
                  weight: FontWeight.w600,
                  color: AppColors.brandStrong,
                ),
              ),
            ],
          ),
          if (others.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'সাথে: ${others.map((g) => g.shortTitle).join(' · ')}',
              style: dsText(12, color: AppColors.brandInk2),
            ),
          ],
          if (primary != null && !primary.hasQuestions && !primary.isBcs) ...[
            const SizedBox(height: 6),
            Text(
              'এই পরীক্ষার প্রশ্ন শীঘ্রই আসছে। বাংলা, ইংরেজি, গণিত আর সাধারণ '
              'জ্ঞানের অনুশীলন এখানেও কাজে লাগবে।',
              style: dsText(12, height: 1.4, color: AppColors.brandInk2),
            ),
          ],
        ],
      ),
    );
  }
}

/// "আমার লক্ষ্য": the learner's goals (up to [maxGoals]), which one is
/// primary, each one's date, and adding or removing one.
Future<void> showGoalsSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    backgroundColor: AppColors.paper,
    builder: (_) => const _GoalsSheet(),
  );
}

class _GoalsSheet extends ConsumerStatefulWidget {
  const _GoalsSheet();

  @override
  ConsumerState<_GoalsSheet> createState() => _GoalsSheetState();
}

class _GoalsSheetState extends ConsumerState<_GoalsSheet> {
  bool _adding = false;
  bool _busy = false;
  String? _error;

  Future<void> _run(Future<void> Function() action) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'সংরক্ষণ করা যায়নি, আবার চেষ্টা করো');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  GoalsNotifier get _goals => ref.read(goalsProvider.notifier);

  Future<void> _pickDate(UserGoal goal) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate:
          goal.examDate ?? goal.targetDate ?? now.add(const Duration(days: 30)),
      firstDate: now,
      lastDate: DateTime(now.year + 3, now.month, now.day),
    );
    if (picked == null) return;
    await _run(
      () => _goals.edit(
        goal.id,
        variant: goal.variant,
        editionNumber: goal.editionNumber,
        examDate: picked,
      ),
    );
  }

  Future<void> _clearDate(UserGoal goal) => _run(
    () => _goals.edit(
      goal.id,
      variant: goal.variant,
      editionNumber: goal.editionNumber,
    ),
  );

  Future<void> _remove(UserGoal goal) async {
    final ok = await showConfirmDialog(
      context,
      title: '${goal.shortTitle} লক্ষ্য থেকে সরাবে?',
      message: 'তোমার অনুশীলন আর ফল থেকে যাবে।',
      confirmLabel: 'সরাও',
      destructive: true,
    );
    if (ok) await _run(() => _goals.remove(goal.id));
  }

  Future<void> _add(String code, {String? variant}) async {
    await _run(() => _goals.add(code, variant: variant));
    if (mounted && _error == null) setState(() => _adding = false);
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
            Text(
              _adding ? 'কোন পরীক্ষা যোগ করবে?' : 'আমার লক্ষ্য',
              style: dsText(18, weight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              _adding
                  ? 'বাংলা, ইংরেজি, গণিত আর সাধারণ জ্ঞানের অনুশীলন সব '
                        'লক্ষ্যেই গোনা হবে।'
                  : 'সর্বোচ্চ ${bn(maxGoals)}টা। প্রধান লক্ষ্যের তারিখ ধরে '
                        'আজকের পরিকল্পনা সাজে।',
              style: dsText(13, height: 1.4, color: AppColors.muted),
            ),
            const SizedBox(height: 12),
            if (_adding)
              ..._programOptions(goals)
            else ...[
              for (final goal in goals) _goalRow(goal, goals.length),
              if (goals.length < maxGoals)
                DsButton.secondary(
                  label: goals.isEmpty ? 'লক্ষ্য বেছে নাও' : 'লক্ষ্য যোগ করো',
                  onPressed: _busy
                      ? null
                      : () => setState(() => _adding = true),
                ),
            ],
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  _error!,
                  style: dsText(13, color: AppColors.danger),
                ),
              ),
            if (_adding)
              TextButton(
                onPressed: _busy ? null : () => setState(() => _adding = false),
                child: const Text('ফিরে যাও'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _goalRow(UserGoal goal, int count) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: DsCard(
        color: goal.isPrimary ? AppColors.brandSoft : AppColors.paper,
        borderColor: goal.isPrimary ? AppColors.brand : AppColors.lineStrong,
        radius: 12,
        padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(goal.title, style: dsText(15, weight: FontWeight.w600)),
                  Text(goal.detail, style: dsText(12, color: AppColors.muted)),
                  const SizedBox(height: 4),
                  if (goal.isPrimary)
                    Text(
                      'প্রধান',
                      style: dsText(
                        12,
                        weight: FontWeight.w600,
                        color: AppColors.brandStrong,
                      ),
                    )
                  else
                    InkWell(
                      onTap: _busy
                          ? null
                          : () => _run(() => _goals.makePrimary(goal.id)),
                      child: Text(
                        'প্রধান করো',
                        style: dsText(
                          12,
                          weight: FontWeight.w600,
                          color: AppColors.brand,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'পরীক্ষার তারিখ',
              onPressed: _busy ? null : () => _pickDate(goal),
              icon: const Icon(LucideIcons.calendar, size: 18),
            ),
            if (goal.examDate != null)
              IconButton(
                tooltip: 'নিজের তারিখ মুছো',
                onPressed: _busy ? null : () => _clearDate(goal),
                icon: const Icon(LucideIcons.calendarX, size: 18),
              ),
            IconButton(
              tooltip: 'সরাও',
              onPressed: _busy ? null : () => _remove(goal),
              icon: const Icon(
                LucideIcons.trash2,
                size: 18,
                color: AppColors.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _programOptions(List<UserGoal> goals) {
    final programsAsync = ref.watch(goalProgramsProvider);
    final programs = programsAsync.value;
    if (programs == null) {
      return [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: programsAsync.hasError
              ? DsButton.secondary(
                  label: 'আবার চেষ্টা করো',
                  onPressed: () => ref.invalidate(goalProgramsProvider),
                )
              : const Center(child: CircularProgressIndicator()),
        ),
      ];
    }
    bool taken(String code, [String? variant]) => goals.any(
      (g) =>
          g.programCode == code &&
          (code != 'BCS' || (g.variant ?? 'general') == variant),
    );
    final options = <(String, String?, String, String?)>[];
    for (final p in programs) {
      final soon = p.hasQuestions ? null : 'প্রশ্ন শীঘ্রই আসছে';
      if (p.isBcs) {
        if (!taken(p.code, 'general')) {
          options.add((p.code, 'general', p.label, null));
        }
        if (!taken(p.code, 'special')) {
          options.add((
            p.code,
            'special',
            'বিশেষ ${p.label}',
            'স্বাস্থ্য, শিক্ষা…',
          ));
        }
      } else if (!taken(p.code)) {
        options.add((p.code, null, p.label, soon));
      }
    }
    if (options.isEmpty) {
      return [
        Text(
          'সব পরীক্ষা যোগ করা আছে।',
          style: dsText(14, color: AppColors.muted),
        ),
      ];
    }
    return [
      for (final (code, variant, label, note) in options)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: DsCard(
            radius: 12,
            borderColor: AppColors.lineStrong,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            onTap: _busy ? null : () => _add(code, variant: variant),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: dsText(15, weight: FontWeight.w600),
                  ),
                ),
                if (note != null)
                  Text(note, style: dsText(12, color: AppColors.muted)),
              ],
            ),
          ),
        ),
    ];
  }
}
