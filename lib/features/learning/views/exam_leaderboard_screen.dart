import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/bangla_digits.dart';
import '../../../core/widgets/responsive_wrapper.dart';
import '../controllers/learning_providers.dart';

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
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(examLeaderboardProvider(examId).future),
        child: boardAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => ListView(
            children: [
              Padding(
                padding: const EdgeInsets.all(24),
                child: Text('লিডারবোর্ড লোড করা যায়নি: $error'),
              ),
            ],
          ),
          data: (board) {
            if (board.entries.isEmpty) {
              return ListView(
                children: const [
                  Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: Text('এখনো কেউ পরীক্ষা দেয়নি।')),
                  ),
                ],
              );
            }
            return ResponsiveWrapper(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (board.provisional)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        'পরীক্ষা এখনো চলছে — র‍্যাঙ্কিং চূড়ান্ত নয়।',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  Text(
                    'প্রত্যেকের প্রথমবারের রেজাল্ট দিয়ে র‍্যাঙ্ক করা হয়েছে।',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 12),
                  for (final entry in board.entries)
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: entry.isYou
                            ? AppColors.brandSoft
                            : AppColors.paper,
                        borderRadius: BorderRadius.circular(AppRadii.md),
                        border: Border.all(
                          color: entry.isYou ? AppColors.brand : AppColors.line,
                        ),
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 44,
                            child: Text(
                              '#${toBanglaNumber(entry.rank)}',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                                color: entry.rank <= 3
                                    ? const Color(0xFFB4730F)
                                    : AppColors.muted,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              entry.isYou ? '${entry.name} (তুমি)' : entry.name,
                              style: TextStyle(
                                fontWeight: entry.isYou
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                              ),
                            ),
                          ),
                          Text(
                            entry.score.toStringAsFixed(2),
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppColors.brandStrong,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
