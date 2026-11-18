import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
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

class SubjectQuestionsScreen extends ConsumerStatefulWidget {
  final String subject;

  const SubjectQuestionsScreen({super.key, required this.subject});

  @override
  ConsumerState<SubjectQuestionsScreen> createState() =>
      _SubjectQuestionsScreenState();
}

class _SubjectQuestionsScreenState
    extends ConsumerState<SubjectQuestionsScreen> {
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
    ).getQuestionsBySubject(widget.subject);
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
            title: Text(widget.subject),
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
      return Center(child: Text('Error: ${snapshot.error}'));
    }
    if (questions.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.book, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'No questions found for ${widget.subject}',
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
          bool isCorrect(String key) => q.correctOptionKeys.contains(key);
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
                          q.questionText.isNotEmpty ? q.questionText : ' ',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      QuestionSpeakButton(question: q),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 8),
                  ...q.options.indexed.map((entry) {
                    final (optionIndex, opt) = entry;
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
                              optionKey: opt.key,
                              state: correct
                                  ? OptionMarkerState.correct
                                  : OptionMarkerState.neutral,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TexText(
                                opt.value.isNotEmpty ? opt.value : ' ',
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
                  if (q.explanation != null && q.explanation!.isNotEmpty) ...[
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
                              q.explanation!,
                              style: TextStyle(
                                fontSize: 13,
                                fontFamily: GoogleFonts.googleSans().fontFamily,
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
