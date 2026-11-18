// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'routine_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(RoutineController)
final routineControllerProvider = RoutineControllerProvider._();

final class RoutineControllerProvider
    extends $NotifierProvider<RoutineController, AsyncValue<void>> {
  RoutineControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'routineControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$routineControllerHash();

  @$internal
  @override
  RoutineController create() => RoutineController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<void> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<void>>(value),
    );
  }
}

String _$routineControllerHash() => r'3a06b4c9aa7d14ad126f1a6635fd6863bd36ea98';

abstract class _$RoutineController extends $Notifier<AsyncValue<void>> {
  AsyncValue<void> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<void>, AsyncValue<void>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<void>, AsyncValue<void>>,
              AsyncValue<void>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
