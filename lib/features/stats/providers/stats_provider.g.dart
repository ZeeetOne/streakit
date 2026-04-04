// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stats_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(StatsNotifier)
final statsProvider = StatsNotifierProvider._();

final class StatsNotifierProvider
    extends $StreamNotifierProvider<StatsNotifier, StatsState> {
  StatsNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'statsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$statsNotifierHash();

  @$internal
  @override
  StatsNotifier create() => StatsNotifier();
}

String _$statsNotifierHash() => r'0e14379196b03f1e99e2ab4a03fd037ce3131dfa';

abstract class _$StatsNotifier extends $StreamNotifier<StatsState> {
  Stream<StatsState> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<StatsState>, StatsState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<StatsState>, StatsState>,
              AsyncValue<StatsState>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
