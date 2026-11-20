import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/bangla_digits.dart';
import '../../../core/widgets/ds.dart';
import '../../bcs/data/bcs_api.dart';
import '../../bcs/data/bcs_sample_data.dart';
import '../../bcs/views/bcs_format.dart';
import '../../exam/views/home_screen.dart';

/// অনুশীলন tab: one main task (mistakes to clear) and every practice tool.
class PracticeHubScreen extends ConsumerWidget {
  const PracticeHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(bcsRepositoryProvider);
    final running = repo.runningEdition();
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
                  const SectionLabel('আগে এটা'),
                  DsCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'আমার ভুল',
                          style: dsText(18, weight: FontWeight.w600),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${bn(running.pendingMistakes)}টি প্রশ্ন আবার দেওয়া বাকি। '
                          'ঠিক করলে তালিকা থেকে সরে যাবে।',
                          style: dsText(13, color: AppColors.muted),
                        ),
                        const SizedBox(height: 14),
                        DsButton(
                          label: 'ভুলগুলো আবার দাও',
                          onPressed: () => context.push('/practice/mistakes'),
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
                        'topic ধরে ধরে',
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
