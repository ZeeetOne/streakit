// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'streak_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(HabitStreak)
final habitStreakProvider = HabitStreakFamily._();

final class HabitStreakProvider
    extends $StreamNotifierProvider<HabitStreak, StreakData> {
  HabitStreakProvider._({
    required HabitStreakFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'habitStreakProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$habitStreakHash();

  @override
  String toString() {
    return r'habitStreakProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  HabitStreak create() => HabitStreak();

  @override
  bool operator ==(Object other) {
    return other is HabitStreakProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$habitStreakHash() => r'3beea618ac8ff720647a85fd15e92f3e8b4afa3d';

final class HabitStreakFamily extends $Family
    with
        $ClassFamilyOverride<
          HabitStreak,
          AsyncValue<StreakData>,
          StreakData,
          Stream<StreakData>,
          int
        > {
  HabitStreakFamily._()
    : super(
        retry: null,
        name: r'habitStreakProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  HabitStreakProvider call(int habitId) =>
      HabitStreakProvider._(argument: habitId, from: this);

  @override
  String toString() => r'habitStreakProvider';
}

abstract class _$HabitStreak extends $StreamNotifier<StreakData> {
  late final _$args = ref.$arg as int;
  int get habitId => _$args;

  Stream<StreakData> build(int habitId);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<StreakData>, StreakData>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<StreakData>, StreakData>,
              AsyncValue<StreakData>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}
