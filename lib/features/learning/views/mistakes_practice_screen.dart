import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/bangla_digits.dart';
import '../../../core/widgets/ds.dart';
import '../../../core/widgets/ds_picker.dart';
import '../../bcs/data/bcs_models.dart';
import '../../bcs/views/practice_screen.dart';
import '../../exam/data/models/question_model.dart';
import '../../exam/services/question_tts_service.dart';
import '../../exam/widgets/question_playback_bar.dart';
import '../controllers/learning_providers.dart';
import '../data/practice_models.dart';
import '../widgets/review_question_card.dart';

/// আমার ভুল: every question whose latest answer was wrong, from ranked
/// exams and from practice, filtered by where it was made and by subject.
/// "আবার দাও" retries them as practice; a right answer drops one from the
/// list. [examId] limits it to one paper.
class MistakesPracticeScreen extends ConsumerStatefulWidget {
  final String? examId;
  final String? title;

  /// Initial filter: `exam`, `practice` or null for both.
  final String? mode;

  const MistakesPracticeScreen({super.key, this.examId, this.title, this.mode});

  @override
  ConsumerState<MistakesPracticeScreen> createState() =>
      _MistakesPracticeScreenState();
}

class _MistakesPracticeScreenState
    extends ConsumerState<MistakesPracticeScreen> {
  late String? _mode = widget.mode == 'exam' || widget.mode == 'practice'
      ? widget.mode
      : null;
  int? _subjectId;
  List<GlobalKey> _itemKeys = const [];
  int? _activeIndex;
  late final QuestionTtsService _tts;
  final _scrollController = ScrollController();

  MistakeFilter get _filter =>
      (examId: widget.examId, mode: _mode, subjectId: _subjectId);

  @override
  void initState() {
    super.initState();
    _tts = ref.read(questionTtsServiceProvider);
    _scrollController.addListener(_maybeLoadMore);
  }

  @override
  void dispose() {
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
    ref.read(filteredMistakesProvider(_filter).notifier).loadMore();
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

  void _retry(List<QuestionModel> questions, String subjectLabel) {
    final where = switch (_mode) {
      'exam' => 'প্রতিযোগিতার ভুল',
      'practice' => 'অনুশীলনের ভুল',
      _ => 'আমার ভুল',
    };
    final label = [
      widget.title ?? where,
      if (_subjectId != null) subjectLabel,
    ].join(' · ');
    context.push(
      '/practice/run',
      extra: PracticeRunScreen(
        title: 'ভুলগুলো আবার দাও',
        subtitle: '$label · ${bn(questions.length)} প্রশ্ন',
        questions: [for (final q in questions) PaperQuestion(q)],
        target: PracticeTarget(
          source: 'mistakes',
          examId: widget.examId,
          label: label,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(filteredMistakesProvider(_filter));
    // The per-mode and per-subject counts only cover all papers.
    final summary = widget.examId == null
        ? ref.watch(mistakeSummaryProvider).value
        : null;
    final mistakes = state.items;
    if (_itemKeys.length != mistakes.length) {
      _itemKeys = List.generate(mistakes.length, (_) => GlobalKey());
    }
    final questions = [for (final m in mistakes) m.question];
    final subjects = summary?.subjects ?? const <MistakeSubjectCount>[];
    String subjectLabel = 'সব বিষয়';
    for (final s in subjects) {
      if (s.subjectId == _subjectId) subjectLabel = s.name;
    }

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: DsHeader(
        title: widget.title == null ? 'আমার ভুল' : '${widget.title} · আমার ভুল',
        subtitle: summary == null
            ? 'প্রতিযোগিতা আর অনুশীলন, দুটোর ভুলই এখানে'
            : '${bn(summary.total)}টি ভুল এখনো ঠিক করা বাকি',
        trailing: questions.isEmpty
            ? null
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: 'শুনে রিভিশন',
                    icon: const Icon(LucideIcons.headphones, size: 20),
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
              ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(mistakeSummaryProvider);
          await ref.read(filteredMistakesProvider(_filter).notifier).refresh();
        },
        child: ListView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
          children: [
            DsCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DsSegmented<String?>(
                    height: 40,
                    fontSize: 13,
                    value: _mode,
                    onChanged: (m) => setState(() => _mode = m),
                    items: [
                      (null, _withCount('সব', summary?.total), null),
                      (
                        'practice',
                        _withCount('অনুশীলন', summary?.practice),
                        null,
                      ),
                      ('exam', _withCount('প্রতিযোগিতা', summary?.exam), null),
                    ],
                  ),
                  if (subjects.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    DsPickerRow(
                      label: 'বিষয়',
                      value: subjectLabel,
                      count: _subjectId == null
                          ? summary!.total
                          : subjects
                                .firstWhere(
                                  (s) => s.subjectId == _subjectId,
                                  orElse: () =>
                                      const MistakeSubjectCount(0, '', 0),
                                )
                                .count,
                      onTap: () async {
                        final id = await showDsPicker(
                          context,
                          title: 'কোন বিষয়ের ভুল?',
                          selected: '${_subjectId ?? 'all'}',
                          items: [
                            ('all', 'সব বিষয়', summary!.total),
                            for (final s in subjects)
                              ('${s.subjectId}', s.name, s.count),
                          ],
                        );
                        if (id == null) return;
                        setState(() => _subjectId = int.tryParse(id));
                      },
                    ),
                  ],
                  const SizedBox(height: 14),
                  DsButton(
                    label: mistakes.isEmpty
                        ? 'আবার দেওয়ার মতো ভুল নেই'
                        : 'আবার দাও · ${bn(mistakes.length)}${state.hasMore ? '+' : ''}টি প্রশ্ন',
                    height: 50,
                    onPressed: mistakes.isEmpty
                        ? null
                        : () => _retry(questions, subjectLabel),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'ঠিক করলে প্রশ্নটা তালিকা থেকে সরে যাবে, তবে রিভিশনে কয়েক দিন পর আবার আসবে।',
                    style: dsText(12, height: 1.5, color: AppColors.muted),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (state.isLoading)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (state.error != null && mistakes.isEmpty)
              _Message(
                icon: LucideIcons.wifiOff,
                text: 'ভুলগুলো লোড করা যায়নি। টেনে নামিয়ে আবার চেষ্টা করো।',
              )
            else if (mistakes.isEmpty)
              _Message(
                icon: LucideIcons.partyPopper,
                text: _mode == null && _subjectId == null
                    ? 'দারুণ! এখন ঠিক করার মতো কোনো ভুল নেই।\n'
                          'অনুশীলন বা প্রতিযোগিতায় যা ভুল হবে, এখানে জমা হবে।'
                    : 'এই ফিল্টারে কোনো ভুল নেই।',
              )
            else ...[
              SectionLabel(
                'সঠিক উত্তর সবুজে, তোমার উত্তর লালে',
                trailing: '${bn(mistakes.length)}টি',
              ),
              for (var i = 0; i < mistakes.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 4, bottom: 4),
                        child: Text(
                          mistakes[i].mode == 'practice'
                              ? 'অনুশীলনে ভুল'
                              : 'প্রতিযোগিতায় ভুল',
                          style: dsText(
                            11,
                            weight: FontWeight.w600,
                            color: AppColors.muted,
                          ),
                        ),
                      ),
                      ReviewQuestionCard(
                        key: _itemKeys[i],
                        question: mistakes[i].question,
                        index: i,
                        selectedKey: mistakes[i].selectedKey,
                        showSelection: true,
                        isActive: i == _activeIndex,
                      ),
                    ],
                  ),
                ),
              if (state.isLoadingMore)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(child: CircularProgressIndicator()),
                ),
            ],
          ],
        ),
      ),
    );
  }

  static String _withCount(String label, int? count) =>
      count == null ? label : '$label ${bn(count)}';
}

class _Message extends StatelessWidget {
  final IconData icon;
  final String text;

  const _Message({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      child: Column(
        children: [
          Icon(icon, size: 32, color: AppColors.muted),
          const SizedBox(height: 10),
          Text(
            text,
            textAlign: TextAlign.center,
            style: dsText(14, height: 1.6, color: AppColors.ink2),
          ),
        ],
      ),
    );
  }
}
