import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/bangla_digits.dart';
import '../../../core/widgets/ds.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../auth/data/models/user_model.dart';
import '../../learning/views/rank_row.dart';

final leaderboardProvider = FutureProvider<List<UserModel>>((ref) async {
  final user = ref.watch(authStateChangesProvider).value;
  if (user == null) return [];
  return ref.read(accountApiServiceProvider).getLeaderboard();
});

/// Overall leaderboard (top 20 by highest score), opened from profile.
class LeaderboardView extends ConsumerWidget {
  const LeaderboardView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final boardAsync = ref.watch(leaderboardProvider);
    final myId = ref.watch(authStateChangesProvider).value?.uid;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: const DsHeader(title: 'লিডারবোর্ড', subtitle: 'সেরা ২০ জন'),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(leaderboardProvider.future),
        child: boardAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => RankMessage(
            icon: LucideIcons.wifiOff,
            text: 'লিডারবোর্ড আনা যায়নি',
            action: DsSmallButton(
              label: 'আবার চেষ্টা করো',
              onPressed: () => ref.invalidate(leaderboardProvider),
            ),
          ),
          data: (users) {
            if (users.isEmpty) {
              return const RankMessage(
                icon: LucideIcons.trophy,
                text: 'এখনো কেউ পরীক্ষা দেয়নি',
              );
            }
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
              children: [
                const SectionLabel('ক্রম', trailing: 'সর্বোচ্চ নম্বর'),
                const SizedBox(height: 8),
                DsListCard(
                  children: [
                    for (var i = 0; i < users.length; i++)
                      RankRow(
                        rank: i + 1,
                        name: users[i].name.isNotEmpty
                            ? users[i].name
                            : 'নামহীন',
                        detail:
                            'গড় ${bnScore(users[i].averageScore)} · '
                            '${bn(users[i].totalExamsAttended)}টি পরীক্ষা',
                        score: bnScore(users[i].highestScore),
                        isYou: myId != null && users[i].uid == myId,
                      ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
