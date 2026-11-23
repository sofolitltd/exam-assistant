import '../../learning/data/saved_questions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tex_text/tex_text.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/bangla_digits.dart';
import '../../../core/widgets/option_marker.dart';
import '../../../core/widgets/responsive_wrapper.dart';
import '../../auth/controllers/auth_controller.dart';
import '../data/models/question_model.dart';
import '../data/services/exam_api_service.dart';
import '../services/question_tts_service.dart';
import '../widgets/question_playback_bar.dart';

/// Shows every question of a finished exam, in its original order, with the
/// correct answer and explanation already revealed — so a learner can study
/// the whole exam as one paper (rather than split by chapter/subject) once
/// its scheduled window has passed.
class ExamAnswerKeyScreen extends ConsumerStatefulWidget {
  final String examId;
  final String title;

  const ExamAnswerKeyScreen({
    super.key,
    required this.examId,
    required this.title,
  });

  @override
  ConsumerState<ExamAnswerKeyScreen> createState() =>
      _ExamAnswerKeyScreenState();
}

class _ExamAnswerKeyScreenState extends ConsumerState<ExamAnswerKeyScreen> {
  late final Future<List<QuestionModel>> _future;
  List<GlobalKey> _itemKeys = const [];
  int? _activeIndex;

  late final QuestionTtsService _tts;

  @override
  void initState() {
    super.initState();
    _tts = ref.read(questionTtsServiceProvider);
    _future = ExamApiService(
      accountApi: ref.read(accountApiServiceProvider),
    ).getExamAnswerKey(widget.examId);
  }

  @override
  void dispose() {
    // Stop reading aloud when leaving the screen; otherwise playback
    // continues with no control left to stop it.
    _tts.stop();
    super.dispose();
  }

  void _handleActiveIndexChanged(int? index) {
    if (!mounted) return;
    setState(() => _activeIndex = index);
    if (index == null || index >= _itemKeys.length) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final itemContext = _itemKeys[index].currentContext;
      if (itemContext != null) {
        Scrollable.ensureVisible(
          itemContext,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          alignment: 0.1,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<QuestionModel>>(
      future: _future,
      builder: (context, snapshot) {
        final questions = snapshot.data ?? const <QuestionModel>[];
        if (_itemKeys.length != questions.length) {
          _itemKeys = List.generate(questions.length, (_) => GlobalKey());
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(widget.title),
            actions: [
              QuestionPlaybackBar(
                questions: questions,
                onActiveIndexChanged: _handleActiveIndexChanged,
              ),
            ],
          ),
          body: _buildBody(snapshot, questions),
        );
      },
    );
  }

  Widget _buildBody(
    AsyncSnapshot<List<QuestionModel>> snapshot,
    List<QuestionModel> questions,
  ) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(child: CircularProgressIndicator());
    }
    if (snapshot.hasError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text('${snapshot.error}', textAlign: TextAlign.center),
        ),
      );
    }
    if (questions.isEmpty) {
      return const Center(child: Text('This exam has no questions.'));
    }

    return ResponsiveWrapper(
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: questions.length,
        itemBuilder: (context, index) {
          final question = questions[index];
          final correctKeys = question.correctOptionKeys.toSet();
          final qText = question.questionText.isNotEmpty
              ? question.questionText
              : ' ';
          final hasExplanation = question.explanation?.isNotEmpty ?? false;
          final isActive = index == _activeIndex;

          return Card(
            key: _itemKeys[index],
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: isActive
                  ? const BorderSide(color: AppTheme.primaryColor, width: 2)
                  : BorderSide.none,
            ),
            elevation: isActive ? 4 : 1,
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
                          toBanglaNumber(index + 1),
                          style: const TextStyle(
                            color: Colors.white,
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
                      QuestionSpeakButton(question: question),
                      SaveQuestionButton(questionId: question.id),
                    ],
                  ),
                  if (question.options.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Divider(height: 1),
                    const SizedBox(height: 8),
                    ...question.options.indexed.map((entry) {
                      final (optionIndex, option) = entry;
                      final correct = correctKeys.contains(option.key);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: correct ? Colors.green : Colors.grey[300]!,
                              width: correct ? 2 : 1,
                            ),
                            borderRadius: BorderRadius.circular(8),
                            color: correct
                                ? Colors.green.withValues(alpha: 0.08)
                                : null,
                          ),
                          child: Row(
                            children: [
                              OptionMarker(
                                index: optionIndex,
                                optionKey: option.key,
                                state: correct
                                    ? OptionMarkerState.correct
                                    : OptionMarkerState.neutral,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TexText(
                                  option.value.isNotEmpty ? option.value : ' ',
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
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                  if (hasExplanation) ...[
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
                          const Icon(
                            Icons.lightbulb_outline,
                            size: 18,
                            color: Colors.blue,
                          ),
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
    );
  }
}
