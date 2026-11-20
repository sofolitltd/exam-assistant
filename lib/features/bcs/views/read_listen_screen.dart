import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/bangla_digits.dart';
import '../../../core/widgets/ds.dart';
import '../../exam/services/question_tts_service.dart';
import '../data/bcs_models.dart';
import '../data/bcs_api.dart';
import 'bcs_async.dart';
import 'bcs_format.dart';
import 'practice_screen.dart';

/// Mode ১: পড়ো ও শোনো. Questions with the right answer marked; the player
/// reads them aloud one after another.
class ReadListenScreen extends ConsumerWidget {
  final int number;
  final PaperSelection selection;

  const ReadListenScreen({
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
          return _ReadListenBody(
            number: number,
            selection: selection,
            questions: questions,
          );
        },
      ),
    );
  }
}

class _ReadListenBody extends ConsumerStatefulWidget {
  final int number;
  final PaperSelection selection;
  final List<PaperQuestion> questions;

  const _ReadListenBody({
    required this.number,
    required this.selection,
    required this.questions,
  });

  @override
  ConsumerState<_ReadListenBody> createState() => _ReadListenScreenState();
}

class _ReadListenScreenState extends ConsumerState<_ReadListenBody> {
  static const _speeds = [1.0, 1.25, 1.5, 0.75];

  late final List<PaperQuestion> _questions = widget.questions;
  late final QuestionTtsService _tts;
  late final List<GlobalKey> _keys = [
    for (var i = 0; i < _questions.length; i++) GlobalKey(),
  ];

  int _cur = 0;
  bool _playing = false;
  bool _showAns = true;
  bool _readAns = true;
  double _speed = 1;

  @override
  void initState() {
    super.initState();
    _tts = ref.read(questionTtsServiceProvider);
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  void _play([int? from]) {
    final start = from ?? _cur;
    setState(() {
      _cur = start;
      _playing = true;
    });
    _tts.readSequence(
      [for (final q in _questions) q.question],
      QuestionReadOptions(
        readAllOptions: false,
        readCorrectAnswer: _readAns,
        readExplanation: _readAns,
        speed: _speed,
      ),
      startIndex: start,
      onQuestionStart: (i) {
        if (!mounted) return;
        setState(() => _cur = i);
        final ctx = _keys[i].currentContext;
        if (ctx != null) {
          Scrollable.ensureVisible(
            ctx,
            duration: const Duration(milliseconds: 250),
            alignment: 0.1,
          );
        }
      },
      onDone: () {
        if (mounted) setState(() => _playing = false);
      },
    );
  }

  void _pause() {
    _tts.stop();
    setState(() => _playing = false);
  }

  void _jump(int i) {
    if (i < 0 || i >= _questions.length) return;
    if (_playing) {
      _play(i);
    } else {
      setState(() => _cur = i);
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = _questions.length;
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: Column(
          children: [
            DsHeader(
              close: true,
              titleSize: 16,
              title: '${bnOrdinal(widget.number)} · পড়ো ও শোনো',
              subtitle: selectionSubtitle(widget.selection, total),
              onBack: () => context.pop(),
              trailing: DsSmallButton(
                label: _showAns ? 'উত্তর লুকাও' : 'উত্তর দেখাও',
                onPressed: () => setState(() => _showAns = !_showAns),
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                itemCount: total,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (_, i) => _card(i),
              ),
            ),
            _footer(total),
          ],
        ),
      ),
    );
  }

  Widget _card(int i) {
    final q = _questions[i].question;
    final active = i == _cur;
    return KeyedSubtree(
      key: _keys[i],
      child: DsCard(
        onTap: () => _jump(i),
        borderColor: active ? AppColors.brand : AppColors.line,
        borderWidth: active ? 1.5 : 1,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'প্রশ্ন ${bn(i + 1)}',
                    style: dsText(
                      12,
                      weight: FontWeight.w600,
                      color: AppColors.muted,
                    ),
                  ),
                ),
                if (active)
                  Text(
                    _playing ? 'শোনানো হচ্ছে' : 'থামানো',
                    style: dsText(
                      12,
                      weight: FontWeight.w600,
                      color: AppColors.liveInk,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              q.questionText,
              style: dsText(16, weight: FontWeight.w600, height: 1.5),
            ),
            const SizedBox(height: 10),
            for (final o in q.options) ...[
              _option(o.key, o.value, _showAns && o.key == q.correctOption),
              const SizedBox(height: 6),
            ],
            if (_showAns && q.explanation != null) ...[
              const SizedBox(height: 4),
              Text(
                q.explanation!,
                style: dsText(13, height: 1.5, color: AppColors.ink2),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _option(String key, String label, bool right) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: right ? AppColors.successSoft : AppColors.canvas,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: right ? AppColors.success : Colors.transparent,
        ),
      ),
      child: Text(
        '$key. $label',
        style: dsText(
          15,
          height: 1.45,
          weight: right ? FontWeight.w600 : FontWeight.w400,
          color: right ? AppColors.successInk : AppColors.ink,
        ),
      ),
    );
  }

  Widget _footer(int total) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.paper,
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(
                '${bn(_cur + 1)} / ${bn(total)}',
                style: dsText(12, color: AppColors.muted),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DsBar(
                  value: (_cur + 1) / total,
                  track: AppColors.lineSoft,
                ),
              ),
              const SizedBox(width: 6),
              SizedBox(
                height: 32,
                child: Checkbox(
                  value: _readAns,
                  activeColor: AppColors.brand,
                  visualDensity: VisualDensity.compact,
                  onChanged: (v) {
                    setState(() => _readAns = v ?? true);
                    if (_playing) _play();
                  },
                ),
              ),
              Text('উত্তরও শোনাও', style: dsText(12, color: AppColors.ink2)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              SizedBox(
                width: 56,
                child: DsButton.secondary(
                  label:
                      '${bn(_speed == _speed.roundToDouble() ? _speed.toStringAsFixed(0) : _speed.toString())}x',
                  height: 44,
                  onPressed: () {
                    final i = _speeds.indexOf(_speed);
                    setState(() => _speed = _speeds[(i + 1) % _speeds.length]);
                    if (_playing) _play();
                  },
                ),
              ),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _roundButton(
                      LucideIcons.skipBack,
                      'আগের প্রশ্ন',
                      () => _jump(_cur - 1),
                    ),
                    const SizedBox(width: 14),
                    Semantics(
                      button: true,
                      label: _playing ? 'থামাও' : 'চালাও',
                      child: Material(
                        color: AppColors.brand,
                        shape: const CircleBorder(),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: _playing ? _pause : _play,
                          child: SizedBox(
                            width: 60,
                            height: 60,
                            child: Icon(
                              _playing ? LucideIcons.pause : LucideIcons.play,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    _roundButton(
                      LucideIcons.skipForward,
                      'পরের প্রশ্ন',
                      () => _jump(_cur + 1),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 56),
            ],
          ),
        ],
      ),
    );
  }

  Widget _roundButton(IconData icon, String label, VoidCallback onTap) {
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: AppColors.sunken,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(width: 44, height: 44, child: Icon(icon, size: 20)),
        ),
      ),
    );
  }
}
