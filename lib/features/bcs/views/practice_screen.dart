import '../../../core/widgets/answer_caveat.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/bangla_digits.dart';
import '../../../core/widgets/ds.dart';
import '../../exam/services/question_tts_service.dart';
import '../../learning/controllers/learning_providers.dart';
import '../../learning/data/practice_models.dart';
import '../../learning/data/practice_recorder.dart';
import '../data/bcs_models.dart';
import '../data/bcs_api.dart';
import 'bcs_async.dart';
import 'bcs_format.dart';

String selectionSubtitle(PaperSelection s, int count) {
  final topic = s.topicId == 'all' ? '' : ' · ${s.topicLabel}';
  return '${s.subjectLabel}$topic · ${bn(count)} প্রশ্ন';
}

/// Mode ২: অনুশীলন. Tap an option and see right/wrong and the explanation
/// at once. Not timed and not ranked.
class PracticeScreen extends ConsumerWidget {
  final int number;
  final PaperSelection selection;

  const PracticeScreen({
    required this.number,
    this.selection = PaperSelection.all,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paper = ref.watch(bcsPaperProvider(number));
    final examId = paper.value?.examId;
    final mistakes = selection.wrongOnly && examId != null
        ? ref.watch(bcsMistakeIdsProvider(examId))
        : const AsyncData<Set<String>>({});
    return BcsAsync(
      title: bnOrdinal(number),
      value: paper,
      onRetry: () => ref.invalidate(bcsPaperProvider(number)),
      builder: (paper) => BcsAsync(
        title: bnOrdinal(number),
        value: mistakes,
        builder: (mistakes) {
          final questions = selectQuestions(
            paper,
            selection,
            mistakes: mistakes,
          );
          if (questions.isEmpty) {
            return BcsAsync<void>(
              title: bnOrdinal(number),
              value: const AsyncError(BcsEmptySelection(), StackTrace.empty),
              builder: (_) => const SizedBox(),
            );
          }
          final topic = selection.topicId == 'all'
              ? ''
              : ' · ${selection.topicLabel}';
          return PracticeRunScreen(
            title: '${bnOrdinal(number)} · অনুশীলন',
            subtitle: selectionSubtitle(selection, questions.length),
            questions: questions,
            target: PracticeTarget(
              source: 'paper',
              examId: paper.examId,
              label: '${editionName(number)} · ${selection.subjectLabel}$topic',
            ),
          );
        },
      ),
    );
  }
}

/// One practice sitting over [questions]: tap an option, see right/wrong
/// and the explanation at once. Every answer is saved as it is given (see
/// [PracticeRecorder]), so it counts in আমার ভুল, রিভিশন and the stats.
/// Used by paper practice, topic practice and mistake practice.
class PracticeRunScreen extends ConsumerStatefulWidget {
  final String title;
  final String subtitle;
  final List<PaperQuestion> questions;
  final PracticeTarget target;

  const PracticeRunScreen({
    required this.title,
    required this.subtitle,
    required this.questions,
    required this.target,
    super.key,
  });

  @override
  ConsumerState<PracticeRunScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends ConsumerState<PracticeRunScreen> {
  late final List<PaperQuestion> _questions = widget.questions;
  late final QuestionTtsService _tts;
  late final PracticeRecorder _recorder;
  late final ProviderContainer _container;
  final Map<int, String> _answers = {};
  bool _single = false;
  int _cur = 0;
  DateTime _shownAt = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tts = ref.read(questionTtsServiceProvider);
    _recorder = ref.read(practiceRecorderFactoryProvider)(widget.target);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _container = ProviderScope.containerOf(context, listen: false);
  }

  @override
  void dispose() {
    _tts.stop();
    // Leaving early still keeps what was answered: send anything queued,
    // then reload the screens that show answers.
    final container = _container;
    if (_answers.isNotEmpty) {
      _recorder.flush().whenComplete(() => _refresh(container));
    }
    super.dispose();
  }

  static void _refresh(ProviderContainer c) {
    refreshLearningData(c);
    c.invalidate(bcsMistakeIdsProvider);
  }

  void _go(int i) => setState(() {
    _cur = i;
    _shownAt = DateTime.now();
  });

  int get _right => _answers.entries
      .where((e) => _questions[e.key].question.correctOption == e.value)
      .length;

  void _pick(int i, String key) {
    if (_answers.containsKey(i)) return;
    setState(() => _answers[i] = key);
    // Time is only meaningful one question at a time.
    final ms = DateTime.now().difference(_shownAt).inMilliseconds;
    _recorder.record(
      _questions[i].question.id,
      key,
      timeSpentMs: _single && i == _cur && ms < 10 * 60 * 1000 ? ms : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final total = _questions.length;
    final right = _right;
    final wrong = _answers.length - right;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              decoration: const BoxDecoration(
                color: AppColors.paper,
                border: Border(bottom: BorderSide(color: AppColors.line)),
              ),
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        tooltip: 'বন্ধ করো',
                        onPressed: () => context.pop(),
                        icon: const Icon(LucideIcons.x, size: 22),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: dsText(
                                16,
                                weight: FontWeight.w700,
                                height: 1.2,
                              ),
                            ),
                            Text(
                              widget.subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: dsText(12, color: AppColors.muted),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'প্রশ্ন শোনো',
                        onPressed: () => _tts.read(
                          _questions[_single ? _cur : 0].question,
                          const QuestionReadOptions(
                            readAllOptions: true,
                            readCorrectAnswer: false,
                            readExplanation: false,
                          ),
                        ),
                        icon: const Icon(LucideIcons.volume2, size: 22),
                      ),
                      // Always reachable, so a long practice can stop
                      // anywhere without scrolling to the end.
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: DsSmallButton(
                          label: 'শেষ করো',
                          filled: true,
                          onPressed: _finish,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: DsSegmented<bool>(
                      value: _single,
                      onChanged: (v) => setState(() {
                        _single = v;
                        _shownAt = DateTime.now();
                      }),
                      items: const [
                        (true, 'একটা একটা করে', LucideIcons.square),
                        (false, 'তালিকা', LucideIcons.list),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      children: [
                        Text(
                          'ঠিক ${bn(right)}',
                          style: dsText(
                            12,
                            weight: FontWeight.w600,
                            color: AppColors.success,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Text(
                          'ভুল ${bn(wrong)}',
                          style: dsText(
                            12,
                            weight: FontWeight.w600,
                            color: AppColors.danger,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Text(
                          'বাকি ${bn(total - _answers.length)}',
                          style: dsText(12, color: AppColors.muted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(child: _single ? _singleView() : _listView()),
            if (_single) _footer(),
          ],
        ),
      ),
    );
  }

  Widget _footer() {
    final bar = BoxDecoration(
      color: AppColors.paper,
      border: const Border(top: BorderSide(color: AppColors.line)),
    );
    final answered = _answers.containsKey(_cur);
    final last = _cur == _questions.length - 1;
    return Container(
      decoration: bar,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      child: Row(
        children: [
          Expanded(
            child: DsButton.secondary(
              label: 'আগের',
              height: 48,
              fontSize: 15,
              onPressed: _cur == 0 ? null : () => _go(_cur - 1),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: DsButton(
              label: last
                  ? 'শেষ করো'
                  : answered
                  ? 'পরের প্রশ্ন'
                  : 'বাদ দাও',
              height: 48,
              onPressed: last ? _finish : () => _go(_cur + 1),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _finish() async {
    if (_answers.isEmpty) {
      context.pop();
      return;
    }
    final right = _right;
    final wrong = _answers.length - right;
    final skipped = _questions.length - _answers.length;
    var saved = await _recorder.flush();
    if (!mounted) return;
    while (true) {
      final action = await showDialog<String>(
        context: context,
        builder: (ctx) => _FinishDialog(
          right: right,
          wrong: wrong,
          skipped: skipped,
          saved: saved,
          // Retrying mistakes already returns to the mistakes list.
          offerMistakes: widget.target.source != 'mistakes',
        ),
      );
      if (!mounted) return;
      if (action == 'retry') {
        saved = await _recorder.flush();
        if (!mounted) return;
        continue;
      }
      _refresh(_container);
      if (action == 'mistakes') {
        context.pushReplacement('/practice/mistakes?mode=practice');
      } else {
        context.pop();
      }
      return;
    }
  }

  OptionState _state(int i, String key) {
    final picked = _answers[i];
    if (picked == null) return OptionState.idle;
    if (key == _questions[i].question.correctOption) return OptionState.correct;
    if (key == picked) return OptionState.wrong;
    return OptionState.idle;
  }

  String? _note(int i, String key) {
    final s = _state(i, key);
    if (s == OptionState.correct) return 'সঠিক';
    if (s == OptionState.wrong) return 'তোমার উত্তর';
    return null;
  }

  Widget _singleView() {
    final i = _cur;
    final pq = _questions[i];
    final q = pq.question;
    final picked = _answers[i];
    final right = picked == q.correctOption;
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      children: [
        Text(
          'প্রশ্ন ${bn(i + 1)} / ${bn(_questions.length)}',
          style: dsText(13, weight: FontWeight.w600, color: AppColors.muted),
        ),
        const SizedBox(height: 14),
        Text(
          q.questionText,
          style: dsText(19, weight: FontWeight.w600, height: 1.5),
        ),
        const SizedBox(height: 14),
        for (final o in q.options) ...[
          OptionTile(
            badge: o.key,
            label: o.value,
            state: _state(i, o.key),
            note: _note(i, o.key),
            onTap: () => _pick(i, o.key),
          ),
          const SizedBox(height: 8),
        ],
        if (picked != null) ...[
          const SizedBox(height: 6),
          DsCard(
            radius: 14,
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  right ? 'ঠিক হয়েছে' : 'ভুল হয়েছে, ভুলের তালিকায় রাখা হলো',
                  style: dsText(
                    14,
                    weight: FontWeight.w700,
                    color: right ? AppColors.success : AppColors.danger,
                  ),
                ),
                AnswerCaveat(question: q),
                if (q.explanation != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    q.explanation!,
                    style: dsText(14, height: 1.55, color: AppColors.ink2),
                  ),
                ],
                if (pq.appearedIn.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        'এই প্রশ্ন এসেছে:',
                        style: dsText(12, color: AppColors.muted),
                      ),
                      for (final e in pq.appearedIn)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.sunken,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            bnOrdinal(e),
                            style: dsText(12, weight: FontWeight.w600),
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _listView() {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      // The finish button sits after the last question, inside the scroll.
      itemCount: _questions.length + 1,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        if (i == _questions.length) {
          return Padding(
            padding: const EdgeInsets.only(top: 6, bottom: 8),
            child: SizedBox(
              width: double.infinity,
              child: DsButton(
                label: 'শেষ করো ও ফল দেখো',
                height: 50,
                onPressed: _finish,
              ),
            ),
          );
        }
        final q = _questions[i].question;
        final answered = _answers.containsKey(i);
        return DsCard(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${bn(i + 1)}.',
                    style: dsText(
                      13,
                      weight: FontWeight.w700,
                      color: AppColors.muted,
                      height: 1.9,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      q.questionText,
                      style: dsText(16, weight: FontWeight.w600, height: 1.5),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              for (final o in q.options) ...[
                OptionTile(
                  compact: true,
                  badge: o.key,
                  label: o.value,
                  state: _state(i, o.key),
                  note: _note(i, o.key),
                  onTap: () => _pick(i, o.key),
                ),
                const SizedBox(height: 6),
              ],
              if (answered) AnswerCaveat(question: q),
              if (answered && q.explanation != null) ...[
                const SizedBox(height: 4),
                Text(
                  q.explanation!,
                  style: dsText(13, height: 1.5, color: AppColors.ink2),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _FinishDialog extends StatelessWidget {
  final int right;
  final int wrong;
  final int skipped;
  final bool saved;
  final bool offerMistakes;

  const _FinishDialog({
    required this.right,
    required this.wrong,
    required this.skipped,
    required this.saved,
    required this.offerMistakes,
  });

  @override
  Widget build(BuildContext context) {
    final answered = right + wrong;
    final note = !saved
        ? 'সব উত্তর সেভ হয়নি। ইন্টারনেট দেখে আবার চেষ্টা করো, নইলে এগুলো তোমার হিসাবে আসবে না।'
        : wrong > 0
        ? 'ভুলগুলো "আমার ভুল"-এ রাখা হয়েছে, রিভিশনেও আসবে। পরে ঠিক করলে তালিকা থেকে সরে যাবে।'
        : 'সব ঠিক! অনুশীলনের হিসাবে যোগ হয়েছে।';
    return AlertDialog(
      backgroundColor: AppColors.paper,
      title: Text('অনুশীলন শেষ', style: dsText(18, weight: FontWeight.w700)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: StatBox(
                  label: 'ঠিক',
                  value: bn(right),
                  valueColor: AppColors.success,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: StatBox(
                  label: 'ভুল',
                  value: bn(wrong),
                  valueColor: AppColors.danger,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: StatBox(label: 'বাদ', value: bn(skipped)),
              ),
            ],
          ),
          if (answered > 0) ...[
            const SizedBox(height: 10),
            Text(
              'নির্ভুলতা ${bn((right * 100 / answered).round())}%',
              style: dsText(14, weight: FontWeight.w600),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            note,
            style: dsText(
              13,
              height: 1.5,
              color: saved ? AppColors.ink2 : AppColors.danger,
            ),
          ),
        ],
      ),
      actions: [
        if (!saved)
          TextButton(
            onPressed: () => Navigator.pop(context, 'retry'),
            child: const Text('আবার চেষ্টা'),
          )
        else if (wrong > 0 && offerMistakes)
          TextButton(
            onPressed: () => Navigator.pop(context, 'mistakes'),
            child: const Text('ভুলগুলো দেখো'),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context, 'done'),
          child: Text(saved ? 'ঠিক আছে' : 'বাদ দাও'),
        ),
      ],
    );
  }
}
