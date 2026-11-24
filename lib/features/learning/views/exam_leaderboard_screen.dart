import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/bangla_digits.dart';
import '../../../core/widgets/ds.dart';
import '../controllers/learning_providers.dart';
import 'rank_row.dart';

/// Top 20 for one exam, ranked by each person's first attempt. The signed-in
/// user's own row is always included, even outside the top 20.
class ExamLeaderboardScreen extends ConsumerWidget {
  final String examId;
  final String title;

  const ExamLeaderboardScreen({
    super.key,
    required this.examId,
    required this.title,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final boardAsync = ref.watch(examLeaderboardProvider(examId));
    final provisional = boardAsync.value?.provisional ?? false;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: DsHeader(
        title: 'লিডারবোর্ড',
        subtitle: title,
        trailing: provisional ? const LivePill('চলছে') : null,
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(examLeaderboardProvider(examId).future),
        child: boardAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => RankMessage(
            icon: LucideIcons.wifiOff,
            text: 'লিডারবোর্ড আনা যায়নি',
            action: DsSmallButton(
              label: 'আবার চেষ্টা করো',
              onPressed: () => ref.invalidate(examLeaderboardProvider(examId)),
            ),
          ),
          data: (board) {
            if (board.entries.isEmpty) {
              return const RankMessage(
                icon: LucideIcons.trophy,
                text: 'এখনো কেউ পরীক্ষা দেয়নি',
              );
            }
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
              children: [
                const SectionLabel('ক্রম', trailing: 'নম্বর'),
                const SizedBox(height: 8),
                DsListCard(
                  children: [
                    for (final e in board.entries)
                      RankRow(
                        rank: e.rank,
                        name: e.name,
                        score: _score(e.score),
                        isYou: e.isYou,
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  provisional
                      ? 'পরীক্ষা এখনো চলছে, তাই ক্রম চূড়ান্ত নয়। '
                            'শুধু প্রথম চেষ্টা গোনা হয়।'
                      : 'শুধু প্রথম চেষ্টা গোনা হয়।',
                  textAlign: TextAlign.center,
                  style: dsText(12, color: AppColors.muted),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Up to two decimals (negative marking gives .25 / .75), trailing zeros cut.
String _score(double v) => bn(
  v.toStringAsFixed(2).replaceFirst(RegExp(r'\.?0+$'), ''),
);
