import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../auth/data/models/user_model.dart';
import '../../exam/data/models/exam_result_model.dart';
import '../../../core/constants/app_constants.dart';

final userStatsProvider = StreamProvider<UserModel?>((ref) {
  final user = ref.watch(authStateChangesProvider).value;
  if (user == null) return Stream.value(null);

  return FirebaseFirestore.instance
      .collection(AppConstants.usersCollection)
      .doc(user.uid)
      .snapshots()
      .map((doc) => doc.exists ? UserModel.fromFirestore(doc) : null);
});

final userExamResultsProvider = FutureProvider<List<ExamResultModel>>((ref) async {
  final user = ref.watch(authStateChangesProvider).value;
  if (user == null) return [];

  try {
    final snapshot = await FirebaseFirestore.instance
        .collection(AppConstants.examResultsCollection)
        .where('userId', isEqualTo: user.uid)
        .orderBy('answeredAt', descending: false)
        .get();

    return snapshot.docs.map((doc) => ExamResultModel.fromFirestore(doc)).toList();
  } catch (e) {
    debugPrint('Firestore query error (likely missing composite index): $e');
    rethrow;
  }
});
