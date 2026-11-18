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
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tts = ref.read(questionTtsServiceProvider);
    _scrollController.addListener(_maybeLoadMore);
  }

  @override
  void dispose() {
    // Stop reading aloud when leaving the screen; otherwise playback
    // continues with no control left to stop it.
    _tts.stop();
    _scrollController.removeListener(_maybeLoadMore);
    _scrollController.dispose();
    super.dispose();
  }

  void _maybeLoadMore() {
    if (_scrollController.position.pixels <
        _scrollController.position.maxScrollExtent - 200) {
      return;
    }
    ref.read(mistakesProvider(widget.examId).notifier).loadMore();
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
    final state = ref.watch(mistakesProvider(widget.examId));
    final mistakes = state.items;
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
      body: Builder(
        builder: (context) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.error != null && mistakes.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('ভুল প্রশ্নগুলো লোড করা যায়নি: ${state.error}'),
              ),
            );
          }
          if (mistakes.isEmpty) {
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
          return RefreshIndicator(
            onRefresh: () =>
                ref.read(mistakesProvider(widget.examId).notifier).refresh(),
            child: ResponsiveWrapper(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: mistakes.length + 1 + (state.isLoadingMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        '${mistakes.length}টি প্রশ্ন — সঠিক উত্তর সবুজে, তোমার ভুল উত্তর লালে।',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    );
                  }
                  if (index == mistakes.length + 1) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  final i = index - 1;
                  return ReviewQuestionCard(
                    key: _itemKeys[i],
                    question: mistakes[i].question,
                    index: i,
                    selectedKey: mistakes[i].selectedKey,
                    showSelection: true,
                    isActive: i == _activeIndex,
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
