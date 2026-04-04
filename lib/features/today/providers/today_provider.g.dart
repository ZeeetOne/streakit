// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'today_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(TodayNotifier)
final todayProvider = TodayNotifierProvider._();

final class TodayNotifierProvider
    extends $StreamNotifierProvider<TodayNotifier, TodayState> {
  TodayNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'todayProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$todayNotifierHash();

  @$internal
  @override
  TodayNotifier create() => TodayNotifier();
}

String _$todayNotifierHash() => r'1aa3a96695f7f07ab9e8d70e239f2704a9df3726';

abstract class _$TodayNotifier extends $StreamNotifier<TodayState> {
  Stream<TodayState> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<TodayState>, TodayState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<TodayState>, TodayState>,
              AsyncValue<TodayState>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
