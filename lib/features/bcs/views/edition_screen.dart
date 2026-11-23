import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/bangla_digits.dart';
import '../../../core/widgets/ds.dart';
import '../data/bcs_api.dart';
import '../data/bcs_models.dart';
import '../data/bcs_sample_data.dart';
import 'bcs_async.dart';
import 'bcs_format.dart';
import 'mode_sheet.dart';

/// One edition's page. Running editions show today's live exam; finished
/// ones show the three ways to work through the paper.
class EditionScreen extends ConsumerWidget {
  final int number;

  const EditionScreen({required this.number, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return BcsAsync(
      title: editionName(number),
      value: ref.watch(bcsEditionProvider(number)),
      onRetry: () => ref.invalidate(bcsPaperExamsProvider),
      builder: (edition) => edition.status == EditionStatus.running
          ? _RunningEdition(edition: edition)
          : edition.hasPaper
          ? _CompletedEdition(edition: edition)
          : _NoPaperEdition(edition: edition),
    );
  }
}

class _RunningEdition extends ConsumerStatefulWidget {
  final BcsEdition edition;

  const _RunningEdition({required this.edition});

  @override
  ConsumerState<_RunningEdition> createState() => _RunningEditionState();
}

class _RunningEditionState extends ConsumerState<_RunningEdition> {
  bool _reminder = false;

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(bcsRepositoryProvider);
    final edition = widget.edition;
    final n = edition.number;
    final slot = repo.todaySlot();
    final next = repo.nextSlot();
    final (quizDone, quizTotal) = repo.dailyQuiz();
    final board = repo.meritBoard(overall: false);
    final until = bnUntil(slot.date);
    final syllabus = repo.syllabus();
    final marks = syllabus.fold<int>(0, (sum, s) => sum + s.newMarks);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: DsHeader(
        title: editionName(n),
        subtitle: prelimText(edition),
        trailing: const LivePill('চলছে'),
      ),
      body: DsPage(
        padding: const EdgeInsets.all(16),
        children: [
          DsCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'LIVE · আজ ${bnTime(slot.date)}',
                        style: dsText(
                          12,
                          weight: FontWeight.w600,
                          color: AppColors.liveInk,
                        ),
                      ),
                    ),
                    Text(
                      until == null ? 'চলছে এখন' : 'শুরু হতে $until',
                      style: dsText(12, color: AppColors.muted),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(slot.subject, style: dsText(19, weight: FontWeight.w700)),
                if (slot.topics != null) ...[
                  const SizedBox(height: 2),
                  Text(slot.topics!, style: dsText(13, color: AppColors.ink2)),
                ],
                const SizedBox(height: 12),
                DsGrid(
                  columns: 3,
                  children: [
                    StatBox(label: 'প্রশ্ন', value: bn(slot.questions)),
                    StatBox(label: 'সময়', value: '${bn(slot.minutes)} মিনিট'),
                    StatBox(label: 'নেগেটিভ', value: bnScore(slot.negative)),
                  ],
                ),
                const SizedBox(height: 12),
                DsCard(
                  onTap: () => showComingSoon(context, 'পড়ার উপকরণ'),
                  radius: 10,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      const Icon(LucideIcons.fileText, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'পড়ার উপকরণ (${bn(slot.materials)})',
                          style: dsText(14, weight: FontWeight.w500),
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
                const SizedBox(height: 12),
                if (until == null)
                  DsButton(
                    label: 'পরীক্ষা শুরু করো',
                    onPressed: () => context.push('/bcs/$n/compete'),
                  )
                else
                  DsGrid(
                    children: [
                      DsButton.secondary(
                        label: 'আগে অনুশীলন',
                        height: 44,
                        onPressed: () => context.push('/bcs/$n/practice'),
                      ),
                      DsButton(
                        label: _reminder ? 'মনে করাব ✓' : 'মনে করিয়ে দিও',
                        height: 44,
                        fontSize: 14,
                        onPressed: () {
                          setState(() => _reminder = !_reminder);
                          ScaffoldMessenger.of(context)
                            ..hideCurrentSnackBar()
                            ..showSnackBar(
                              SnackBar(
                                content: Text(
                                  _reminder
                                      ? 'শুরুর ১০ মিনিট আগে মনে করিয়ে দেব'
                                      : 'রিমাইন্ডার বন্ধ করা হলো',
                                ),
                              ),
                            );
                        },
                      ),
                    ],
                  ),
              ],
            ),
          ),
          DsCard(
            onTap: () => context.push('/bcs/$n/practice'),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                _Ring(value: quizDone / quizTotal, label: bn(quizDone)),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ডেইলি কুইজ',
                        style: dsText(15, weight: FontWeight.w600),
                      ),
                      Text(
                        '${bn(quizTotal)}টার মধ্যে ${bn(quizDone)}টা শেষ · '
                        '${bn(quizTotal - quizDone)}টা বাকি',
                        style: dsText(12, color: AppColors.muted),
                      ),
                    ],
                  ),
                ),
                Text(
                  'চালিয়ে যাও',
                  style: dsText(
                    14,
                    weight: FontWeight.w600,
                    color: AppColors.brand,
                  ),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(top: 4),
            child: SectionLabel('আরও'),
          ),
          DsGrid(
            children: [
              InfoTile(
                title: 'পরীক্ষার সূচি',
                subtitle: next == null
                    ? 'সব পরীক্ষা শেষ'
                    : 'পরের: ${bnDayMonthShort(next.date)} · ${_short(next.subject)}',
                onTap: () => context.push('/bcs/$n/schedule'),
              ),
              InfoTile(
                title: 'মেধাতালিকা',
                subtitle:
                    'শেষবার ${bn(board.me.rank)} · শীর্ষ ${bn(board.topPercent)}%',
                onTap: () => context.push('/bcs/$n/merit'),
              ),
              InfoTile(
                title: 'আমার ভুল',
                subtitle: '${bn(edition.pendingMistakes)}টি বাকি',
                onTap: () => context.push('/practice/mistakes'),
              ),
              InfoTile(
                title: 'সিলেবাস',
                subtitle: '${bn(syllabus.length)} বিষয় · ${bn(marks)} নম্বর',
                onTap: () => context.push('/bcs/$n/syllabus'),
              ),
              InfoTile(
                title: 'পড়ার উপকরণ',
                subtitle: 'সব পরীক্ষার, এক জায়গায়',
                onTap: () => showComingSoon(context, 'পড়ার উপকরণ'),
              ),
              InfoTile(
                title: 'সংরক্ষিত',
                subtitle: '${bn(edition.savedQuestions)}টি প্রশ্ন',
                onTap: () => showComingSoon(context, 'সংরক্ষিত প্রশ্ন'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _short(String subject) => subject.split(' ').first;
}

class _Ring extends StatelessWidget {
  final double value;
  final String label;

  const _Ring({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      height: 44,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox.expand(
            child: CircularProgressIndicator(
              value: value,
              strokeWidth: 5,
              strokeCap: StrokeCap.butt,
              color: AppColors.brand,
              backgroundColor: AppColors.line,
            ),
          ),
          Text(label, style: dsText(12, weight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _CompletedEdition extends ConsumerWidget {
  final BcsEdition edition;

  const _CompletedEdition({required this.edition});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final n = edition.number;
    final total = edition.totalQuestions;

    Widget modeRow({
      required IconData icon,
      required String title,
      required String subtitle,
      required VoidCallback onTap,
      bool filled = false,
    }) {
      return InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              IconSquare(icon, filled: filled),
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

    Future<void> openMode(PaperMode mode) async {
      final choice = await showModeSheet(
        context,
        edition: n,
        initialMode: mode,
      );
      if (choice == null || !context.mounted) return;
      final path = choice.$1 == PaperMode.read ? 'read' : 'practice';
      context.push('/bcs/$n/$path', extra: choice.$2);
    }

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: DsHeader(
        title: editionName(n),
        subtitle: 'প্রিলিমিনারি · ${bn(total)} MCQ · ২ ঘণ্টা · নেগেটিভ ০.৫',
        trailing: const NeutralPill('শেষ'),
      ),
      body: DsPage(
        children: [
          const SectionLabel('কীভাবে পড়বে'),
          DsListCard(
            radius: 16,
            children: [
              modeRow(
                icon: LucideIcons.headphones,
                title: 'পড়ো ও শোনো',
                subtitle: 'উত্তরসহ প্রশ্ন · বিষয়/topic বেছে নাও',
                onTap: () => openMode(PaperMode.read),
              ),
              modeRow(
                icon: LucideIcons.pencilLine,
                title: 'অনুশীলন',
                subtitle: 'নিজে দাগাও, সাথে সাথে ঠিক/ভুল · সময় নেই',
                onTap: () => openMode(PaperMode.practice),
              ),
              modeRow(
                icon: LucideIcons.timer,
                title: 'প্রতিযোগিতা',
                subtitle: 'পুরো ${bn(total)} · ২ ঘণ্টা · মেধাতালিকায় যাবে',
                filled: true,
                onTap: () => context.push('/bcs/$n/compete'),
              ),
            ],
          ),
          DsGrid(
            children: [
              StatBox(
                label: 'প্রথম চেষ্টা (মেধাতালিকায়)',
                value: edition.firstScore == null
                    ? 'এখনো দাওনি'
                    : '${bnScore(edition.firstScore!)} · ক্রম ${bn(edition.firstRank ?? 0)}',
                background: AppColors.paper,
                border: Border.all(color: AppColors.line),
              ),
              StatBox(
                label: 'পরের চেষ্টায় সেরা',
                value: edition.bestScore == null
                    ? '—'
                    : bnScore(edition.bestScore!),
                valueColor: AppColors.success,
                background: AppColors.paper,
                border: Border.all(color: AppColors.line),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.only(top: 4),
            child: SectionLabel('আরও'),
          ),
          DsGrid(
            children: [
              InfoTile(
                title: 'বিশ্লেষণ',
                subtitle: 'কোন topic বেশি, কঠিন প্রশ্ন',
                onTap: () => context.push('/bcs/$n/analysis'),
              ),
              InfoTile(
                title: 'মেধাতালিকা',
                subtitle: edition.firstRank == null
                    ? '${bnCount(edition.participants)} জন'
                    : 'আমি ${bn(edition.firstRank!)} · ${bnCount(edition.participants)} জন',
                onTap: () => context.push(
                  edition.examId == null
                      ? '/bcs/$n/merit'
                      : '/exam/${Uri.encodeComponent(edition.examId!)}/leaderboard'
                            '?title=${Uri.encodeComponent(editionName(n))}',
                ),
              ),
              InfoTile(
                title: 'আমার ভুল',
                subtitle: '${bn(edition.pendingMistakes)}টি বাকি',
                onTap: () => context.push(
                  '/practice/mistakes?title=${Uri.encodeComponent(editionName(n))}'
                  '${edition.examId == null ? '' : '&examId=${Uri.encodeComponent(edition.examId!)}'}',
                ),
              ),
              InfoTile(
                title: 'সংরক্ষিত',
                subtitle: '${bn(edition.savedQuestions)}টি প্রশ্ন',
                onTap: () => showComingSoon(context, 'সংরক্ষিত প্রশ্ন'),
              ),
              InfoTile(
                title: 'বিষয়ভিত্তিক অগ্রগতি',
                subtitle: 'বিষয় ধরে ঠিক-ভুল',
                onTap: () => context.push('/progress'),
              ),
              InfoTile(
                title: 'Live exam আর্কাইভ',
                subtitle: '৪০টি · মেধাতালিকাসহ',
                onTap: () => context.push('/bcs/$n/schedule'),
              ),
              InfoTile(
                title: 'সিলেবাস',
                subtitle: 'যে সিলেবাসে পরীক্ষা হয়েছিল',
                onTap: () => context.push('/bcs/$n/syllabus'),
              ),
              InfoTile(
                title: 'প্রশ্ন খোঁজো',
                subtitle: 'শব্দ বা topic দিয়ে',
                onTap: () => context.push('/bcs/pyq?bcs=$n'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// An upcoming edition, or a past one whose question paper isn't in the app
/// yet.
class _NoPaperEdition extends StatelessWidget {
  final BcsEdition edition;

  const _NoPaperEdition({required this.edition});

  @override
  Widget build(BuildContext context) {
    final upcoming = edition.status == EditionStatus.upcoming;
    final special = specialText(edition);
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: DsHeader(
        title: editionName(edition.number),
        subtitle: special,
        trailing: NeutralPill(upcoming ? 'আসছে' : 'শেষ'),
      ),
      body: DsPage(
        children: [
          DsCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  upcoming
                      ? 'প্রস্তুতি শুরু হবে শীঘ্রই'
                      : 'প্রশ্নপত্র শীঘ্রই আসছে',
                  style: dsText(17, weight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Text(
                  upcoming
                      ? prelimText(edition)
                      : 'এই বিসিএসের প্রশ্ন আর ব্যাখ্যা যোগ করা হচ্ছে। '
                            'যোগ হলেই এখানে পড়ো, অনুশীলন আর প্রতিযোগিতা খুলে যাবে।',
                  style: dsText(14, color: AppColors.ink2, height: 1.5),
                ),
                if (!upcoming && edition.prelimDate != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    prelimText(edition),
                    style: dsText(13, color: AppColors.muted),
                  ),
                ],
                if (edition.note != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    edition.note!,
                    style: dsText(13, color: AppColors.muted),
                  ),
                ],
              ],
            ),
          ),
          DsButton.secondary(
            label: 'বিষয়ভিত্তিক বিগত প্রশ্ন দেখো',
            onPressed: () => context.push('/bcs/pyq'),
          ),
        ],
      ),
    );
  }
}
