import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/responsive_wrapper.dart';
import '../controllers/exam_controller.dart';
import '../data/models/exam_model.dart';
import '../data/services/firestore_exam_service.dart';

class _ExamWithCount {
  final ExamModel exam;
  final int questionCount;
  _ExamWithCount(this.exam, this.questionCount);
}

final allExamsProvider = FutureProvider<List<_ExamWithCount>>((ref) async {
  final service = FirestoreQuizService();
  final exams = await service.getExams(publishedOnly: true);
  final result = <_ExamWithCount>[];
  for (final exam in exams) {
    final count = await service.getExamQuestionCount(exam.examId);
    result.add(_ExamWithCount(exam, count));
  }
  return result;
});

class AllExamsScreen extends ConsumerWidget {
  const AllExamsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final examsAsync = ref.watch(allExamsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('All Exams')),
      body: ResponsiveWrapper(
        child: examsAsync.when(
          data: (allExams) {
            if (allExams.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(LucideIcons.file, size: 64, color: Colors.grey[300]),
                    const SizedBox(height: 16),
                    Text(
                      'No exams available',
                      style: TextStyle(color: Colors.grey[600], fontSize: 16),
                    ),
                  ],
                ),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              itemCount: allExams.length,
              itemBuilder: (context, index) {
                final item = allExams[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildExamCard(context, ref, item.exam, item.questionCount),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(child: Text('Error: $err')),
        ),
      ),
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
            Row(children: [
              Icon(Icons.timer_outlined, size: 18, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Text('Duration: ${exam.durationSeconds ~/ 60} minutes',
                  style: const TextStyle(fontSize: 14)),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              Icon(Icons.quiz_outlined, size: 18, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Text('Questions: ${questions.length}',
                  style: const TextStyle(fontSize: 14)),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              Icon(Icons.remove_circle_outline, size: 18, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Text('Negative: ${exam.negativeMarks}',
                  style: const TextStyle(fontSize: 14)),
            ]),
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
}
