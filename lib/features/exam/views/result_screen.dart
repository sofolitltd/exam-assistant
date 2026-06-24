import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/responsive_wrapper.dart';
import '../../auth/controllers/auth_controller.dart';
import '../controllers/exam_controller.dart';

class ResultScreen extends ConsumerStatefulWidget {
  const ResultScreen({super.key});

  @override
  ConsumerState<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends ConsumerState<ResultScreen> {
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(_saveResult);
  }

  Future<void> _saveResult() async {
    if (_saved) return;
    final quizState = ref.read(examControllerProvider);
    final exam = quizState.currentExam;
    final questions = quizState.questions;
    if (exam == null || questions == null) return;

    int correct = 0;
    int wrong = 0;
    int skipped = 0;
    for (int i = 0; i < questions.length; i++) {
      final selected = quizState.selectedOptions[i];
      if (selected == null) {
        skipped++;
        continue;
      }
      if (questions[i].correctOptionKeys.contains(selected)) {
        correct++;
      } else {
        wrong++;
      }
    }
    final score = correct - (wrong * exam.negativeMarks).toDouble();

    try {
      // TODO: Send FCM notification with exam result summary
      // e.g., await _sendResultNotification(examTitle: exam.title, score: score, total: questions.length);
      await ref.read(authServiceProvider).saveExamResult(
            score: score,
            examId: exam.examId,
            totalQuestions: questions.length,
            correctCount: correct,
            wrongCount: wrong,
            skippedCount: skipped,
          );
      _saved = true;
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final quizState = ref.watch(examControllerProvider);
    final exam = quizState.currentExam;
    final questions = quizState.questions;

    if (exam == null || questions == null) {
      return const Scaffold(body: Center(child: Text('No Data')));
    }

    int correct = 0;
    int wrong = 0;
    int skipped = 0;

    for (int i = 0; i < questions.length; i++) {
      final selected = quizState.selectedOptions[i];
      if (selected == null) {
        skipped++;
      } else if (questions[i].correctOptionKeys.contains(selected)) {
        correct++;
      } else {
        wrong++;
      }
    }

    final double totalScore =
        correct - (wrong * exam.negativeMarks).toDouble();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.go('/home');
      },
      child: Scaffold(
      appBar: AppBar(
        title: const Text('Exam Result'),
        automaticallyImplyLeading: false,
        actions: [
          TextButton(
            onPressed: () => context.go('/home'),
            child: const Text('Back'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: ResponsiveWrapper(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color:
                        const Color(0xFF005C53).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Column(
                    children: [
                      Text(
                        totalScore.toStringAsFixed(2),
                        style: Theme.of(context)
                            .textTheme
                            .displayMedium
                            ?.copyWith(
                              color: const Color(0xFF005C53),
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const Text('Total Score'),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _statItem(
                        'Correct', correct.toString(), Colors.green),
                    _statItem(
                        'Incorrect', wrong.toString(), Colors.red),
                    _statItem(
                        'Skipped', skipped.toString(), Colors.grey),
                  ],
                ),
                const SizedBox(height: 40),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Review Answers',
                    style: TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 16),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: questions.length,
                  itemBuilder: (context, index) {
                    final question = questions[index];
                    final selected =
                        quizState.selectedOptions[index];
                    final isCorrect = selected != null &&
                        question.correctOptionKeys.contains(selected);
                    final qText = question.questionText.isNotEmpty
                        ? question.questionText
                        : ' ';
                    final hasOptions = question.options.isNotEmpty;
                    final hasExplanation = question.explanation != null &&
                        question.explanation!.isNotEmpty;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 1,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 12,
                                  backgroundColor: selected == null
                                      ? Colors.transparent
                                      : (isCorrect
                                          ? Colors.green
                                          : Colors.red),
                                  child: Text(
                                    '${index + 1}',
                                    style: TextStyle(
                                      color: selected == null
                                          ? Colors.grey[600]
                                          : Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    qText,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                if (hasExplanation)
                                  IconButton(
                                    icon: const Icon(Icons.info_outline,
                                        size: 20),
                                    onPressed: () => showDialog(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: const Text('Explanation'),
                                        content: Text(question.explanation!),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(ctx),
                                            child: const Text('Close'),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            if (hasOptions) ...[
                              const SizedBox(height: 12),
                              const Divider(height: 1),
                              const SizedBox(height: 8),
                              ...question.options.map((option) {
                                final isSelected =
                                    selected == option.key;
                                final isCorrectOption = question
                                    .correctOptionKeys
                                    .contains(option.key);

                                Color borderColor;
                                Color bgColor;
                                Color textColor;
                                IconData? icon;

                                if (isCorrectOption) {
                                  borderColor = Colors.green;
                                  bgColor = Colors.green
                                      .withValues(alpha: 0.08);
                                  textColor =
                                      Colors.green.shade800;
                                  icon = Icons.check_circle;
                                } else if (isSelected &&
                                    !isCorrectOption) {
                                  borderColor = Colors.red;
                                  bgColor = Colors.red
                                      .withValues(alpha: 0.08);
                                  textColor = Colors.red.shade800;
                                  icon = Icons.cancel;
                                } else {
                                  borderColor = Colors.grey[300]!;
                                  bgColor = Colors.transparent;
                                  textColor = Colors.black87;
                                  icon = null;
                                }

                                return Padding(
                                  padding:
                                      const EdgeInsets.only(bottom: 6),
                                  child: Container(
                                    padding: const EdgeInsets
                                        .symmetric(
                                      horizontal: 12,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: borderColor,
                                        width: isCorrectOption ||
                                                isSelected
                                            ? 2
                                            : 1,
                                      ),
                                      borderRadius:
                                          BorderRadius.circular(8),
                                      color: bgColor,
                                    ),
                                    child: Row(
                                      children: [
                                        SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: DecoratedBox(
                                            decoration:
                                                BoxDecoration(
                                              shape:
                                                  BoxShape.circle,
                                              border: Border.all(
                                                color: isCorrectOption
                                                    ? Colors.green
                                                    : (isSelected
                                                        ? Colors.red
                                                        : Colors
                                                            .grey[400]!),
                                                width: 2,
                                              ),
                                              color: isCorrectOption ||
                                                      isSelected
                                                  ? borderColor
                                                  : null,
                                            ),
                                            child: Center(
                                              child: icon != null
                                                  ? Icon(
                                                      icon,
                                                      size: 14,
                                                      color: Colors
                                                          .white,
                                                    )
                                                  : null,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            option.value.isNotEmpty
                                                ? option.value
                                                : ' ',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: textColor,
                                              fontWeight: isCorrectOption ||
                                                      isSelected
                                                  ? FontWeight.w500
                                                  : FontWeight
                                                      .normal,
                                            ),
                                          ),
                                        ),
                                        if (isCorrectOption)
                                          const Padding(
                                            padding:
                                                EdgeInsets.only(
                                                    left: 8),
                                            child: Text(
                                              'Correct',
                                              style: TextStyle(
                                                color: Colors.green,
                                                fontSize: 11,
                                                fontWeight:
                                                    FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        if (isSelected &&
                                            !isCorrectOption)
                                          const Padding(
                                            padding:
                                                EdgeInsets.only(
                                                    left: 8),
                                            child: Text(
                                              'Your Answer',
                                              style: TextStyle(
                                                color: Colors.red,
                                                fontSize: 11,
                                                fontWeight:
                                                    FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                );
                              }),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => context.go('/home'),
                  child: const Text('Back to Home'),
                ),
              ],
            ),
          ),
        ),
      ),
      ),
    );
  }

  Widget _statItem(
      String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label,
            style: const TextStyle(color: Colors.grey)),
      ],
    );
  }
}
