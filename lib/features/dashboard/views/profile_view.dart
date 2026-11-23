import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/router/app_router.dart';
import '../../../core/settings/app_settings.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/bangla_digits.dart';
import '../../../core/widgets/ds.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../goals/data/goals.dart';
import '../../goals/views/goals_sheet.dart';
import '../../learning/controllers/learning_providers.dart';
import '../../learning/data/learning_models.dart';
import '../../learning/widgets/accuracy_chart.dart';
import '../../routine/controllers/routine_controller.dart';
import '../../routine/controllers/study_plan_provider.dart';
import '../controllers/stats_controller.dart';

/// প্রোফাইল: who you are and your goal, four numbers, the recent trend,
/// your weakest subjects, the study tools, then settings.
class ProfileView extends ConsumerWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userStatsProvider);
    final user = userAsync.value;
    final resultsAsync = ref.watch(userExamResultsProvider);
    final results = [...?resultsAsync.value]
      ..sort((a, b) => a.answeredAt.compareTo(b.answeredAt));
    final streak = ref.watch(streakProvider).value;
    final subjectsAsync = ref.watch(subjectPerformanceByDaysProvider(30));
    final mistakes = ref.watch(mistakesProvider(null));
    final plan = ref.watch(studyPlanProvider).value;
    final due = ref.watch(dueReviewsProvider).value;
    final groups = ref.watch(studyGroupsProvider).value;
    final textSize = ref.watch(textSizeProvider).value ?? TextSize.medium;
    final reminders = ref.watch(reminderPrefsProvider).value;

    final pcts = [for (final r in results) r.percentage];
    final avg = pcts.isEmpty
        ? null
        : pcts.reduce((a, b) => a + b) / pcts.length;
    final best = pcts.isEmpty ? null : pcts.reduce((a, b) => a > b ? a : b);
    final last10 = pcts.length > 10 ? pcts.sublist(pcts.length - 10) : pcts;

    final subjects = [...?subjectsAsync.value?.where((s) => s.attempted > 0)]
      ..sort((a, b) => a.accuracy.compareTo(b.accuracy));
    // One or two answers say little: ask for a few before calling a subject
    // weak.
    final weakest = subjects.where((s) => s.attempted >= 5).take(3).toList();

    final name = user?.name.isNotEmpty == true ? user!.name : 'নাম নেই';
    final contact = user == null
        ? ''
        : user.phone.isNotEmpty
        ? '${bn(user.phone)} · ${user.email}'
        : user.email;

    final mistakesText = mistakes.items.isEmpty
        ? (mistakes.isLoading ? 'লোড হচ্ছে…' : 'কোনো ভুল নেই')
        : '${bn(mistakes.items.length)}${mistakes.hasMore ? '+' : ''}টি বাকি';

    final enabledReminders = reminders == null
        ? null
        : [
            reminders.afternoon,
            reminders.night,
            reminders.weekly,
          ].where((e) => e).length;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: Column(
        children: [
          DecoratedBox(
            decoration: const BoxDecoration(
              color: AppColors.paper,
              border: Border(bottom: BorderSide(color: AppColors.line)),
            ),
            child: SafeArea(
              bottom: false,
              child: Container(
                height: 60,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                alignment: Alignment.centerLeft,
                child: Text(
                  'প্রোফাইল',
                  style: dsText(19, weight: FontWeight.w700),
                ),
              ),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(userProfileProvider);
                ref.invalidate(userExamResultsProvider);
                ref.invalidate(streakProvider);
                ref.invalidate(studyPlanProvider);
                ref.invalidate(goalsProvider);
                ref.invalidate(dueReviewsProvider);
                ref.invalidate(studyGroupsProvider);
                ref.invalidate(subjectPerformanceByDaysProvider(30));
                await ref.read(mistakesProvider(null).notifier).refresh();
              },
              child: DsPage(
                children: [
                  if (userAsync.hasError && user == null)
                    DsCard(
                      color: AppColors.dangerSoft,
                      borderWidth: 0,
                      padding: const EdgeInsets.all(14),
                      onTap: () => ref.invalidate(userProfileProvider),
                      child: Text(
                        'প্রোফাইল লোড করা যায়নি। আবার চেষ্টা করতে এখানে চাপো।',
                        style: dsText(14, color: AppColors.danger),
                      ),
                    ),
                  DsCard(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              alignment: Alignment.center,
                              decoration: const BoxDecoration(
                                color: AppColors.brand,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                name.characters.first,
                                style: dsText(
                                  22,
                                  weight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    style: dsText(18, weight: FontWeight.w700),
                                  ),
                                  if (contact.isNotEmpty)
                                    Text(
                                      contact,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: dsText(12, color: AppColors.muted),
                                    ),
                                ],
                              ),
                            ),
                            DsSmallButton(
                              label: 'এডিট',
                              onPressed: () => context.push('/profile/edit'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        const GoalsCard(),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            _stat(
                              bn(user?.totalExamsAttended ?? results.length),
                              'পরীক্ষা',
                            ),
                            _stat(
                              avg == null ? '—' : '${bn(avg.round())}%',
                              'গড়',
                            ),
                            _stat(
                              best == null ? '—' : '${bn(best.round())}%',
                              'সেরা',
                            ),
                            _stat('${bn(streak?.current ?? 0)} দিন', 'streak'),
                          ],
                        ),
                        if (streak != null) ...[
                          const SizedBox(height: 10),
                          Text(
                            'সবচেয়ে লম্বা streak ${bn(streak.best)} দিন · '
                            '${streak.todayCounted ? 'আজ গণনা হয়েছে' : 'আজ এখনো গণনা হয়নি'}',
                            textAlign: TextAlign.center,
                            style: dsText(12, color: AppColors.muted),
                          ),
                        ],
                      ],
                    ),
                  ),
                  DsCard(
                    onTap: () => context.push('/profile/results'),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                last10.isEmpty
                                    ? 'পরীক্ষার ফল'
                                    : 'শেষ ${bn(last10.length)} পরীক্ষার ফল',
                                style: dsText(15, weight: FontWeight.w600),
                              ),
                            ),
                            Text(
                              'সব ফল',
                              style: dsText(
                                13,
                                weight: FontWeight.w600,
                                color: AppColors.brand,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (last10.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            child: Text(
                              resultsAsync.hasError
                                  ? 'ফল লোড করা যায়নি'
                                  : 'পরীক্ষা দিলে ফলের ধারা এখানে দেখা যাবে',
                              textAlign: TextAlign.center,
                              style: dsText(13, color: AppColors.muted),
                            ),
                          )
                        else
                          AccuracyChart(values: last10, height: 96),
                      ],
                    ),
                  ),
                  if (weakest.isNotEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.only(top: 2),
                      child: SectionLabel(
                        'সবচেয়ে দুর্বল বিষয়',
                        trailing: 'গত ৩০ দিন',
                      ),
                    ),
                    DsListCard(
                      radius: 16,
                      children: [for (final s in weakest) _WeakRow(subject: s)],
                    ),
                  ],
                  const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: SectionLabel('পড়াশোনা'),
                  ),
                  DsGrid(
                    children: [
                      InfoTile(
                        title: 'আজকের পরিকল্পনা',
                        minHeight: 72,
                        subtitle: plan?.daysLeft == null
                            ? 'আজ কী পড়বে'
                            : 'পরীক্ষা পর্যন্ত ${bn(plan!.daysLeft!)} দিন',
                        onTap: () => context.push('/study-plan'),
                      ),
                      InfoTile(
                        title: 'আজকের রিভিশন',
                        minHeight: 72,
                        subtitle: due == null
                            ? 'ভুলের রিভিশন'
                            : due.summary.due == 0
                            ? 'আজ কিছু বাকি নেই'
                            : '${bn(due.summary.due)}টি বাকি',
                        subtitleColor: (due?.summary.due ?? 0) > 0
                            ? AppColors.accent
                            : null,
                        onTap: () => context.push('/practice/review'),
                      ),
                      InfoTile(
                        title: 'কোনটা আগে পড়ব',
                        minHeight: 72,
                        subtitle: 'বিগত প্রশ্ন অনুযায়ী',
                        onTap: () => context.push('/study-first'),
                      ),
                      InfoTile(
                        title: 'স্কোর কৌশল',
                        minHeight: 72,
                        subtitle: 'নেগেটিভ মার্কিং',
                        onTap: () => context.push('/strategy'),
                      ),
                      InfoTile(
                        title: 'শুনে পড়ো',
                        minHeight: 72,
                        subtitle: 'প্রশ্ন-উত্তর শোনো',
                        onTap: () => context.push('/listen'),
                      ),
                      InfoTile(
                        title: 'স্টাডি গ্রুপ',
                        minHeight: 72,
                        subtitle: groups == null
                            ? 'বন্ধুদের সাথে'
                            : groups.isEmpty
                            ? 'কোনো গ্রুপে নেই'
                            : '${bn(groups.length)}টি গ্রুপে আছো',
                        onTap: () => context.push('/routine/groups'),
                      ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: SectionLabel('আমার রেকর্ড'),
                  ),
                  DsGrid(
                    children: [
                      InfoTile(
                        title: 'সব ভুল',
                        minHeight: 72,
                        subtitle: mistakesText,
                        subtitleColor: mistakes.items.isEmpty
                            ? null
                            : AppColors.danger,
                        onTap: () => context.push('/practice/mistakes'),
                      ),
                      InfoTile(
                        title: 'সংরক্ষিত',
                        minHeight: 72,
                        subtitle: 'বুকমার্ক করা প্রশ্ন',
                        onTap: () => context.push('/saved'),
                      ),
                      InfoTile(
                        title: 'আমার অগ্রগতি',
                        minHeight: 72,
                        subtitle: subjects.isEmpty
                            ? 'বিষয়ভিত্তিক হিসাব'
                            : '${bn(subjects.length)} বিষয়ের হিসাব',
                        onTap: () => context.push('/progress'),
                      ),
                      InfoTile(
                        title: 'আমার ফল',
                        minHeight: 72,
                        subtitle: results.isEmpty
                            ? 'পরীক্ষার ইতিহাস'
                            : '${bn(results.length)}টি পরীক্ষা',
                        onTap: () => context.push('/profile/results'),
                      ),
                      InfoTile(
                        title: 'সাপ্তাহিক সামারি',
                        minHeight: 72,
                        subtitle: 'রুটিন কতটা মানলে',
                        onTap: () => context.push('/routine/weekly-summary'),
                      ),
                      InfoTile(
                        title: 'লিডারবোর্ড',
                        minHeight: 72,
                        subtitle: 'সেরা ২০ জন',
                        onTap: () => context.push('/leaderboard'),
                      ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: SectionLabel('সেটিংস'),
                  ),
                  DsListCard(
                    radius: 16,
                    children: [
                      _setting(
                        'নোটিফিকেশন ও রিমাইন্ডার',
                        trailing: enabledReminders == null
                            ? null
                            : enabledReminders == 0
                            ? 'বন্ধ'
                            : '${bn(enabledReminders)}টি চালু',
                        onTap: () => context.push('/profile/notifications'),
                      ),
                      _setting(
                        'লেখার আকার',
                        trailing: textSize.label,
                        onTap: () => _pickTextSize(context, ref, textSize),
                      ),
                      _setting(
                        'সাহায্য ও মতামত',
                        onTap: () => context.push('/profile/help'),
                      ),
                      InkWell(
                        onTap: () => _confirmSignOut(context, ref),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 13,
                          ),
                          child: Text(
                            'লগ আউট',
                            style: dsText(
                              15,
                              weight: FontWeight.w600,
                              color: AppColors.danger,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stat(String value, String label) => Expanded(
    child: Column(
      children: [
        Text(value, style: dsText(18, weight: FontWeight.w700)),
        Text(label, style: dsText(11, color: AppColors.muted)),
      ],
    ),
  );

  Widget _setting(String title, {String? trailing, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        child: Row(
          children: [
            Expanded(child: Text(title, style: dsText(15))),
            if (trailing != null) ...[
              Text(trailing, style: dsText(13, color: AppColors.muted)),
              const SizedBox(width: 6),
            ],
            const Icon(
              LucideIcons.chevronRight,
              size: 16,
              color: Color(0xFF8A919C),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeakRow extends StatelessWidget {
  final SubjectPerformance subject;

  const _WeakRow({required this.subject});

  @override
  Widget build(BuildContext context) {
    final pct = (subject.accuracy * 100).round();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${subject.name} · ${bn(pct)}%',
                  style: dsText(14, weight: FontWeight.w600),
                ),
                const SizedBox(height: 5),
                DsBar(
                  value: subject.accuracy,
                  height: 5,
                  track: AppColors.lineSoft,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          DsSmallButton(
            label: 'অনুশীলন',
            onPressed: () => context.push(practicePath(subject)),
          ),
        ],
      ),
    );
  }
}

String practicePath(SubjectPerformance s) =>
    '/taxonomy-questions/${s.syllabusId}/${s.nodeId}'
    '?title=${Uri.encodeComponent(s.name)}';

Future<void> _confirmSignOut(BuildContext context, WidgetRef ref) async {
  final ok = await showConfirmDialog(
    context,
    title: 'লগ আউট করবে?',
    message: 'আবার ঢুকতে ইমেইল আর পাসওয়ার্ড লাগবে।',
    confirmLabel: 'লগ আউট',
    destructive: true,
  );
  if (!ok) return;
  await ref.read(authControllerProvider.notifier).signOut();
  appRouter.go('/login');
}

Future<void> _pickTextSize(
  BuildContext context,
  WidgetRef ref,
  TextSize current,
) async {
  final picked = await showModalBottomSheet<TextSize>(
    context: context,
    showDragHandle: true,
    backgroundColor: AppColors.paper,
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('লেখার আকার', style: dsText(18, weight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(
              'প্রশ্ন, উত্তর আর পুরো অ্যাপের লেখা এই মাপে দেখাবে',
              style: dsText(13, color: AppColors.muted),
            ),
            const SizedBox(height: 12),
            for (final o in TextSize.values)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: DsCard(
                  color: o == current ? AppColors.brandSoft : AppColors.paper,
                  borderColor: o == current
                      ? AppColors.brand
                      : AppColors.lineStrong,
                  radius: 12,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  onTap: () => Navigator.of(context).pop(o),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          o.label,
                          style: dsText(15 * o.factor, weight: FontWeight.w600),
                        ),
                      ),
                      if (o == current)
                        const Icon(
                          LucideIcons.check,
                          size: 18,
                          color: AppColors.brand,
                        ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
  );
  if (picked != null) {
    await ref.read(textSizeProvider.notifier).set(picked);
  }
}
