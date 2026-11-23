import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/bangla_digits.dart';
import '../../../core/widgets/brand_mark.dart';
import '../../../core/widgets/ds.dart';
import '../../bcs/data/bcs_models.dart';
import '../../bcs/data/bcs_sample_data.dart';
import '../../bcs/data/bcs_api.dart';
import '../../bcs/views/bcs_async.dart';
import '../../bcs/views/bcs_format.dart';
import '../data/home_categories.dart';

/// Hidden for now (user's choice, 2026-11-21): the "আজ" card runs on
/// sample data (live slot, daily quiz, streak). Set to true to bring it
/// back once it reads real data.
const bool showTodaySection = false;

/// Home: today's one main task on top, then the exam categories.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(bcsRepositoryProvider);
    final running = BcsEdition(
      number: ref.watch(bcsRunningNumberProvider),
      status: EditionStatus.running,
    );
    final slot = repo.todaySlot();
    final (quizDone, quizTotal) = repo.dailyQuiz();
    final (streak, week) = repo.readingStreak();
    // From the admin console (Home categories); no built-in list.
    final categoriesAsync = ref.watch(homeCategoriesProvider);
    // The tile's "৫০তম চলছে" only once the real BCS list has loaded.
    final runningLoaded = ref.watch(bcsListProvider).value?.running?.number;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const HomeTopBar(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                children: [
                  if (showTodaySection) ...[
                    const SectionLabel('আজ'),
                    const SizedBox(height: 8),
                    DsCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              LivePill('Live · ${bnTime(slot.date)}'),
                              const SizedBox(width: 8),
                              Text(
                                editionName(running.number),
                                style: dsText(13, color: AppColors.ink2),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Text(
                            slot.subject,
                            style: dsText(18, weight: FontWeight.w600),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            slotMeta(slot),
                            style: dsText(13, color: AppColors.muted),
                          ),
                          const SizedBox(height: 14),
                          DsGrid(
                            children: [
                              _MiniStat(
                                label: 'ডেইলি কুইজ',
                                value: '${bn(quizDone)} / ${bn(quizTotal)}',
                                bar: DsBar(value: quizDone / quizTotal),
                              ),
                              _MiniStat(
                                label: 'পড়ার স্ট্রিক',
                                value: '${bn(streak)} দিন',
                                bar: Row(
                                  children: [
                                    for (var i = 0; i < week.length; i++) ...[
                                      if (i > 0) const SizedBox(width: 3),
                                      Expanded(
                                        child: DsBar(
                                          value: 1,
                                          color: week[i]
                                              ? AppColors.success
                                              : AppColors.line,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          DsButton(
                            label:
                                '${bnOrdinal(running.number)} প্রস্তুতিতে যাও',
                            onPressed: () =>
                                context.push('/bcs/${running.number}'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                  const SectionLabel('পরীক্ষা'),
                  const SizedBox(height: 8),
                  BcsAsync(
                    value: categoriesAsync,
                    onRetry: () => ref.invalidate(homeCategoriesProvider),
                    builder: (categories) => categories.isEmpty
                        ? DsCard(
                            child: Text(
                              'এখন কোনো পরীক্ষা দেখানো হচ্ছে না।',
                              style: dsText(14, color: AppColors.muted),
                            ),
                          )
                        : DsGrid(
                            children: [
                              for (final category in categories)
                                _CategoryTile(
                                  category:
                                      category.id == 'bcs' &&
                                          runningLoaded != null
                                      ? ExamCategory(
                                          id: category.id,
                                          name: category.name,
                                          status:
                                              '${bnOrdinal(runningLoaded)} চলছে',
                                          running: true,
                                        )
                                      : category,
                                ),
                            ],
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Title bar of the home tab, with the notice bell.
class HomeTopBar extends StatelessWidget {
  const HomeTopBar({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60,
      child: Padding(
        padding: const EdgeInsets.only(left: 16, right: 4),
        child: Row(
          children: [
            const BrandMark(size: 30),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Exam Assistant',
                style: dsText(19, weight: FontWeight.w700),
              ),
            ),
            const NoticeBell(),
          ],
        ),
      ),
    );
  }
}

class NoticeBell extends StatelessWidget {
  final bool unread;

  const NoticeBell({this.unread = true, super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'নোটিশ',
      onPressed: () => context.push('/notices'),
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          const Icon(LucideIcons.bell, size: 22, color: AppColors.ink),
          if (unread)
            Positioned(
              top: 0,
              right: 1,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.live,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Widget bar;

  const _MiniStat({
    required this.label,
    required this.value,
    required this.bar,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.canvas,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: dsText(12, color: AppColors.muted)),
          const SizedBox(height: 6),
          Text(value, style: dsText(15, weight: FontWeight.w600)),
          const SizedBox(height: 6),
          bar,
        ],
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final ExamCategory category;

  const _CategoryTile({required this.category});

  @override
  Widget build(BuildContext context) {
    return InfoTile(
      title: category.name,
      subtitle: category.status,
      titleSize: 16,
      minHeight: 72,
      highlighted: category.running,
      subtitleColor: category.running ? AppColors.liveInk : null,
      subtitleLeading: category.running ? const LiveDot() : null,
      onTap: () {
        switch (category.id) {
          case 'bcs':
            context.push('/bcs');
          case 'jobs':
            context.push('/all-exams');
          default:
            showComingSoon(context, category.name);
        }
      },
    );
  }
}
