import '../../../core/utils/question_timer.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/bangla_digits.dart';
import '../../../core/widgets/ds.dart';
import '../../auth/controllers/auth_controller.dart';
import '../data/bcs_api.dart';
import '../data/bcs_models.dart';
import '../data/bcs_sample_data.dart';
import 'bcs_async.dart';
import 'bcs_format.dart';

/// Mode ৩: প্রতিযোগিতা. Full paper, real time limit. An answer locks once
/// marked; skipping leaves it blank. Only the first attempt is ranked.
class CompetitionScreen extends ConsumerWidget {
  final int number;

  const CompetitionScreen({required this.number, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final edition = ref.watch(bcsEditionProvider(number));
    final paper = ref.watch(bcsPaperProvider(number));
    return BcsAsync(
      title: bnOrdinal(number),
      value: edition,
      onRetry: () => ref.invalidate(bcsPaperExamsProvider),
      builder: (edition) => BcsAsync(
        title: bnOrdinal(number),
        value: paper,
        onRetry: () => ref.invalidate(bcsPaperProvider(number)),
        builder: (paper) =>
            _CompetitionBody(number: number, edition: edition, paper: paper),
      ),
    );
  }
}

class _CompetitionBody extends ConsumerStatefulWidget {
  final int number;
  final BcsEdition edition;
  final BcsPaper paper;

  const _CompetitionBody({
    required this.number,
    required this.edition,
    required this.paper,
  });

  @override
  ConsumerState<_CompetitionBody> createState() => _CompetitionScreenState();
}

class _CompetitionScreenState extends ConsumerState<_CompetitionBody> {
  late final BcsRepository _repo = ref.read(bcsRepositoryProvider);
  late final BcsEdition _edition = widget.edition;
  late final bool _live = _edition.status == EditionStatus.running;
  late final List<PaperQuestion> _questions = widget.paper.questions;
  late final double _negative = _live
      ? _repo.todaySlot().negative
      : widget.paper.negativeMarks;
  late int _secs = _live
      ? _repo.todaySlot().minutes * 60
      : widget.paper.durationSeconds;
  late final bool _firstAttempt = _edition.firstScore == null;

  final Map<int, String> _answers = {};
  Timer? _timer;
  final _qTimer = QuestionTimer();
  bool _single = false;
  int _cur = 0;
  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_secs <= 1) {
        _timer?.cancel();
        setState(() => _secs = 0);
        _submit(auto: true);
        return;
      }
      setState(() => _secs--);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _pick(int i, String key) {
    if (_answers.containsKey(i)) return;
    setState(() => _answers[i] = key);
    // The answer is locked; stop the clock for this question.
    if (_single && i == _cur) _qTimer.show(null);
  }

  /// Moves to question [i] and starts timing it if it is still open. Time is
  /// only measured in one-at-a-time mode, where one question is on screen.
  void _go(int i) {
    setState(() => _cur = i);
    _qTimer.show(_single && !_answers.containsKey(i) ? i : null);
  }

  Future<bool> _confirm(String title, String body, String yes) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title, style: dsText(18, weight: FontWeight.w700)),
        content: Text(body, style: dsText(14, height: 1.6)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('না'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(yes),
          ),
        ],
      ),
    );
    return ok ?? false;
  }

  Future<void> _submit({bool auto = false}) async {
    if (_submitted) return;
    final blank = _questions.length - _answers.length;
    if (!auto) {
      final ok = await _confirm(
        'জমা দেবে?',
        blank > 0
            ? '${bn(blank)}টি প্রশ্ন ফাঁকা আছে। জমা দিলে আর বদলানো যাবে না।'
            : 'জমা দিলে আর বদলানো যাবে না।',
        'জমা দাও',
      );
      if (!ok) return;
    }
    _submitted = true;
    _timer?.cancel();
    final times = _qTimer.finish();

    var right = 0;
    _answers.forEach((i, key) {
      if (_questions[i].question.correctOption == key) right++;
    });
    var wrong = _answers.length - right;
    var score = right - wrong * _negative;
    var saveFailed = false;

    // A real paper is graded and stored by the API, so the first attempt
    // reaches the merit list and wrong answers show up in "আমার ভুল".
    final examId = widget.paper.examId;
    if (examId != null) {
      try {
        final result = await ref
            .read(accountApiServiceProvider)
            .submitExamResult(
              examId: examId,
              answers: {
                for (final e in _answers.entries)
                  _questions[e.key].question.id: e.value,
              },
              timeSpentMs: {
                for (final e in times.entries)
                  if (_answers.containsKey(e.key) && e.value > 0)
                    _questions[e.key].question.id: e.value,
              },
            );
        score = (result['score'] as num? ?? score).toDouble();
        right = (result['correctCount'] as num? ?? right).toInt();
        wrong = (result['wrongCount'] as num? ?? wrong).toInt();
        ref.invalidate(bcsMyResultsProvider);
        ref.invalidate(bcsMistakeIdsProvider(examId));
      } catch (_) {
        saveFailed = true;
      }
    }

    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(
          auto ? 'সময় শেষ' : 'জমা হয়েছে',
          style: dsText(18, weight: FontWeight.w700),
        ),
        content: Text(
          'নম্বর ${bnScore(score)} / ${bn(_questions.length)}\n'
          'ঠিক ${bn(right)} · ভুল ${bn(wrong)} · ফাঁকা ${bn(blank)}\n'
          '${saveFailed
              ? 'ফল সার্ভারে জমা হয়নি। ইন্টারনেট দেখে আবার দিও।'
              : _firstAttempt
              ? 'এটা প্রথম চেষ্টা, তাই মেধাতালিকায় যাবে।'
              : 'পরের চেষ্টা, শুধু তোমার নম্বর দেখাবে।'}',
          style: dsText(14, height: 1.6),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('মেধাতালিকা দেখো'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (examId != null) {
      context.pushReplacement(
        '/exam/${Uri.encodeComponent(examId)}/leaderboard'
        '?title=${Uri.encodeComponent(editionName(widget.number))}',
      );
    } else {
      context.pushReplacement('/bcs/${widget.number}/merit');
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = _questions.length;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final leave = await _confirm(
          'পরীক্ষা থেকে বের হবে?',
          'এখন বের হলে এই চেষ্টা জমা হবে না।',
          'বের হও',
        );
        if (leave && context.mounted) context.pop();
      },
      child: Scaffold(
        backgroundColor: AppColors.canvas,
        body: SafeArea(
          child: Column(
            children: [
              _header(total),
              Expanded(child: _single ? _singleView() : _listView()),
              if (_single) _footer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(int total) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.paper,
        border: Border(bottom: BorderSide(color: AppColors.line)),
      ),
      padding: const EdgeInsets.fromLTRB(8, 8, 12, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                tooltip: 'পরীক্ষা থেকে বের হও',
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(LucideIcons.x, size: 22),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${bnOrdinal(widget.number)} · ${_live ? 'Live' : 'প্রতিযোগিতা'}',
                      style: dsText(15, weight: FontWeight.w700, height: 1.2),
                    ),
                    Text(
                      _firstAttempt
                          ? 'প্রথম চেষ্টা · মেধাতালিকায় যাবে'
                          : 'পরের চেষ্টা · শুধু নিজের নম্বর',
                      style: dsText(12, color: AppColors.muted),
                    ),
                  ],
                ),
              ),
              Semantics(
                label: 'বাকি সময়',
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Text(
                    bnClock(_secs),
                    style:
                        dsText(
                          20,
                          weight: FontWeight.w700,
                          color: _secs < 600 ? AppColors.danger : AppColors.ink,
                        ).copyWith(
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                  ),
                ),
              ),
              DsSmallButton(label: 'জমা দাও', filled: true, onPressed: _submit),
            ],
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: DsSegmented<bool>(
              value: _single,
              onChanged: (v) {
                setState(() => _single = v);
                _qTimer.show(v && !_answers.containsKey(_cur) ? _cur : null);
              },
              items: const [
                (true, 'একটা একটা করে', LucideIcons.square),
                (false, 'তালিকা', LucideIcons.list),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Wrap(
              spacing: 14,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _legend(
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: AppColors.brand,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  'দিয়েছি ${bn(_answers.length)}',
                ),
                _legend(
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.live, width: 1.5),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  'ফাঁকা ${bn(total - _answers.length)}',
                ),
                Text(
                  'মোট ${bn(total)} · ভুলে ${bnScore(_negative)} কাটা',
                  style: dsText(12, color: AppColors.muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _legend(Widget swatch, String text) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      swatch,
      const SizedBox(width: 5),
      Text(text, style: dsText(12)),
    ],
  );

  OptionState _state(int i, String key) {
    final picked = _answers[i];
    if (picked == null) return OptionState.idle;
    return picked == key ? OptionState.picked : OptionState.dimmed;
  }

  Widget _lockNote(double size) => Row(
    children: [
      Icon(LucideIcons.lock, size: size, color: AppColors.ink2),
      const SizedBox(width: 6),
      Text(
        size > 14
            ? 'উত্তর lock হয়েছে, আর বদলানো যাবে না'
            : 'উত্তর lock হয়েছে',
        style: dsText(size > 14 ? 13 : 12, color: AppColors.ink2),
      ),
    ],
  );

  Widget _listView() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      children: [
        for (var i = 0; i < _questions.length; i++) ...[
          _card(i),
          const SizedBox(height: 10),
        ],
        Text(
          'উত্তর না দিলে প্রশ্নটা ফাঁকা থাকবে, নম্বর কাটবে না',
          textAlign: TextAlign.center,
          style: dsText(12, color: AppColors.muted),
        ),
      ],
    );
  }

  Widget _card(int i) {
    final q = _questions[i].question;
    final locked = _answers.containsKey(i);
    return DsCard(
      borderColor: locked ? AppColors.brandLine : AppColors.line,
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
              onTap: locked ? null : () => _pick(i, o.key),
            ),
            const SizedBox(height: 6),
          ],
          if (locked) ...[const SizedBox(height: 4), _lockNote(14)],
        ],
      ),
    );
  }

  Widget _singleView() {
    final q = _questions[_cur].question;
    final locked = _answers.containsKey(_cur);
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      children: [
        Text(
          'প্রশ্ন ${bn(_cur + 1)} / ${bn(_questions.length)}',
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
            state: _state(_cur, o.key),
            onTap: locked ? null : () => _pick(_cur, o.key),
          ),
          const SizedBox(height: 8),
        ],
        if (locked) ...[const SizedBox(height: 6), _lockNote(16)],
      ],
    );
  }

  Widget _footer() {
    final locked = _answers.containsKey(_cur);
    final last = _cur == _questions.length - 1;
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.paper,
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
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
                  ? 'জমা দাও'
                  : locked
                  ? 'পরের প্রশ্ন'
                  : 'ফাঁকা রেখে পরের',
              height: 48,
              background: locked || last ? AppColors.brand : AppColors.ink2,
              onPressed: last ? _submit : () => _go(_cur + 1),
            ),
          ),
        ],
      ),
    );
  }
}
