import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/controllers/auth_controller.dart';
import '../data/learning_api_service.dart';
import '../data/learning_models.dart';

final learningApiServiceProvider = Provider<LearningApiService>((ref) {
  return LearningApiService(ref.watch(accountApiServiceProvider));
});

final examLeaderboardProvider = FutureProvider.autoDispose
    .family<ExamLeaderboard, String>((ref, examId) {
      return ref.read(learningApiServiceProvider).getExamLeaderboard(examId);
    });

/// Mistakes across all exams when the key is null, or one exam's.
final mistakesProvider = FutureProvider.autoDispose
    .family<List<MistakeQuestion>, String?>((ref, examId) {
      return ref.read(learningApiServiceProvider).getMistakes(examId: examId);
    });

final subjectPerformanceProvider =
    FutureProvider.autoDispose<List<SubjectPerformance>>((ref) {
      return ref.read(learningApiServiceProvider).getSubjectPerformance();
    });
