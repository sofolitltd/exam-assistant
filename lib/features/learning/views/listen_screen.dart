import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/bangla_digits.dart';
import '../../../core/widgets/responsive_wrapper.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../exam/data/models/question_model.dart';
import '../../exam/data/services/taxonomy_api_service.dart';
import '../../exam/services/question_tts_service.dart';
import '../../exam/widgets/question_playback_bar.dart';
import '../controllers/learning_providers.dart';
import '../widgets/review_question_card.dart';

/// Hands-free revision: reads a set of questions aloud one after another
/// with the current one on screen. The set is a syllabus subject's
/// question bank when [nodeId] is given, otherwise the learner's mistakes
/// (one exam's when [examId] is given).
class ListenScreen extends ConsumerStatefulWidget {
  final String? examId;
  final int? syllabusId;
  final int? nodeId;
  final String? title;

  const ListenScreen({
    super.key,
    this.examId,
    this.syllabusId,
    this.nodeId,
    this.title,
  });

  bool get isSubjectSource => syllabusId != null && nodeId != null;

  @override
  ConsumerState<ListenScreen> createState() => _ListenScreenState();
}

class _ListenScreenState extends ConsumerState<ListenScreen> {
  late final QuestionTtsService _tts = ref.read(questionTtsServiceProvider);
  late final Future<_ListenSet> _future = _load();
  int _current = 0;

  Future<_ListenSet> _load() async {
    if (widget.isSubjectSource) {
      final questions = await TaxonomyApiService(
        accountApi: ref.read(accountApiServiceProvider),
      ).getQuestionBank(syllabusId: widget.syllabusId, nodeId: widget.nodeId);
      return _ListenSet(questions, const {});
    }
    final mistakes = await ref
        .read(learningApiServiceProvider)
        .getMistakes(examId: widget.examId);
    return _ListenSet(
      [for (final m in mistakes) m.question],
      {for (final m in mistakes) m.question.id: m.selectedKey},
    );
  }

  @override
  void dispose() {
    // Leaving the screen ends the session; otherwise audio would continue
    // with no control left on screen to stop it.
    _tts.stop();
    super.dispose();
  }

  Future<void> _playFrom(List<QuestionModel> questions, int index) async {
    setState(() => _current = index);
    await _tts.readSequence(
      questions,
      ref.read(questionReadOptionsProvider),
      startIndex: index,
      onQuestionStart: (i) {
        if (mounted) setState(() => _current = i);
      },
    );
  }

  Future<void> _jump(
    List<QuestionModel> questions,
    int index,
    bool playing,
  ) async {
    if (index < 0 || index >= questions.length) return;
    if (playing) {
      await _playFrom(questions, index);
    } else {
      setState(() => _current = index);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title =
        widget.title ??
        (widget.isSubjectSource ? 'শুনে রিভিশন' : 'ভুলগুলো শোনো');
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            tooltip: 'কী কী পড়বে',
            icon: const Icon(Icons.tune),
            onPressed: () => editReadOptions(context, ref),
          ),
        ],
      ),
      body: FutureBuilder<_ListenSet>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('প্রশ্ন লোড করা যায়নি: ${snapshot.error}'),
              ),
            );
          }
          final set = snapshot.data!;
          if (set.questions.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  widget.isSubjectSource
                      ? 'এই বিষয়ে শোনার মতো প্রশ্ন এখনো নেই।'
                      : 'শোনার মতো কোনো ভুল প্রশ্ন নেই। শেষ হওয়া পরীক্ষার ভুলগুলো এখানে আসবে।',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          final total = set.questions.length;
          final current = _current.clamp(0, total - 1);
          final question = set.questions[current];

          return ValueListenableBuilder<String?>(
            valueListenable: _tts.activeQuestionId,
            builder: (context, activeId, _) {
              final playing = activeId != null;
              return ResponsiveWrapper(
                child: Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: ReviewQuestionCard(
                          question: question,
                          index: current,
                          selectedKey: set.selected[question.id],
                          showSelection: !widget.isSubjectSource,
                          showSpeakButton: false,
                          isActive: playing,
                        ),
                      ),
                    ),
                    _PlayerControls(
                      position: current,
                      total: total,
                      playing: playing,
                      onPrevious: () =>
                          _jump(set.questions, current - 1, playing),
                      onNext: () => _jump(set.questions, current + 1, playing),
                      onToggle: () => playing
                          ? _tts.stop()
                          : _playFrom(set.questions, current),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _ListenSet {
  final List<QuestionModel> questions;
  final Map<String, String?> selected;

  const _ListenSet(this.questions, this.selected);
}

class _PlayerControls extends StatelessWidget {
  final int position;
  final int total;
  final bool playing;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onToggle;

  const _PlayerControls({
    required this.position,
    required this.total,
    required this.playing,
    required this.onPrevious,
    required this.onNext,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
        decoration: const BoxDecoration(
          color: AppColors.paper,
          border: Border(top: BorderSide(color: AppColors.line)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (position + 1) / total,
                minHeight: 5,
                backgroundColor: AppColors.sunken,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${toBanglaNumber(position + 1)} / ${toBanglaNumber(total)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  tooltip: 'আগের প্রশ্ন',
                  iconSize: 32,
                  onPressed: position > 0 ? onPrevious : null,
                  icon: const Icon(Icons.skip_previous_rounded),
                ),
                const SizedBox(width: 18),
                SizedBox(
                  width: 68,
                  height: 68,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      shape: const CircleBorder(),
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(68, 68),
                    ),
                    onPressed: onToggle,
                    child: Icon(
                      playing ? Icons.stop_rounded : Icons.play_arrow_rounded,
                      size: 36,
                    ),
                  ),
                ),
                const SizedBox(width: 18),
                IconButton(
                  tooltip: 'পরের প্রশ্ন',
                  iconSize: 32,
                  onPressed: position < total - 1 ? onNext : null,
                  icon: const Icon(Icons.skip_next_rounded),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
