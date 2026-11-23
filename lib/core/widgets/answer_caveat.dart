import 'package:flutter/material.dart';

import '../../features/exam/data/models/question_model.dart';
import '../theme/app_theme.dart';
import 'ds.dart';

/// A short warning shown above an answer or explanation when the answer can
/// go out of date, is disputed, was corrected or the question was cancelled.
/// Renders nothing for an ordinary confirmed question.
class AnswerCaveat extends StatelessWidget {
  final QuestionModel question;

  const AnswerCaveat({required this.question, super.key});

  static String? messageFor(QuestionModel q) {
    switch (q.answerStatus) {
      case 'cancelled':
        return 'এই প্রশ্নটি বাতিল হয়েছে।';
      case 'disputed':
        return 'এই প্রশ্নের উত্তর নিয়ে বিতর্ক আছে। বইয়ের উত্তর নিশ্চিত নয়।';
      case 'corrected':
        return 'এই উত্তর পরে সংশোধন করা হয়েছে।';
    }
    if (q.timeSensitive) {
      return 'এই উত্তর সময়ের সাথে বদলাতে পারে। পরীক্ষার আগে সর্বশেষ তথ্য মিলিয়ে নাও।';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final message = messageFor(question);
    if (message == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 2),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.accentSoft,
          borderRadius: BorderRadius.circular(AppRadii.sm),
        ),
        child: Text(
          message,
          style: dsText(12, weight: FontWeight.w600, color: AppColors.accent),
        ),
      ),
    );
  }
}
