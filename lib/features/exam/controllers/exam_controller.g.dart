// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'exam_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ExamController)
final examControllerProvider = ExamControllerProvider._();

final class ExamControllerProvider
    extends $NotifierProvider<ExamController, QuizState> {
  ExamControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'examControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$examControllerHash();

  @$internal
  @override
  ExamController create() => ExamController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(QuizState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<QuizState>(value),
    );
  }
}

String _$examControllerHash() => r'b9ed2bff34102b926ace0aaaa89a99c66493b575';

abstract class _$ExamController extends $Notifier<QuizState> {
  QuizState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<QuizState, QuizState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<QuizState, QuizState>,
              QuizState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
