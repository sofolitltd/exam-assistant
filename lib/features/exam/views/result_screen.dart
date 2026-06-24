import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tex_text/tex_text.dart';

import '../../../core/utils/bangla_digits.dart';
import '../../../core/widgets/responsive_wrapper.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../dashboard/controllers/stats_controller.dart';
import '../controllers/exam_controller.dart';

class ResultScreen extends ConsumerStatefulWidget {
  const ResultScreen({super.key});

  @override
  ConsumerState<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends ConsumerState<ResultScreen> {
  bool _saved = false;
  String _selectedSubject = 'All';

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
      ref.invalidate(userExamResultsProvider);
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

    final double totalNegative = wrong * exam.negativeMarks;
    final double totalScore = correct - totalNegative;

    final timeTakenSeconds = exam.durationSeconds - quizState.remainingSeconds;
    final minutes = timeTakenSeconds ~/ 60;
    final seconds = timeTakenSeconds % 60;

    final subjects = <String>{'All'};
    for (final q in questions) {
      if (q.subject.isNotEmpty) subjects.add(q.subject);
    }
    final subjectList = subjects.toList()..sort();

    final displayQuestions = _selectedSubject == 'All'
        ? questions
        : questions.where((q) => q.subject == _selectedSubject).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Exam Result'),
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
                const SizedBox(height: 24),
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 1,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.bar_chart, size: 20, color: Color(0xFF005C53)),
                            const SizedBox(width: 8),
                            const Text(
                              'Score Breakdown',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ],
                        ),
                        const Divider(height: 20),
                        _detailRow('Correct', correct.toString(), Colors.green, Icons.check_circle),
                        const SizedBox(height: 8),
                        _detailRow('Incorrect', wrong.toString(), Colors.red, Icons.cancel),
                        const SizedBox(height: 8),
                        _detailRow(
                          'Total Attempt',
                          (correct + wrong).toString(),
                          Colors.indigo,
                          Icons.arrow_forward,
                        ),
                        const SizedBox(height: 8),
                        _detailRow('Skipped', skipped.toString(), Colors.grey, Icons.remove_circle_outline),
                        const SizedBox(height: 8),
                        _detailRow(
                          'Negative',
                          '-${totalNegative.toStringAsFixed(2)}',
                          Colors.orange,
                          Icons.do_not_disturb_alt,
                        ),
                        const SizedBox(height: 8),
                        _detailRow(
                          'Time Taken',
                          '${minutes}m ${seconds}s',
                          Colors.blue,
                          Icons.timer_outlined,
                        ),
                        const Divider(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total Score',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Color(0xFF005C53),
                              ),
                            ),
                            Text(
                              totalScore.toStringAsFixed(2),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                                color: Color(0xFF005C53),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
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
                SizedBox(
                  height: 48,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    children: subjectList.map((subject) {
                      final isSelected = subject == _selectedSubject;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(
                            subject,
                            style: TextStyle(
                              fontSize: 13,
                              color: isSelected ? Colors.white : Colors.black87,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                          selected: isSelected,
                          onSelected: (_) => setState(() => _selectedSubject = subject),
                          selectedColor: const Color(0xFF005C53),
                          checkmarkColor: Colors.white,
                          backgroundColor: Colors.grey[100],
                          side: BorderSide.none,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 8),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: displayQuestions.length,
                  itemBuilder: (context, index) {
                    final question = displayQuestions[index];
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
                                      ? Colors.grey[300]
                                      : (isCorrect
                                          ? Colors.green
                                          : Colors.red),
                                  child: Text(
                                    toBanglaNumber(index + 1),
                                    style: TextStyle(
                                      color: selected == null
                                          ? Colors.black54
                                          : Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TexText(
                                    qText,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
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
                                          child: TexText(
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
                            if (hasExplanation) ...[
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(Icons.lightbulb_outline,
                                        size: 18, color: Colors.blue),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: TexText(
                                        question.explanation!,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: Colors.blue,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
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
    );
  }

  Widget _detailRow(String label, String value, Color color, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 14, color: Colors.black87)),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
