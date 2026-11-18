import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/responsive_wrapper.dart';
import '../../exam/services/question_tts_service.dart';
import '../../exam/widgets/question_playback_bar.dart';
import '../controllers/learning_providers.dart';
import '../widgets/review_question_card.dart';

/// Every question the learner most recently got wrong or skipped — one
/// exam's when [examId] is set, otherwise across all exams. Answering one
/// correctly in a later attempt removes it from this list.
class MistakesPracticeScreen extends ConsumerStatefulWidget {
  final String? examId;
  final String? title;

  const MistakesPracticeScreen({super.key, this.examId, this.title});

  @override
  ConsumerState<MistakesPracticeScreen> createState() =>
      _MistakesPracticeScreenState();
}

class _MistakesPracticeScreenState
    extends ConsumerState<MistakesPracticeScreen> {
  List<GlobalKey> _itemKeys = const [];
  int? _activeIndex;
  late final QuestionTtsService _tts;

  @override
  void initState() {
    super.initState();
    _tts = ref.read(questionTtsServiceProvider);
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
          alignment: 0.1,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final mistakesAsync = ref.watch(mistakesProvider(widget.examId));
    final mistakes = mistakesAsync.value ?? const [];
    if (_itemKeys.length != mistakes.length) {
      _itemKeys = List.generate(mistakes.length, (_) => GlobalKey());
    }
    final questions = [for (final m in mistakes) m.question];

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title ?? 'ভুলগুলো প্র্যাকটিস'),
        actions: [
          if (questions.isNotEmpty) ...[
            IconButton(
              tooltip: 'শুনে রিভিশন',
              icon: const Icon(Icons.headphones_outlined),
              onPressed: () => context.push(
                widget.examId == null
                    ? '/listen'
                    : '/listen?examId=${Uri.encodeQueryComponent(widget.examId!)}',
              ),
            ),
            QuestionPlaybackBar(
              questions: questions,
              onActiveIndexChanged: _handleActiveIndexChanged,
            ),
          ],
        ],
      ),
      body: mistakesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('ভুল প্রশ্নগুলো লোড করা যায়নি: $error'),
          ),
        ),
        data: (items) {
          if (items.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'দারুণ! এখন প্র্যাকটিস করার মতো কোনো ভুল প্রশ্ন নেই।\n'
                  'শেষ হওয়া পরীক্ষার ভুলগুলো এখানে জমা হবে।',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return ResponsiveWrapper(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: items.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      '${items.length}টি প্রশ্ন — সঠিক উত্তর সবুজে, তোমার ভুল উত্তর লালে।',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  );
                }
                final i = index - 1;
                return ReviewQuestionCard(
                  key: _itemKeys[i],
                  question: items[i].question,
                  index: i,
                  selectedKey: items[i].selectedKey,
                  showSelection: true,
                  isActive: i == _activeIndex,
                );
              },
            ),
          );
        },
      ),
    );
  }
}
