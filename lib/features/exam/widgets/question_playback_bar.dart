import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../data/models/question_model.dart';
import '../services/question_tts_service.dart';

/// What to read is a one-time choice, not something to confirm on every
/// tap — the gear icon in [QuestionPlaybackBar] edits this, and it carries
/// over to every exam/subject/topic question list for the rest of the
/// session.
class QuestionReadOptionsNotifier extends Notifier<QuestionReadOptions> {
  @override
  QuestionReadOptions build() => const QuestionReadOptions();

  void update(QuestionReadOptions options) => state = options;
}

final questionReadOptionsProvider =
    NotifierProvider<QuestionReadOptionsNotifier, QuestionReadOptions>(
      QuestionReadOptionsNotifier.new,
    );

/// Opens the "what to read" dialog and saves the choice for the session.
Future<void> editReadOptions(BuildContext context, WidgetRef ref) async {
  final current = ref.read(questionReadOptionsProvider);
  final next = await showDialog<QuestionReadOptions>(
    context: context,
    builder: (context) => _ReadOptionsDialog(initial: current),
  );
  if (next != null) {
    ref.read(questionReadOptionsProvider.notifier).update(next);
  }
}

/// A single AppBar control pair: a settings gear (what to read, voice speed)
/// and a play/stop button that reads every question in [questions], in
/// order, start to finish, with no per-question prompt.
///
/// [onActiveIndexChanged] reports whichever of [questions] is being spoken
/// — whether by this bar or a card's own [QuestionSpeakButton] — or null
/// when nothing is, so the caller can highlight/scroll to it.
class QuestionPlaybackBar extends ConsumerStatefulWidget {
  final List<QuestionModel> questions;
  final void Function(int? index)? onActiveIndexChanged;

  const QuestionPlaybackBar({
    super.key,
    required this.questions,
    this.onActiveIndexChanged,
  });

  @override
  ConsumerState<QuestionPlaybackBar> createState() =>
      _QuestionPlaybackBarState();
}

class _QuestionPlaybackBarState extends ConsumerState<QuestionPlaybackBar> {
  late final QuestionTtsService _service;

  @override
  void initState() {
    super.initState();
    _service = ref.read(questionTtsServiceProvider);
    _service.activeQuestionId.addListener(_reportActive);
  }

  @override
  void dispose() {
    _service.activeQuestionId.removeListener(_reportActive);
    super.dispose();
  }

  void _reportActive() {
    final activeId = _service.activeQuestionId.value;
    final index = activeId == null
        ? -1
        : widget.questions.indexWhere((q) => q.id == activeId);
    widget.onActiveIndexChanged?.call(index < 0 ? null : index);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String?>(
      valueListenable: _service.activeQuestionId,
      builder: (context, activeId, _) {
        final isPlaying = activeId != null;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: 'শোনার সেটিংস',
              icon: const Icon(Icons.tune),
              onPressed: isPlaying ? null : () => editReadOptions(context, ref),
            ),
            IconButton(
              tooltip: isPlaying ? 'থামান' : 'সব প্রশ্ন শুনুন',
              icon: Icon(
                isPlaying ? Icons.stop_circle : Icons.volume_up_outlined,
                color: isPlaying ? AppTheme.errorColor : AppTheme.primaryColor,
              ),
              onPressed: widget.questions.isEmpty
                  ? null
                  : () => isPlaying
                        ? _service.stop()
                        : _service.readSequence(
                            widget.questions,
                            ref.read(questionReadOptionsProvider),
                          ),
            ),
          ],
        );
      },
    );
  }
}

/// Top-right button on a question card: reads just that question, using the
/// AppBar's settings (no dialog). Tapping it while that question is being
/// read stops playback.
class QuestionSpeakButton extends ConsumerWidget {
  final QuestionModel question;

  const QuestionSpeakButton({super.key, required this.question});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final service = ref.watch(questionTtsServiceProvider);
    return ValueListenableBuilder<String?>(
      valueListenable: service.activeQuestionId,
      builder: (context, activeId, _) {
        final isReadingThis = activeId == question.id;
        return IconButton(
          visualDensity: VisualDensity.compact,
          tooltip: isReadingThis ? 'থামাও' : 'এই প্রশ্নটা শোনো',
          icon: Icon(
            isReadingThis ? Icons.stop_circle : Icons.volume_up_outlined,
            size: 22,
            color: isReadingThis ? AppTheme.errorColor : AppTheme.primaryColor,
          ),
          onPressed: () => isReadingThis
              ? service.stop()
              : service.read(question, ref.read(questionReadOptionsProvider)),
        );
      },
    );
  }
}

class _ReadOptionsDialog extends StatefulWidget {
  final QuestionReadOptions initial;

  const _ReadOptionsDialog({required this.initial});

  @override
  State<_ReadOptionsDialog> createState() => _ReadOptionsDialogState();
}

class _ReadOptionsDialogState extends State<_ReadOptionsDialog> {
  late QuestionReadOptions _options;

  @override
  void initState() {
    super.initState();
    _options = widget.initial;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('কী কী পড়ে শোনাবে?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            title: const Text('প্রশ্ন'),
            value: _options.readQuestion,
            onChanged: (value) => setState(
              () => _options = _options.copyWith(readQuestion: value),
            ),
          ),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            title: const Text('সব অপশন (ক, খ, গ, ঘ)'),
            value: _options.readAllOptions,
            onChanged: (value) => setState(
              () => _options = _options.copyWith(readAllOptions: value),
            ),
          ),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            title: const Text('সঠিক উত্তর'),
            value: _options.readCorrectAnswer,
            onChanged: (value) => setState(
              () => _options = _options.copyWith(readCorrectAnswer: value),
            ),
          ),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            title: const Text('ব্যাখ্যা (Explanation)'),
            value: _options.readExplanation,
            onChanged: (value) => setState(
              () => _options = _options.copyWith(readExplanation: value),
            ),
          ),
          const Divider(height: 24),
          Row(
            children: [
              const Text('ভয়েস স্পিড'),
              const Spacer(),
              Text(
                '${_options.speed}x',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          Slider(
            value: _options.speed,
            min: 0.5,
            max: 1.5,
            divisions: 4,
            label: '${_options.speed}x',
            onChanged: (value) =>
                setState(() => _options = _options.copyWith(speed: value)),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('ধীর', style: Theme.of(context).textTheme.bodySmall),
              Text('স্বাভাবিক', style: Theme.of(context).textTheme.bodySmall),
              Text('দ্রুত', style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('বাতিল'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_options),
          child: const Text('ঠিক আছে'),
        ),
      ],
    );
  }
}
