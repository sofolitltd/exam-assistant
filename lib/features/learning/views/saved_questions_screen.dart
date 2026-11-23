import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/bangla_digits.dart';
import '../../../core/widgets/ds.dart';
import '../../../core/widgets/responsive_wrapper.dart';
import '../../exam/services/question_tts_service.dart';
import '../data/saved_questions.dart';
import '../widgets/review_question_card.dart';

/// সংরক্ষিত: the questions the learner starred, newest first.
class SavedQuestionsScreen extends ConsumerStatefulWidget {
  const SavedQuestionsScreen({super.key});

  @override
  ConsumerState<SavedQuestionsScreen> createState() =>
      _SavedQuestionsScreenState();
}

class _SavedQuestionsScreenState extends ConsumerState<SavedQuestionsScreen> {
  final _scroll = ScrollController();
  late final QuestionTtsService _tts;

  @override
  void initState() {
    super.initState();
    _tts = ref.read(questionTtsServiceProvider);
    _scroll.addListener(() {
      if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 200) {
        ref.read(savedQuestionsProvider.notifier).loadMore();
      }
    });
  }

  @override
  void dispose() {
    _tts.stop();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(savedQuestionsProvider);
    final items = state.items;

    Widget body;
    if (state.isLoading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (state.error != null && items.isEmpty) {
      body = _Message(
        'সংরক্ষিত প্রশ্ন লোড করা যায়নি। ইন্টারনেট দেখে আবার চেষ্টা করো।',
        action: DsSmallButton(
          label: 'আবার চেষ্টা',
          onPressed: () => ref.read(savedQuestionsProvider.notifier).refresh(),
        ),
      );
    } else if (items.isEmpty) {
      body = const _Message(
        'এখনো কিছু সংরক্ষণ করোনি।\nযেকোনো প্রশ্নের পাশের বুকমার্ক চেপে রাখো, এখানে জমা হবে।',
      );
    } else {
      body = RefreshIndicator(
        onRefresh: () => ref.read(savedQuestionsProvider.notifier).refresh(),
        child: ResponsiveWrapper(
          child: ListView.builder(
            controller: _scroll,
            padding: const EdgeInsets.all(16),
            itemCount: items.length + 1 + (state.isLoadingMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == 0) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    '${bn(items.length)}${state.hasMore ? '+' : ''}টি প্রশ্ন',
                    style: dsText(13, color: AppColors.muted),
                  ),
                );
              }
              if (index == items.length + 1) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final i = index - 1;
              return ReviewQuestionCard(
                key: ValueKey(items[i].question.id),
                question: items[i].question,
                index: i,
              );
            },
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: const DsHeader(title: 'সংরক্ষিত প্রশ্ন'),
      body: body,
    );
  }
}

class _Message extends StatelessWidget {
  final String text;
  final Widget? action;

  const _Message(this.text, {this.action});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              text,
              textAlign: TextAlign.center,
              style: dsText(15, color: AppColors.ink2, height: 1.5),
            ),
            if (action != null) ...[const SizedBox(height: 16), action!],
          ],
        ),
      ),
    );
  }
}
