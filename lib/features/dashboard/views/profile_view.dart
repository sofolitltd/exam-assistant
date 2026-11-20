import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/bangla_digits.dart';
import '../../../core/widgets/ds.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../auth/data/target_exam.dart';
import '../../bcs/data/bcs_api.dart';
import '../../bcs/data/bcs_models.dart';
import '../../bcs/views/bcs_format.dart';
import '../../learning/controllers/learning_providers.dart';
import '../../learning/data/learning_models.dart';
import '../../learning/widgets/accuracy_chart.dart';
import '../../routine/controllers/routine_controller.dart';
import '../controllers/stats_controller.dart';

/// প্রোফাইল: who you are and your goal, four numbers, the recent trend,
/// your three weakest subjects, then everything else.
class ProfileView extends ConsumerWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userStatsProvider).value;
    final results = [...?ref.watch(userExamResultsProvider).value]
      ..sort((a, b) => a.answeredAt.compareTo(b.answeredAt));
    final streak = ref.watch(streakProvider).value;
    final subjectsAsync = ref.watch(subjectPerformanceByDaysProvider(30));
    final mistakes = ref.watch(mistakesProvider(null));
    final target = BcsEdition(
      number: ref.watch(bcsRunningNumberProvider),
      status: EditionStatus.running,
    );
    final goalId = ref.watch(targetExamProvider).value;
    final goalLabel = goalId == null || goalId == 'bcs'
        ? '${editionName(target.number)} প্রিলিমিনারি'
        : targetExamById(goalId).label;

    final pcts = [for (final r in results) r.percentage];
    final avg = pcts.isEmpty
        ? null
        : pcts.reduce((a, b) => a + b) / pcts.length;
    final best = pcts.isEmpty ? null : pcts.reduce((a, b) => a > b ? a : b);
    final last10 = pcts.length > 10 ? pcts.sublist(pcts.length - 10) : pcts;

    final subjects = [...?subjectsAsync.value?.where((s) => s.attempted > 0)]
      ..sort((a, b) => a.accuracy.compareTo(b.accuracy));
    final weakest = subjects.take(3).toList();

    final name = user?.name.isNotEmpty == true ? user!.name : 'নাম নেই';
    final contact = user == null
        ? ''
        : user.phone.isNotEmpty
        ? bn(user.phone)
        : user.email;

    final mistakesText = mistakes.items.isEmpty
        ? (mistakes.isLoading ? 'লোড হচ্ছে…' : 'কোনো ভুল নেই')
        : '${bn(mistakes.items.length)}${mistakes.hasMore ? '+' : ''}টি বাকি';

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
                ref.invalidate(userExamResultsProvider);
                ref.invalidate(streakProvider);
                ref.invalidate(subjectPerformanceByDaysProvider(30));
                await ref.read(mistakesProvider(null).notifier).refresh();
              },
              child: DsPage(
                children: [
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
                        DsCard(
                          color: AppColors.brandSoft,
                          borderWidth: 0,
                          radius: 12,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          onTap: () => _pickGoal(context, ref, goalId),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'আমার লক্ষ্য',
                                      style: dsText(
                                        12,
                                        color: AppColors.brandInk2,
                                      ),
                                    ),
                                    Text(
                                      goalLabel,
                                      style: dsText(
                                        15,
                                        weight: FontWeight.w600,
                                        color: AppColors.brandStrong,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                'বদলাও',
                                style: dsText(
                                  13,
                                  weight: FontWeight.w600,
                                  color: AppColors.brandStrong,
                                ),
                              ),
                            ],
                          ),
                        ),
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
                      ],
                    ),
                  ),
                  DsCard(
                    onTap: () => context.push('/progress'),
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
                                'শেষ ${bn(last10.isEmpty ? 10 : last10.length)} পরীক্ষার ফল',
                                style: dsText(15, weight: FontWeight.w600),
                              ),
                            ),
                            Text(
                              'সব দেখো',
                              style: dsText(
                                13,
                                weight: FontWeight.w600,
                                color: AppColors.brand,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
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
                  DsGrid(
                    children: [
                      InfoTile(
                        title: 'আমার অগ্রগতি',
                        minHeight: 72,
                        subtitle: subjects.isEmpty
                            ? 'বিষয়ভিত্তিক হিসাব'
                            : '${bn(subjects.length)} বিষয়ের হিসাব',
                        onTap: () => context.push('/progress'),
                      ),
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
                        subtitle: 'শীঘ্রই আসছে',
                        onTap: () => showComingSoon(context, 'সংরক্ষিত প্রশ্ন'),
                      ),
                      InfoTile(
                        title: 'শুনে পড়ো',
                        minHeight: 72,
                        subtitle: 'প্রশ্ন-উত্তর শোনো',
                        onTap: () => context.push('/listen'),
                      ),
                    ],
                  ),
                  DsListCard(
                    radius: 16,
                    children: [
                      _setting(
                        'নোটিফিকেশন ও রিমাইন্ডার',
                        onTap: () async {
                          final service = ref.read(
                            routineNotificationServiceProvider,
                          );
                          final granted = await service.requestPermission();
                          if (granted) await service.scheduleRoutineReminders();
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                granted
                                    ? 'রুটিনের রিমাইন্ডার চালু আছে'
                                    : 'ফোনের সেটিংস থেকে নোটিফিকেশন চালু করো',
                              ),
                            ),
                          );
                        },
                      ),
                      _setting(
                        'ডার্ক মোড',
                        trailing: 'শীঘ্রই',
                        onTap: () => showComingSoon(context, 'ডার্ক মোড'),
                      ),
                      _setting(
                        'লেখার আকার',
                        trailing: 'মাঝারি',
                        onTap: () =>
                            showComingSoon(context, 'লেখার আকার বদলানো'),
                      ),
                      _setting(
                        'সাহায্য ও মতামত',
                        onTap: () => showComingSoon(context, 'সাহায্য ও মতামত'),
                      ),
                      InkWell(
                        onTap: () async {
                          await ref
                              .read(authControllerProvider.notifier)
                              .signOut();
                          appRouter.go('/login');
                        },
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
            if (trailing != null)
              Text(trailing, style: dsText(13, color: AppColors.muted))
            else
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

/// "বদলাও" on the goal card. The choice is stored on this device until the
/// API has a target-exam field.
Future<void> _pickGoal(
  BuildContext context,
  WidgetRef ref,
  String? current,
) async {
  final picked = await showModalBottomSheet<String>(
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
            Text('আমার লক্ষ্য', style: dsText(18, weight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(
              'হোমের "আজ" card এটা দেখেই সাজানো হয়',
              style: dsText(13, color: AppColors.muted),
            ),
            const SizedBox(height: 12),
            for (final o in targetExamOptions)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: DsCard(
                  color: o.id == (current ?? 'bcs')
                      ? AppColors.brandSoft
                      : AppColors.paper,
                  borderColor: o.id == (current ?? 'bcs')
                      ? AppColors.brand
                      : AppColors.lineStrong,
                  radius: 12,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                  onTap: () => Navigator.of(context).pop(o.id),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          o.label,
                          style: dsText(15, weight: FontWeight.w600),
                        ),
                      ),
                      if (o.id == (current ?? 'bcs'))
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
    await ref.read(targetExamProvider.notifier).set(picked);
  }
}
