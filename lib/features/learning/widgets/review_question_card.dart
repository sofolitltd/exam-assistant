import '../../../core/widgets/answer_caveat.dart';
import 'package:flutter/material.dart';
import 'package:tex_text/tex_text.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/bangla_digits.dart';
import '../../../core/widgets/option_marker.dart';
import '../../exam/data/models/question_model.dart';
import '../../exam/widgets/question_playback_bar.dart';
import '../data/saved_questions.dart';

/// A question with its correct answer and explanation revealed. When
/// [showSelection] is true it also marks what the learner picked: their
/// wrong pick in red, or a "skipped" tag when [selectedKey] is null.
class ReviewQuestionCard extends StatelessWidget {
  final QuestionModel question;
  final int index;
  final String? selectedKey;
  final bool showSelection;
  final bool isActive;

  /// Off where the screen has its own player (listen mode).
  final bool showSpeakButton;

  const ReviewQuestionCard({
    super.key,
    required this.question,
    required this.index,
    this.selectedKey,
    this.showSelection = false,
    this.isActive = false,
    this.showSpeakButton = true,
  });

  @override
  Widget build(BuildContext context) {
    final correctKeys = question.correctOptionKeys.toSet();
    final answeredCorrectly =
        selectedKey != null && correctKeys.contains(selectedKey);
    final badgeColor = !showSelection
        ? AppColors.brand
        : selectedKey == null
        ? AppColors.subtle
        : answeredCorrectly
        ? AppColors.success
        : AppColors.danger;
    final explanation = question.explanation?.trim() ?? '';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(
          color: isActive ? AppColors.brand : AppColors.line,
          width: isActive ? 2 : 1,
        ),
        boxShadow: isActive ? AppShadows.card : null,
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 13,
                backgroundColor: badgeColor,
                child: Text(
                  toBanglaNumber(index + 1),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
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
                    color: AppColors.ink,
                  ),
                ),
              ),
              if (showSpeakButton) QuestionSpeakButton(question: question),
              SaveQuestionButton(questionId: question.id),
            ],
          ),
          if (showSelection && selectedKey == null) ...[
            const SizedBox(height: 8),
            const _Tag(label: 'উত্তর দাওনি', color: AppColors.muted),
          ],
          const SizedBox(height: 12),
          ...question.options.indexed.map((entry) {
            final (optionIndex, option) = entry;
            final isCorrect = correctKeys.contains(option.key);
            final isWrongPick =
                showSelection && option.key == selectedKey && !isCorrect;
            final color = isCorrect
                ? AppColors.success
                : isWrongPick
                ? AppColors.danger
                : null;
            return Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: color?.withValues(alpha: 0.08) ?? AppColors.sunken,
                borderRadius: BorderRadius.circular(AppRadii.sm),
                border: Border.all(
                  color: color ?? Colors.transparent,
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  OptionMarker(
                    index: optionIndex,
                    optionKey: option.key,
                    state: isCorrect
                        ? OptionMarkerState.correct
                        : isWrongPick
                        ? OptionMarkerState.wrong
                        : OptionMarkerState.neutral,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TexText(
                      option.value.isNotEmpty ? option.value : ' ',
                      style: TextStyle(
                        fontSize: 15,
                        color: color ?? AppColors.ink2,
                        fontWeight: color != null
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                  if (isWrongPick)
                    const _Tag(label: 'তোমার উত্তর', color: AppColors.danger),
                ],
              ),
            );
          }),
          AnswerCaveat(question: question),
          if (explanation.isNotEmpty) ...[
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.accentSoft,
                borderRadius: BorderRadius.circular(AppRadii.sm),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.lightbulb_outline,
                    size: 18,
                    color: Color(0xFFB4730F),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TexText(
                      explanation,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.ink2,
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;
  final Color color;

  const _Tag({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
