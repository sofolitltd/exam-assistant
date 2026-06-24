// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'timer_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(TimerController)
final timerControllerProvider = TimerControllerProvider._();

final class TimerControllerProvider
    extends $NotifierProvider<TimerController, TimerState> {
  TimerControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'timerControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$timerControllerHash();

  @$internal
  @override
  TimerController create() => TimerController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TimerState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TimerState>(value),
    );
  }
}

String _$timerControllerHash() => r'e1749a7b46d44d7839825f897186c10689073cf3';

abstract class _$TimerController extends $Notifier<TimerState> {
  TimerState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<TimerState, TimerState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<TimerState, TimerState>,
              TimerState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
