import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/controllers/auth_controller.dart';
import '../../auth/data/models/user_model.dart';
import '../../exam/data/models/exam_result_model.dart';

final userStatsProvider = Provider<AsyncValue<UserModel?>>((ref) {
  return ref.watch(userProfileProvider);
});

final userExamResultsProvider = FutureProvider<List<ExamResultModel>>((
  ref,
) async {
  final user = ref.watch(authStateChangesProvider).value;
  if (user == null) return [];
  return ref.read(accountApiServiceProvider).getExamResults();
});
