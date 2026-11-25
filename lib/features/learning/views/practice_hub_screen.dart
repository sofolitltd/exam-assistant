import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/ds.dart';
import '../../bcs/data/bcs_api.dart';
import '../../bcs/views/bcs_format.dart';
import '../../exam/views/home_screen.dart';
import '../../goals/views/goal_chip.dart';
import '../widgets/today_practice_card.dart';

/// অনুশীলন tab: one main task (mistakes to clear) and every practice tool.
class PracticeHubScreen extends ConsumerWidget {
  const PracticeHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final runningNumber = ref.watch(bcsRunningNumberProvider);
    final papers = ref.watch(bcsPapersReadyProvider).value ?? const [];

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            SizedBox(
              height: 60,
              child: Padding(
                padding: const EdgeInsets.only(left: 16, right: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'অনুশীলন',
                        style: dsText(19, weight: FontWeight.w700),
                      ),
                    ),
                    const NoticeBell(),
                  ],
                ),
              ),
            ),
            Expanded(
              child: DsPage(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                children: [
                  const GoalChip(),
                  const SectionLabel('আজ'),
                  const TodayPracticeCard(),
                  DsCard(
                    onTap: () => context.push('/study-first'),
                    child: Row(
                      children: [
                        const IconSquare(LucideIcons.target),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'কোনটা আগে পড়ব',
                                style: dsText(15, weight: FontWeight.w600),
                              ),
                              Text(
                                'গত বিসিএসগুলোর ধরন আর তোমার দুর্বলতা মিলিয়ে',
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
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: SectionLabel('যেভাবে পড়বে'),
                  ),
                  DsListCard(
                    radius: 16,
                    children: [
                      _row(
                        context,
                        LucideIcons.bookOpen,
                        'বিষয়ভিত্তিক বিগত প্রশ্ন',
                        'টপিক ধরে পড়ো, নিজে দাগিয়ে অনুশীলন করো',
                        () => context.push('/bcs/pyq'),
                      ),
                      _row(
                        context,
                        LucideIcons.pencilLine,
                        'প্রশ্নপত্র ধরে অনুশীলন',
                        papers.isEmpty
                            ? 'আগের বিসিএসের প্রশ্নপত্র'
                            : '${editionName(papers.first.number)} থেকে শুরু করো',
                        () => context.push('/bcs'),
                      ),
                      _row(
                        context,
                        LucideIcons.headphones,
                        'শুনে শুনে পড়ো',
                        'প্রশ্ন আর উত্তর পড়ে শোনাবে',
                        () => context.push('/listen'),
                      ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: SectionLabel('আরও'),
                  ),
                  DsGrid(
                    children: [
                      InfoTile(
                        title: 'বিষয়ভিত্তিক অগ্রগতি',
                        subtitle: 'কোথায় দুর্বল দেখো',
                        onTap: () => context.push('/progress'),
                      ),
                      InfoTile(
                        title: 'স্কোর কৌশল',
                        subtitle: 'কোথায় আন্দাজ করা ঠিক',
                        onTap: () => context.push('/strategy'),
                      ),
                      InfoTile(
                        title: 'সিলেবাস',
                        subtitle: 'পুরনো, নতুন, তুলনা',
                        onTap: () =>
                            context.push('/bcs/$runningNumber/syllabus'),
                      ),
                      InfoTile(
                        title: 'জব সল্যুশন',
                        subtitle: 'সব নিয়োগ পরীক্ষা',
                        onTap: () => context.push('/all-exams'),
                      ),
                      InfoTile(
                        title: 'মেধাতালিকা',
                        subtitle: 'Live exam-এর ক্রম',
                        onTap: () => context.push('/bcs/$runningNumber/merit'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            IconSquare(icon),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: dsText(15, weight: FontWeight.w600)),
                  Text(subtitle, style: dsText(12, color: AppColors.muted)),
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
    );
  }
}
