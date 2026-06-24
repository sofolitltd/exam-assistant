import 'package:firebase_auth/firebase_auth.dart' show User;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart' show appRouter;
import '../../../core/widgets/responsive_wrapper.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../auth/data/models/user_model.dart';
import '../../exam/data/models/exam_result_model.dart';

import '../controllers/stats_controller.dart';

class ProfileView extends ConsumerWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(userStatsProvider);
    final examResultsAsync = ref.watch(userExamResultsProvider);
    final firebaseUser = ref.watch(authServiceProvider).currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text('Profile', ),
      ),
      body: SingleChildScrollView(
        child: ResponsiveWrapper(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            child: Column(
              children: [
                _ProfileCard(statsAsync: statsAsync, firebaseUser: firebaseUser),
                const SizedBox(height: 16),
                _PerformanceCard(statsAsync: statsAsync, examResultsAsync: examResultsAsync),
                const SizedBox(height: 16),
                _AccountCard(firebaseUser: firebaseUser, ref: ref),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final AsyncValue<UserModel?> statsAsync;
  final User? firebaseUser;

  const _ProfileCard({required this.statsAsync, required this.firebaseUser});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
width: double.infinity,
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 40,
              child: Icon(Icons.person, size: 40),
            ),
            const SizedBox(height: 16),
            statsAsync.when(
              data: (user) {
                if (user != null) {
                  return Column(
                    children: [
                      Text(
                        user.name.isNotEmpty ? user.name : ' ',
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      if (user.email.isNotEmpty)
                        Text(
                          user.email,
                          style: const TextStyle(color: Colors.grey),
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                        ),
                      if (user.phone.isNotEmpty)
                        Text(
                          user.phone,
                          style: const TextStyle(color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                    ],
                  );
                }
                return Text(
                  firebaseUser?.displayName ?? 'User Name',
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                );
              },
              loading: () => Text(
                firebaseUser?.displayName ?? ' ',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
              error: (_, _) => Text(
                firebaseUser?.displayName ?? ' ',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: 150,
              child: OutlinedButton.icon(
                onPressed: () => context.push('/profile/edit'),
                icon: const Icon(Icons.edit, size: 18),
                label: const Text('Edit Profile'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PerformanceCard extends StatelessWidget {
  final AsyncValue<UserModel?> statsAsync;
  final AsyncValue<List<ExamResultModel>> examResultsAsync;

  const _PerformanceCard({
    required this.statsAsync,
    required this.examResultsAsync,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: statsAsync.when(
          data: (stats) {
            if (stats == null) {
              return const SizedBox(
                width: double.infinity,
                height: 200,
                child: Center(child: Text('No stats available yet. Take an exam!')));
            }
            return Column(
              children: [
                Row(
                  children: [
                    Expanded(child: _statItem('Total Exams', stats.totalExamsAttended.toString())),
                    Expanded(child: _statItem('Highest', stats.highestScore.toStringAsFixed(1))),
                    Expanded(child: _statItem('Average', stats.averageScore.toStringAsFixed(1))),
                  ],
                ),
                const Divider(height: 40),
                const Row(
                  children: [
                    Icon(Icons.trending_up, size: 20, color: Color(0xFF005C53)),
                    SizedBox(width: 8),
                    Text(
                      'Performance Trajectory',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Your latest exam scores over time',
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
                const SizedBox(height: 24),
                _buildChart(),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, s) => Text('Error loading stats: $e'),
        ),
      ),
    );
  }

  Widget _buildChart() {
    return examResultsAsync.when(
      data: (results) {
        if (results.isEmpty) {
          return const SizedBox(
            height: 220,
            child: Center(
              child: Text(
                'Complete an exam to see your trajectory',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          );
        }

        final spots = results.asMap().entries.map((e) {
          return FlSpot(e.key.toDouble(), e.value.percentage);
        }).toList();

        return SizedBox(
          height: 220,
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: 20,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: Colors.grey.withValues(alpha: 0.12),
                  strokeWidth: 1,
                ),
              ),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 32,
                    interval: 1,
                    getTitlesWidget: (value, meta) {
                      if (value.toInt() >= results.length) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          '${value.toInt() + 1}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 36,
                    interval: 20,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        '${value.toInt()}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                      );
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              minY: 0,
              maxY: 100,
              lineTouchData: LineTouchData(
                enabled: true,
                touchTooltipData: LineTouchTooltipData(
                  getTooltipItems: (touchedSpots) {
                    return touchedSpots.map((spot) {
                      return LineTooltipItem(
                        '${spot.y.toStringAsFixed(0)}%',
                        const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      );
                    }).toList();
                  },
                ),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  color: const Color(0xFF005C53),
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, barData, index) {
                      return FlDotCirclePainter(
                        radius: 5,
                        color: const Color(0xFF005C53),
                        strokeWidth: 2,
                        strokeColor: Colors.white,
                      );
                    },
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
const Color(0xFF005C53).withValues(alpha: 0.25),
const Color(0xFF005C53).withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox(
        height: 220,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, s) => SizedBox(
        height: 220,
        child: Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _statItem(String label, String value) {
    return Column(
      children: [
        const SizedBox(height: 8),
        Text(
          value,
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFF005C53),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: Colors.grey, fontSize: 12),
        ),
      ],
    );
  }
}

class _AccountCard extends StatelessWidget {
  final User? firebaseUser;
  final WidgetRef ref;

  const _AccountCard({required this.firebaseUser, required this.ref});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            if (firebaseUser?.email == 'asifreyad1@gmail.com')
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => context.go('/admin'),
                    icon: const Icon(Icons.admin_panel_settings),
                    label: const Text('Admin Panel'),
                  ),
                ),
              ),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  await ref
                      .read(authControllerProvider.notifier)
                      .signOut();
                  appRouter.go('/login');
                },
                icon: const Icon(Icons.logout),
                label: const Text('Sign Out'),
                style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
