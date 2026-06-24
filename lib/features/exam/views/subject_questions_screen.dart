import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:tex_text/tex_text.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/responsive_wrapper.dart';
import '../data/models/question_model.dart';
import '../data/services/firestore_quiz_service.dart';

class SubjectQuestionsScreen extends ConsumerWidget {
  final String subject;

  const SubjectQuestionsScreen({super.key, required this.subject});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: Text(subject)),
      body: FutureBuilder<List<QuestionModel>>(
        future: FirestoreQuizService().getQuestionsBySubject(subject),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final questions = snapshot.data ?? [];
          if (questions.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(LucideIcons.book, size: 64, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text(
                    'No questions found for $subject',
                    style: TextStyle(color: Colors.grey[600], fontSize: 16),
                  ),
                ],
              ),
            );
          }
          return ResponsiveWrapper(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: questions.length,
              itemBuilder: (context, index) {
                final q = questions[index];
                bool isCorrect(String key) =>
                    q.correctOptionKeys.contains(key);
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
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
                              backgroundColor: AppTheme.primaryColor,
                              child: Text(
                                '${index + 1}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ClipRect(
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    minHeight: 44,
                                    maxHeight: 86,
                                  ),
                                  child: TexText(
                                    q.questionText.isNotEmpty
                                        ? q.questionText
                                        : ' ',
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Divider(height: 1),
                        const SizedBox(height: 8),
                        ...q.options.map((opt) {
                          final correct = isCorrect(opt.key);
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: correct
                                      ? Colors.green
                                      : Colors.grey[300]!,
                                  width: correct ? 2 : 1,
                                ),
                                borderRadius: BorderRadius.circular(8),
                                color: correct
                                    ? Colors.green.withValues(alpha: 0.08)
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
                                          color: correct
                                              ? Colors.green
                                              : Colors.grey[400]!,
                                          width: 2,
                                        ),
                                        color: correct
                                            ? Colors.green
                                            : null,
                                      ),
                                      child: correct
                                          ? const Icon(Icons.check,
                                              size: 14,
                                              color: Colors.white)
                                          : null,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: ClipRect(
                                      child: ConstrainedBox(
                                        constraints: BoxConstraints(
                                          minHeight: 42,
                                          maxHeight: 80,
                                        ),
                                        child: TexText(
                                          opt.value.isNotEmpty
                                              ? opt.value
                                              : ' ',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: correct
                                                ? Colors.green.shade800
                                                : Colors.black87,
                                            fontWeight: correct
                                                ? FontWeight.w500
                                                : FontWeight.normal,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  if (correct)
                                    const Padding(
                                      padding: EdgeInsets.only(left: 8),
                                      child: Text(
                                        'Correct',
                                        style: TextStyle(
                                          color: Colors.green,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        }),
                        if (q.explanation != null &&
                            q.explanation!.isNotEmpty) ...[
                          const SizedBox(height: 8),
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
                                  child: ClipRect(
                                    child: ConstrainedBox(
                                      constraints: BoxConstraints(
                                        minHeight: 38,
                                        maxHeight: 74,
                                      ),
                                      child: TexText(
                                        q.explanation!,
                                        style:  TextStyle(
                                          fontSize: 13,
                                          fontFamily: GoogleFonts.googleSans().fontFamily,
                                          color: Colors.blue,
                                        ),
                                      ),
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
          );
        },
      ),
    );
  }
}
