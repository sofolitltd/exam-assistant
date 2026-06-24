import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tex_text/tex_text.dart';

import '../../../core/utils/bangla_digits.dart';
import '../../../core/widgets/responsive_wrapper.dart';
import '../controllers/exam_controller.dart';
import '../data/services/firestore_exam_service.dart';

class LiveExamScreen extends ConsumerStatefulWidget {
  final String examId;

  const LiveExamScreen({super.key, required this.examId});

  @override
  ConsumerState<LiveExamScreen> createState() => _LiveExamScreenState();
}

class _LiveExamScreenState extends ConsumerState<LiveExamScreen> {
  Timer? _timer;
  bool _isLoading = true;
  String _selectedSubject = 'All';

  @override
  void initState() {
    super.initState();
    _loadExam();
  }

  Future<void> _loadExam() async {
    try {
      final service = FirestoreQuizService();
      final exam = await service.getExam(widget.examId);
      final questions = await service.getExamQuestions(widget.examId);
      if (exam == null || !mounted) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }
      ref.read(examControllerProvider.notifier).startExam(exam, questions);
      if (mounted) {
        setState(() => _isLoading = false);
        _startTimer();
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _startTimer() {
    final state = ref.read(examControllerProvider);
    if (state.remainingSeconds <= 0) {
      _finishExam();
      return;
    }
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final currentState = ref.read(examControllerProvider);
      if (currentState.remainingSeconds <= 0 || currentState.isCompleted) {
        _timer?.cancel();
        _finishExam();
      } else {
        ref
            .read(examControllerProvider.notifier)
            .updateTimer(currentState.remainingSeconds - 1);
      }
    });
  }

  void _finishExam() {
    ref.read(examControllerProvider.notifier).completeExam();
    context.go('/result');
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final quizState = ref.watch(examControllerProvider);
    final exam = quizState.currentExam;
    final questions = quizState.questions;

    if (exam == null || questions == null || questions.isEmpty) {
      return const Scaffold(body: Center(child: Text('No Exam Found')));
    }

    final remainingSeconds = quizState.remainingSeconds;
    final minutes = (remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (remainingSeconds % 60).toString().padLeft(2, '0');
    final answeredCount = quizState.selectedOptions.length;

    final subjects = <String>{'All'};
    for (final q in questions) {
      if (q.subject.isNotEmpty) subjects.add(q.subject);
    }
    final subjectList = subjects.toList()..sort();

    final displayIndices = List<int>.generate(questions.length, (i) => i)
        .where((i) => _selectedSubject == 'All' || questions[i].subject == _selectedSubject)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('$minutes:$seconds ($answeredCount/${questions.length})'),
     
     actions: [
      TextButton(onPressed: 
        _finishExam
      , child: Text('Submit', style: TextStyle(color: Colors.white),),),
     ],
      ),
    
      body: ResponsiveWrapper(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 20,),
              child: LinearProgressIndicator(
                value: questions.isEmpty ? 0 : answeredCount / questions.length,
              ),
            ),
            SizedBox(
              height: 48,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
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
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                itemCount: displayIndices.length,
                itemBuilder: (context, i) {
                  final index = displayIndices[i];
                  final question = questions[index];
                  final selected = quizState.selectedOptions[index];
                  final hasOptions = question.options.isNotEmpty;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 1,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                radius: 12,
                                backgroundColor: selected != null
                                    ? const Color(0xFF005C53)
                                    : Colors.grey[300],
                                child: Text(
                                  toBanglaNumber(index + 1),
                                  style: TextStyle(
                                    color: selected != null
                                        ? Colors.white
                                        : Colors.grey[600],
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TexText(
                                  question.questionText.isNotEmpty
                                      ? question.questionText
                                      : ' ',
                                  style: const TextStyle(
                                    fontSize: 16,
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
                              return Padding(
                                padding:
                                    const EdgeInsets.only(bottom: 8),
                                child: InkWell(
                                  onTap: () => ref
                                      .read(examControllerProvider
                                          .notifier)
                                      .selectOption(
                                          index, option.key),
                                  borderRadius:
                                      BorderRadius.circular(8),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: isSelected
                                            ? const Color(0xFF005C53)
                                            : Colors.grey[300]!,
                                        width: isSelected ? 2 : 1,
                                      ),
                                      borderRadius:
                                          BorderRadius.circular(8),
                                      color: isSelected
                                          ? const Color(0xFF005C53)
                                              .withValues(alpha: 0.08)
                                          : null,
                                    ),
                                    child: Row(
                                      children: [
                                        SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: DecoratedBox(
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: isSelected
                                                    ? const Color(
                                                        0xFF005C53)
                                                    : Colors.grey[400]!,
                                                width: 2,
                                              ),
                                              color: isSelected
                                                  ? const Color(
                                                      0xFF005C53)
                                                  : null,
                                            ),
                                            child: isSelected
                                                ? const Icon(
                                                    Icons.check,
                                                    size: 14,
                                                    color:
                                                        Colors.white,
                                                  )
                                                : null,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: TexText(
                                            option.value.isNotEmpty
                                                ? option.value
                                                : ' ',
                                            style: TextStyle(
                                              fontSize: 15,
                                              color: isSelected
                                                  ? const Color(
                                                      0xFF005C53)
                                                  : Colors.black87,
                                              fontWeight: isSelected
                                                  ? FontWeight.w500
                                                  : FontWeight.normal,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
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
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _finishExam,
        backgroundColor: const Color(0xFF005C53),
        foregroundColor: Colors.white,
        label: Text(
          'Submit ($answeredCount/${questions.length})',
        ),
        icon: const Icon(Icons.check_circle_outline),
      ),
    );
  }
}
