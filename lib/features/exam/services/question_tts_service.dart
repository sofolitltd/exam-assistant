import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../data/models/question_model.dart';

class QuestionReadOptions {
  final bool readQuestion;
  final bool readAllOptions;
  final bool readCorrectAnswer;
  final bool readExplanation;

  /// Voice speed relative to normal: 1.0 is normal, 0.5 half, 1.5 faster.
  final double speed;

  const QuestionReadOptions({
    this.readQuestion = true,
    this.readAllOptions = false,
    this.readCorrectAnswer = true,
    this.readExplanation = true,
    this.speed = 1.0,
  });

  QuestionReadOptions copyWith({
    bool? readQuestion,
    bool? readAllOptions,
    bool? readCorrectAnswer,
    bool? readExplanation,
    double? speed,
  }) {
    return QuestionReadOptions(
      readQuestion: readQuestion ?? this.readQuestion,
      readAllOptions: readAllOptions ?? this.readAllOptions,
      readCorrectAnswer: readCorrectAnswer ?? this.readCorrectAnswer,
      readExplanation: readExplanation ?? this.readExplanation,
      speed: speed ?? this.speed,
    );
  }
}

/// The engine rate that sounds "normal" for Bangla; [QuestionReadOptions.speed]
/// scales it. flutter_tts tops out at 1.0 on iOS.
const _baseSpeechRate = 0.42;

/// Candidate Bangla locale codes, most specific first. Android/iOS TTS
/// engines are inconsistent about which of these they report as available.
const _banglaLocaleCandidates = ['bn-BD', 'bn-IN', 'bn'];

class QuestionTtsService {
  final FlutterTts _tts = FlutterTts();
  final ValueNotifier<String?> activeQuestionId = ValueNotifier<String?>(null);
  bool _initialized = false;
  Future<void>? _initializing;
  int _playToken = 0;

  QuestionTtsService() {
    // Kick off voice selection as soon as the service exists instead of on
    // the first tap. On web, speechSynthesis.speak() must run inside the
    // click's own call stack or the browser silently ignores it; doing the
    // async setup (isLanguageAvailable/getVoices lookups) ahead of time
    // keeps the actual speak() call right next to the user gesture.
    unawaited(_ensureInitialized());
  }

  bool get isSpeaking => activeQuestionId.value != null;

  Future<void> _ensureInitialized() {
    if (_initialized) return Future.value();
    return _initializing ??= _doInitialize();
  }

  Future<void> _doInitialize() async {
    _initialized = true;
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
      // Keep speaking with the screen locked / app in the background, for
      // listen-while-commuting revision. Needs UIBackgroundModes=audio.
      await _tts.setSharedInstance(true);
      await _tts.setIosAudioCategory(IosTextToSpeechAudioCategory.playback, [
        IosTextToSpeechAudioCategoryOptions.duckOthers,
      ], IosTextToSpeechAudioMode.spokenAudio);
    }
    await _selectBanglaVoice();
    await _tts.awaitSpeakCompletion(true);
    await _tts.setPitch(1.0);
  }

  /// Picks a Bangla voice so Bangla question/option text isn't read with an
  /// English accent. `setLanguage` alone silently no-ops on many devices
  /// when the exact locale isn't installed, so this also checks
  /// `isLanguageAvailable` and falls back to scanning installed voices for
  /// anything with a `bn*` locale before giving up to the device default.
  Future<void> _selectBanglaVoice() async {
    for (final locale in _banglaLocaleCandidates) {
      try {
        final available = await _tts.isLanguageAvailable(locale);
        if (available == true || available == 1) {
          await _tts.setLanguage(locale);
          return;
        }
      } catch (e) {
        debugPrint(
          'QuestionTtsService: isLanguageAvailable($locale) failed: $e',
        );
      }
    }

    try {
      final voices = await _tts.getVoices;
      if (voices is List) {
        for (final voice in voices) {
          if (voice is! Map) continue;
          final locale = (voice['locale'] ?? '').toString().toLowerCase();
          if (!locale.startsWith('bn')) continue;
          final name = voice['name']?.toString();
          if (name == null) continue;
          await _tts.setVoice({'name': name, 'locale': voice['locale']});
          return;
        }
      }
      // No Bangla voice found; falls back to the engine's default voice.
    } catch (e) {
      debugPrint('QuestionTtsService: getVoices failed: $e');
    }
  }

  List<String> _buildSegments(
    QuestionModel question,
    QuestionReadOptions options,
  ) {
    final correctKeys = question.correctOptionKeys.toSet();
    final segments = <String>[];

    if (options.readQuestion && question.questionText.trim().isNotEmpty) {
      segments.add(question.questionText);
    }

    if (options.readAllOptions) {
      for (final option in question.options) {
        if (option.value.trim().isEmpty) continue;
        segments.add(option.value);
      }
    }

    if (options.readCorrectAnswer) {
      final correctOptions = question.options.where(
        (option) => correctKeys.contains(option.key),
      );
      for (final option in correctOptions) {
        if (option.value.trim().isEmpty) continue;
        // Spoken as "উত্তর <answer>" so it's clear this is the answer, not
        // another option — e.g. "উত্তর ঢাকা".
        segments.add('উত্তর ${option.value}');
      }
    }

    if (options.readExplanation &&
        (question.explanation?.trim().isNotEmpty ?? false)) {
      // Spoken as "ব্যাখ্যা <explanation>" for the same reason.
      segments.add('ব্যাখ্যা ${question.explanation!}');
    }

    return segments;
  }

  /// Reads a single question, then stops.
  Future<void> read(
    QuestionModel question,
    QuestionReadOptions options, {
    void Function()? onDone,
  }) async {
    await readSequence([question], options, onDone: onDone);
  }

  /// Reads every question in [questions] in order from [startIndex] to the
  /// last, with no prompt in between. Call [stop] to cancel; calling this
  /// again while already reading replaces the current playback.
  Future<void> readSequence(
    List<QuestionModel> questions,
    QuestionReadOptions options, {
    int startIndex = 0,
    void Function(int index)? onQuestionStart,
    void Function()? onDone,
  }) async {
    await stop();
    await _ensureInitialized();
    await _tts.setSpeechRate((_baseSpeechRate * options.speed).clamp(0.1, 1.0));
    final token = ++_playToken;

    for (var i = startIndex; i < questions.length; i++) {
      if (_playToken != token) return;
      final question = questions[i];
      activeQuestionId.value = question.id;
      onQuestionStart?.call(i);
      for (final segment in _buildSegments(question, options)) {
        if (_playToken != token) return;
        try {
          await _tts.speak(segment);
        } catch (e) {
          debugPrint('QuestionTtsService: speak() failed: $e');
        }
      }
    }

    if (_playToken == token) {
      activeQuestionId.value = null;
      onDone?.call();
    }
  }

  Future<void> stop() async {
    _playToken++;
    if (activeQuestionId.value == null) return;
    activeQuestionId.value = null;
    await _tts.stop();
  }

  void dispose() {
    activeQuestionId.dispose();
    _tts.stop();
  }
}

final questionTtsServiceProvider = Provider<QuestionTtsService>((ref) {
  final service = QuestionTtsService();
  ref.onDispose(service.dispose);
  return service;
});
