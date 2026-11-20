import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/bangla_digits.dart';
import '../../../core/widgets/ds.dart';
import '../data/bcs_sample_data.dart';
import 'bcs_format.dart';

class AnalysisScreen extends ConsumerWidget {
  final int number;

  const AnalysisScreen({required this.number, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final a = ref.watch(bcsRepositoryProvider).analysis(number);
    final maxTopic = a.topTopics.fold<int>(1, (m, t) => t.$2 > m ? t.$2 : m);
    final tile = Border.all(color: AppColors.line);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: DsHeader(
        title: 'প্রশ্নপত্র বিশ্লেষণ',
        subtitle: editionName(number),
      ),
      body: DsPage(
        children: [
          DsGrid(
            columns: 3,
            children: [
              StatBox(
                label: 'সবার গড়',
                value: bnScore(a.average),
                valueSize: 18,
                background: AppColors.paper,
                border: tile,
              ),
              StatBox(
                label: 'আমার সেরা',
                value: a.myBest == null ? '—' : bnScore(a.myBest!),
                valueSize: 18,
                valueColor: AppColors.success,
                background: AppColors.paper,
                border: tile,
              ),
              StatBox(
                label: 'আবার এসেছে',
                value: '${bn(a.repeated)}টি',
                valueSize: 18,
                background: AppColors.paper,
                border: tile,
              ),
            ],
          ),
          Text(
            'গড় আর কঠিনতা আমাদের user-দের উত্তর থেকে নিজে থেকে হিসাব হয়',
            style: dsText(12, color: AppColors.muted),
          ),
          DsCard(
            radius: 14,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'কোন topic থেকে বেশি এসেছে',
                  style: dsText(15, weight: FontWeight.w600),
                ),
                for (final (name, count) in a.topTopics) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: Text(name, style: dsText(13))),
                      const SizedBox(width: 10),
                      SizedBox(
                        width: 120,
                        child: DsBar(
                          value: count / maxTopic,
                          height: 8,
                          track: AppColors.lineSoft,
                        ),
                      ),
                      SizedBox(
                        width: 32,
                        child: Text(
                          bn(count),
                          textAlign: TextAlign.right,
                          style: dsText(13, weight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          DsCard(
            radius: 14,
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'সবচেয়ে কঠিন প্রশ্ন',
                          style: dsText(15, weight: FontWeight.w600),
                        ),
                      ),
                      Text(
                        'সবার সঠিক %',
                        style: dsText(12, color: AppColors.muted),
                      ),
                    ],
                  ),
                ),
                for (final q in a.hardest)
                  InkWell(
                    onTap: () => context.push('/bcs/$number/practice'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 11,
                      ),
                      decoration: const BoxDecoration(
                        border: Border(
                          top: BorderSide(color: AppColors.lineSoft),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              q.text,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: dsText(14),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            '${bn(q.correctPercent)}%',
                            style: dsText(
                              14,
                              weight: FontWeight.w700,
                              color: AppColors.danger,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          DsCard(
            onTap: () => context.push('/bcs/$number/practice'),
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
                        'আগের বিসিএস-এ আসা ${bn(a.repeated)}টি প্রশ্ন',
                        style: dsText(
                          15,
                          weight: FontWeight.w600,
                          color: AppColors.brandStrong,
                        ),
                      ),
                      Text(
                        'এগুলো আবারও আসার সম্ভাবনা বেশি',
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
        ],
      ),
    );
  }
}
