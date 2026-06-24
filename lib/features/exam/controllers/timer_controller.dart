import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'timer_controller.g.dart';

class TimerState {
  final int remainingSeconds;
  final bool isRunning;

  TimerState({required this.remainingSeconds, this.isRunning = false});

  TimerState copyWith({int? remainingSeconds, bool? isRunning}) {
    return TimerState(
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      isRunning: isRunning ?? this.isRunning,
    );
  }
}

@riverpod
class TimerController extends _$TimerController {
  Timer? _timer;

  @override
  TimerState build() {
    ref.onDispose(() => _timer?.cancel());
    return TimerState(remainingSeconds: 0);
  }

  void start(int seconds) {
    _timer?.cancel();
    state = TimerState(remainingSeconds: seconds, isRunning: true);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.remainingSeconds <= 0) {
        timer.cancel();
        state = state.copyWith(isRunning: false);
      } else {
        state = state.copyWith(remainingSeconds: state.remainingSeconds - 1);
      }
    });
  }

  void stop() {
    _timer?.cancel();
    state = state.copyWith(isRunning: false);
  }
}
