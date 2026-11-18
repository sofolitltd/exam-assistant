import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/option_marker.dart';
import '../../../core/widgets/responsive_wrapper.dart';
import '../../auth/controllers/auth_controller.dart';
import '../data/models/question_model.dart';
import '../data/services/taxonomy_api_service.dart';
import '../services/question_tts_service.dart';
import '../widgets/question_playback_bar.dart';

class TaxonomyQuestionsScreen extends ConsumerStatefulWidget {
  final int syllabusId;
  final int nodeId;
  final String title;

  const TaxonomyQuestionsScreen({
    super.key,
    required this.syllabusId,
    required this.nodeId,
    required this.title,
  });

  @override
  ConsumerState<TaxonomyQuestionsScreen> createState() =>
      _TaxonomyQuestionsScreenState();
}

class _TaxonomyQuestionsScreenState
    extends ConsumerState<TaxonomyQuestionsScreen> {
  late final Future<List<QuestionModel>> _future;
  List<GlobalKey> _itemKeys = const [];
  int? _activeIndex;

  late final QuestionTtsService _tts;

  @override
  void initState() {
    super.initState();
    _tts = ref.read(questionTtsServiceProvider);
    _future = TaxonomyApiService(
      accountApi: ref.read(accountApiServiceProvider),
    ).getQuestionBank(syllabusId: widget.syllabusId, nodeId: widget.nodeId);
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
          child: Text('Could not load questions: ${snapshot.error}'),
        ),
      );
    }
    if (questions.isEmpty) {
      return Center(
        child: Text('No published practice questions for ${widget.title} yet.'),
      );
    }

    return ResponsiveWrapper(
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: questions.length,
        itemBuilder: (context, index) {
          final question = questions[index];
          final isActive = index == _activeIndex;
          return Card(
            key: _itemKeys[index],
            margin: const EdgeInsets.only(bottom: 14),
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
                      Expanded(
                        child: Text(
                          question.questionText,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      QuestionSpeakButton(question: question),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...question.options.indexed.map((entry) {
                    final (optionIndex, option) = entry;
                    final correct = question.correctOptionKeys.contains(
                      option.key,
                    );
                    return ListTile(
                      dense: true,
                      leading: OptionMarker(
                        index: optionIndex,
                        optionKey: option.key,
                        state: correct
                            ? OptionMarkerState.correct
                            : OptionMarkerState.neutral,
                      ),
                      title: Text(option.value),
                      contentPadding: EdgeInsets.zero,
                    );
                  }),
                  if (question.explanation?.isNotEmpty ?? false) ...[
                    const Divider(),
                    Text(
                      question.explanation!,
                      style: TextStyle(color: Colors.blueGrey.shade700),
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
