import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/responsive_wrapper.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../auth/data/models/user_model.dart';

final leaderboardProvider = FutureProvider<List<UserModel>>((ref) async {
  final user = ref.watch(authStateChangesProvider).value;
  if (user == null) return [];
  return ref.read(accountApiServiceProvider).getLeaderboard();
});

class LeaderboardView extends ConsumerWidget {
  const LeaderboardView({super.key});

  static const _medals = ['🥇', '🥈', '🥉'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leaderboardAsync = ref.watch(leaderboardProvider);

    return Scaffold(
      appBar: AppBar(title: Text("Leaderboard")),
      body: leaderboardAsync.when(
        data: (users) => RefreshIndicator(
          onRefresh: () async => ref.refresh(leaderboardProvider),
          child: ResponsiveWrapper(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: users.length,
              itemBuilder: (context, index) {
                final user = users[index];
                final isTopThree = index < 3;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 40,
                              child: isTopThree
                                  ? Text(
                                      _medals[index],
                                      style: const TextStyle(fontSize: 24),
                                      textAlign: TextAlign.center,
                                    )
                                  : CircleAvatar(
                                      radius: 16,
                                      backgroundColor: Colors.grey[200],
                                      child: Text(
                                        '${index + 1}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    user.name.isNotEmpty ? user.name : ' ',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryColor.withValues(
                                        alpha: 0.1,
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      'Avg: ${user.averageScore.toStringAsFixed(1)}  |  ${user.totalExamsAttended} exams',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppTheme.primaryColor,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              user.highestScore.toStringAsFixed(1),
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
