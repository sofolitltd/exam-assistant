import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/responsive_wrapper.dart';
import '../controllers/exam_controller.dart';
import '../data/models/exam_model.dart';
import '../data/services/firestore_quiz_service.dart';

class _ExamWithCount {
  final ExamModel exam;
  final int questionCount;
  _ExamWithCount(this.exam, this.questionCount);
}

final recentExamsProvider = FutureProvider<List<_ExamWithCount>>((ref) async {
  final service = FirestoreQuizService();
  final exams = await service.getRecentExams(5, publishedOnly: true);
  final result = <_ExamWithCount>[];
  for (final exam in exams) {
    final count = await service.getExamQuestionCount(exam.examId);
    result.add(_ExamWithCount(exam, count));
  }
  return result;
});

const _subjects = [
  'Bangla', 'English', 'Mathematics', 'Science',
  'International Affairs', 'Geography', 'Bangladesh Affairs',
  'Islam & Moral Education', 'ICT', 'Mental Ability',
];

final questionCountsProvider = FutureProvider<Map<String, int>>((ref) async {
  final service = FirestoreQuizService();
  final counts = <String, int>{};
  for (final subject in _subjects) {
    final questions = await service.getQuestionsBySubject(subject);
    counts[subject] = questions.length;
  }
  return counts;
});

IconData _subjectIcon(String subject) {
  switch (subject) {
    case 'Bangla':
    case 'English':
      return LucideIcons.book;
    case 'Mathematics':
      return LucideIcons.sigma;
    case 'Science':
      return Icons.science_outlined;
    case 'International Affairs':
      return LucideIcons.users;
    case 'Geography':
      return LucideIcons.globe;
    case 'Bangladesh Affairs':
      return LucideIcons.landmark;
    case 'Islam & Moral Education':
      return Icons.mosque_outlined;
    case 'ICT':
      return LucideIcons.monitor;
    case 'Mental Ability':
      return LucideIcons.brain;
    default:
      return LucideIcons.book;
  }
}

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final examsAsync = ref.watch(recentExamsProvider);
    final countsAsync = ref.watch(questionCountsProvider);
    final counts = countsAsync.asData?.value ?? const <String, int>{};

    return Scaffold(
      appBar: AppBar(title: Text("Exam Assistant"),),
      body: ResponsiveWrapper(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              examsAsync.when(
                data: (exams) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionHeader('Latest Exams', LucideIcons.zap, trailing: TextButton(
                        onPressed: () => context.push('/all-exams'),
                        child: const Text('See More'),
                      )),
                      const SizedBox(height: 12),
                      if (exams.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 32),
                            child: Column(
                              children: [
                                Icon(LucideIcons.file,
                                    size: 48, color: Colors.grey[300]),
                                const SizedBox(height: 12),
                                Text(
                                  'No exams available yet',
                                  style: TextStyle(
                                    color: Colors.grey[500],
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        ...exams.map((e) =>
                            _buildExamCard(context, ref, e.exam, e.questionCount)),
                      const SizedBox(height: 24),
                    ],
                  );
                },
                loading: () => const Padding(
                  padding: EdgeInsets.only(bottom: 24),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (_, _) => const SizedBox(),
              ),
              _sectionHeader('Practice by Subject', LucideIcons.book),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, constraints) {
                  final crossAxisCount = constraints.maxWidth >= 900
                      ? 4
                      : constraints.maxWidth >= 600
                          ? 3
                          : 2;
                  return MasonryGridView.count(
                    crossAxisCount: crossAxisCount,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _subjects.length,
                    itemBuilder: (context, index) {
                      final subject = _subjects[index];
                      final count = counts[subject] ?? 0;
                      return _buildSubjectCard(context, subject, count);
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, IconData icon, {Widget? trailing}) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppTheme.primaryColor),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ?trailing,
      ],
    );
  }

  Widget _buildExamCard(
      BuildContext context, WidgetRef ref, ExamModel exam, int questionCount) {
    final minutes = exam.durationSeconds ~/ 60;
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    final timeStr = hours > 0 ? '${hours}h $mins m' : '$mins min';
    final dateStr = _formatDate(exam.createdAt);
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showExamInfoDialog(context, ref, exam),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(LucideIcons.file,
                    color: AppTheme.primaryColor),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            exam.title.isNotEmpty ? exam.title : ' ',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '[$dateStr]',
                          style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          timeStr,
                          style: TextStyle(
                              color: Colors.grey[600], fontSize: 13),
                        ),
                        Text(
                          '  ·  ',
                          style: TextStyle(
                              color: Colors.grey[400], fontSize: 13),
                        ),
                        Text(
                          '$questionCount questions',
                          style: TextStyle(
                              color: Colors.grey[600], fontSize: 13),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right,
                  size: 20, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  void _showExamInfoDialog(
      BuildContext context, WidgetRef ref, ExamModel exam) async {
    final service = FirestoreQuizService();
    final questions = await service.getExamQuestions(exam.examId);
    if (questions.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No questions in this exam')),
        );
      }
      return;
    }

    if (!context.mounted) return;

    final shouldStart = await showDialog<bool>(
      context: context,
      builder: (ctx) => SizedBox(
        width: 500,
        child: AlertDialog(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(exam.title.isNotEmpty ? exam.title : 'Exam'),
            ),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(ctx, false),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _dialogRow(Icons.timer_outlined,
                'Duration: ${exam.durationSeconds ~/ 60} minutes'),
            const SizedBox(height: 8),
            _dialogRow(Icons.quiz_outlined,
                'Questions: ${questions.length}'),
            const SizedBox(height: 8),
            _dialogRow(Icons.remove_circle_outline,
                'Negative: ${exam.negativeMarks}'),
            if (exam.isPublished)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(children: [
                  Icon(Icons.check_circle, size: 18, color: Colors.green[600]),
                  const SizedBox(width: 6),
                  Text('Published',
                      style: TextStyle(color: Colors.green[600])),
                ]),
              ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Start Exam'),
          ),
        ],
      ),
      ),
    );

    if (shouldStart == true && context.mounted) {
      ref.read(examControllerProvider.notifier).startExam(exam, questions);
      if (context.mounted) context.go('/exam/${exam.examId}');
    }
  }

  Widget _dialogRow(IconData icon, String text) {
    return Row(children: [
      Icon(icon, size: 18, color: Colors.grey[600]),
      const SizedBox(width: 8),
      Text(text, style: const TextStyle(fontSize: 14)),
    ]);
  }

  Widget _buildSubjectCard(
      BuildContext context, String subject, int questionCount) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.push('/subject/$subject'),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(_subjectIcon(subject),
                    size: 20, color: AppTheme.primaryColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        subject,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$questionCount questions',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
