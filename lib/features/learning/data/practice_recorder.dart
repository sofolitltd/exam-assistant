import 'package:flutter/foundation.dart';

import 'learning_api_service.dart';
import 'practice_models.dart';

/// Saves one practice sitting's answers as they are given.
///
/// Each answer is queued and sent straight away; a failed send stays queued
/// and goes out with the next answer or on [flush]. The server ignores a
/// question already saved in the session, so resending is safe.
class PracticeRecorder extends ChangeNotifier {
  PracticeRecorder(this._api, this.target);

  final LearningApiService _api;
  final PracticeTarget target;

  int? _sessionId;
  final List<Map<String, dynamic>> _pending = [];
  Future<bool>? _inFlight;
  bool _failed = false;
  int _saved = 0;

  /// The last send failed and answers are waiting.
  bool get failed => _failed && _pending.isNotEmpty;
  int get pending => _pending.length;
  int get saved => _saved;

  void record(String questionId, String selectedKey, {int? timeSpentMs}) {
    _pending.add({
      'questionId': questionId,
      'selectedKey': selectedKey,
      'timeSpentMs': ?timeSpentMs,
    });
    flush();
  }

  /// Sends everything queued. True when nothing is left unsent.
  Future<bool> flush() {
    if (_pending.isEmpty && _inFlight == null) return Future.value(true);
    return _inFlight ??= _drain().whenComplete(() => _inFlight = null);
  }

  Future<bool> _drain() async {
    while (_pending.isNotEmpty) {
      final batch = _pending.take(200).toList();
      try {
        final result = await _api.recordPracticeAnswers(
          sessionId: _sessionId,
          target: target,
          answers: batch,
        );
        _sessionId = result.sessionId;
        _pending.removeRange(0, batch.length);
        _saved += result.saved;
        _failed = false;
      } catch (_) {
        _failed = true;
        notifyListeners();
        return false;
      }
    }
    notifyListeners();
    return true;
  }
}
