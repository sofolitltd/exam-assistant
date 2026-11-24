import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/bangla_digits.dart';
import '../../../core/widgets/ds.dart';
import '../data/bcs_api.dart';
import '../data/bcs_models.dart';
import 'bcs_async.dart';
import 'bcs_format.dart';

/// বিসিএস: the running edition on top, then upcoming, subject-wise past
/// questions and every previous paper.
class BcsScreen extends ConsumerStatefulWidget {
  const BcsScreen({super.key});

  @override
  ConsumerState<BcsScreen> createState() => _BcsScreenState();
}

class _BcsScreenState extends ConsumerState<BcsScreen> {
  bool _following = false;

  @override
  Widget build(BuildContext context) {
    final listAsync = ref.watch(bcsListProvider);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: DsHeader(
        title: 'বিসিএস',
        titleSize: 19,
        bordered: false,
        trailing: IconButton(
          tooltip: 'প্রশ্ন খোঁজো',
          onPressed: () => context.push('/bcs/pyq'),
          icon: const Icon(LucideIcons.search, size: 21, color: AppColors.ink),
        ),
      ),
      body: BcsAsync(
        value: listAsync,
        onRetry: () => ref.invalidate(bcsListProvider),
        builder: (list) => RefreshIndicator(
          color: AppColors.brand,
          onRefresh: () async {
            ref.invalidate(bcsMyResultsProvider);
            ref.invalidate(bcsListProvider);
            await ref.read(bcsListProvider.future);
          },
          child: _content(context, list),
        ),
      ),
    );
  }

  Widget _content(BuildContext context, BcsEditionList list) {
    // Same rule as the past list: only editions with real content. The
    // running/upcoming editions have no paper yet (their live schedule is
    // still sample data), so their cards stay hidden until they do.
    final running = list.running?.hasPaper == true ? list.running : null;
    final upcoming = list.upcoming?.hasPaper == true ? list.upcoming : null;
    // Only past editions whose question paper is in the app.
    final past = list.past.where((e) => e.hasPaper).toList();
    final ready = past;
    final pyqQuestions = ready.fold<int>(0, (sum, e) => sum + e.totalQuestions);

    return DsPage(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      children: [
        if (running != null)
          DsCard(
            onTap: () => context.push('/bcs/${running.number}'),
            borderColor: AppColors.brand,
            borderWidth: 1.5,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const LivePill('চলছে'),
                    if (specialText(running) != null) ...[
                      const SizedBox(width: 6),
                      NeutralPill(specialText(running)!),
                    ],
                    const Spacer(),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            editionName(running.number),
                            style: dsText(20, weight: FontWeight.w700),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            running.note ?? prelimText(running),
                            style: dsText(13, color: AppColors.ink2),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      LucideIcons.chevronRight,
                      size: 20,
                      color: AppColors.brand,
                    ),
                  ],
                ),
              ],
            ),
          ),
        if (upcoming != null)
          DsCard(
            radius: 14,
            padding: const EdgeInsets.fromLTRB(16, 10, 12, 10),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text.rich(
                        TextSpan(
                          text: editionName(upcoming.number),
                          style: dsText(15, weight: FontWeight.w600),
                          children: [
                            TextSpan(
                              text:
                                  ' · ${specialText(upcoming) == null ? 'আসছে' : '${specialText(upcoming)} · আসছে'}',
                              style: dsText(
                                12,
                                weight: FontWeight.w500,
                                color: AppColors.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        upcoming.prelimDate != null
                            ? prelimText(upcoming)
                            : _following
                            ? 'বিজ্ঞপ্তি এলেই নোটিফিকেশন পাবে'
                            : 'বিজ্ঞপ্তি এলে জানিয়ে দেব',
                        style: dsText(12, color: AppColors.muted),
                      ),
                    ],
                  ),
                ),
                DsSmallButton(
                  label: _following ? 'অনুসরণ করছ' : 'অনুসরণ করো',
                  filled: _following,
                  onPressed: () => setState(() => _following = !_following),
                ),
              ],
            ),
          ),
        DsCard(
          onTap: () => context.push('/bcs/pyq'),
          color: AppColors.brandSoft,
          borderWidth: 0,
          radius: 14,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'বিষয়ভিত্তিক বিগত প্রশ্ন',
                      style: dsText(
                        15,
                        weight: FontWeight.w600,
                        color: AppColors.brandStrong,
                      ),
                    ),
                    Text(
                      ready.isEmpty
                          ? 'বিগত প্রশ্ন'
                          : '${_range(ready)} · ${bnCount(pyqQuestions)} প্রশ্ন',
                      style: dsText(12, color: AppColors.brandInk2),
                    ),
                  ],
                ),
              ),
              const Icon(
                LucideIcons.chevronRight,
                size: 20,
                color: AppColors.brandStrong,
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: SectionLabel(
            'আগের বিসিএস',
            trailing: past.isEmpty ? null : '${bn(past.length)}টি প্রশ্নপত্র',
          ),
        ),
        if (past.isEmpty)
          DsCard(
            child: Text(
              'এখনো কোনো প্রশ্নপত্র যোগ করা হয়নি।',
              style: dsText(14, color: AppColors.muted),
            ),
          )
        else
          DsListCard(
            children: [
              for (final edition in past) _EditionRow(edition: edition),
            ],
          ),
      ],
    );
  }
}

/// "৩৫–৫১তম" for the editions that have a paper, or just "৪৪তম".
String _range(List<BcsEdition> past) {
  final numbers = past.map((e) => e.number).toList()..sort();
  if (numbers.length == 1) return bnOrdinal(numbers.first);
  return '${bn(numbers.first)}–${bnOrdinal(numbers.last)}';
}

class _EditionRow extends StatelessWidget {
  final BcsEdition edition;

  const _EditionRow({required this.edition});

  @override
  Widget build(BuildContext context) {
    Widget status;
    if (!edition.hasPaper) {
      status = Text(
        'প্রশ্ন শীঘ্রই আসছে',
        style: dsText(12, color: AppColors.muted),
      );
    } else if (edition.finished) {
      status = _ProgressLine(
        value: 1,
        color: AppColors.success,
        label: 'সেরা ${bnScore(edition.bestScore!)}',
        labelColor: AppColors.success,
        bold: true,
      );
    } else if (edition.started) {
      status = _ProgressLine(
        value: edition.totalQuestions == 0
            ? 0
            : edition.answered / edition.totalQuestions,
        color: AppColors.brand,
        label: '${bn(edition.answered)}/${bn(edition.totalQuestions)}',
      );
    } else {
      status = Text('শুরু করোনি', style: dsText(12, color: AppColors.muted));
    }

    return InkWell(
      onTap: () => context.push('/bcs/${edition.number}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.sunken,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                bn(edition.number),
                style: dsText(15, weight: FontWeight.w700),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text.rich(
                    TextSpan(
                      text: editionName(edition.number),
                      style: dsText(15, weight: FontWeight.w600),
                      children: [
                        if (specialText(edition) != null)
                          TextSpan(
                            text: ' · ${specialText(edition)}',
                            style: dsText(
                              12,
                              weight: FontWeight.w500,
                              color: AppColors.muted,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  status,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressLine extends StatelessWidget {
  final double value;
  final Color color;
  final String label;
  final Color labelColor;
  final bool bold;

  const _ProgressLine({
    required this.value,
    required this.color,
    required this.label,
    this.labelColor = AppColors.muted,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: DsBar(value: value, color: color),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: dsText(
            12,
            color: labelColor,
            weight: bold ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ],
    );
  }
}
