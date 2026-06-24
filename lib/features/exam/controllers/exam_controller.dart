import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/models/exam_model.dart';
import '../data/models/question_model.dart';

part 'exam_controller.g.dart';

class QuizState {
  final ExamModel? currentExam;
  final List<QuestionModel>? questions;
  final int remainingSeconds;
  final Map<int, String> selectedOptions;
  final bool isCompleted;

  QuizState({
    this.currentExam,
    this.questions,
    this.remainingSeconds = 0,
    Map<int, String>? selectedOptions,
    this.isCompleted = false,
  }) : selectedOptions = selectedOptions ?? {};
}

@Riverpod(keepAlive: true)
class ExamController extends _$ExamController {
  @override
  QuizState build() => QuizState();

  void startExam(ExamModel exam, List<QuestionModel> questions) {
    state = QuizState(
      currentExam: exam,
      questions: questions,
      remainingSeconds: exam.durationSeconds,
    );
  }

  void updateTimer(int seconds) {
    state = QuizState(
      currentExam: state.currentExam,
      questions: state.questions,
      remainingSeconds: seconds,
      selectedOptions: Map.from(state.selectedOptions),
      isCompleted: state.isCompleted,
    );
  }

  void selectOption(int questionIndex, String option) {
    final updatedOptions = Map<int, String>.from(state.selectedOptions);
    updatedOptions[questionIndex] = option;
    state = QuizState(
      currentExam: state.currentExam,
      questions: state.questions,
      remainingSeconds: state.remainingSeconds,
      selectedOptions: updatedOptions,
      isCompleted: state.isCompleted,
    );
  }

  void completeExam() {
    state = QuizState(
      currentExam: state.currentExam,
      questions: state.questions,
      remainingSeconds: state.remainingSeconds,
      selectedOptions: Map.from(state.selectedOptions),
      isCompleted: true,
    );
  }
}
