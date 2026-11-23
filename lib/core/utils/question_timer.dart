/// Measures how long the learner looks at each question before answering.
///
/// Call [show] when a question becomes the one on screen (and `show(null)`
/// when none is, or once it is answered), then read [finish] when submitting.
/// Only time spent while a question is shown counts, so skipping around
/// doesn't smear time across questions.
class QuestionTimer {
  final Map<int, int> _ms = {};
  final Stopwatch _watch = Stopwatch();
  int? _active;

  void show(int? index) {
    _flush();
    _active = index;
    if (index != null) {
      _watch
        ..reset()
        ..start();
    }
  }

  void _flush() {
    final active = _active;
    if (active != null) {
      _watch.stop();
      _ms[active] = (_ms[active] ?? 0) + _watch.elapsedMilliseconds;
    }
    _active = null;
  }

  /// Milliseconds per question index, for questions that were shown.
  Map<int, int> finish() {
    _flush();
    return Map.unmodifiable(_ms);
  }
}
