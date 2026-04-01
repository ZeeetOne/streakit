// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(appDatabase)
final appDatabaseProvider = AppDatabaseProvider._();

final class AppDatabaseProvider
    extends $FunctionalProvider<AppDatabase, AppDatabase, AppDatabase>
    with $Provider<AppDatabase> {
  AppDatabaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appDatabaseProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appDatabaseHash();

  @$internal
  @override
  $ProviderElement<AppDatabase> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AppDatabase create(Ref ref) {
    return appDatabase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppDatabase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AppDatabase>(value),
    );
  }
}

String _$appDatabaseHash() => r'8c69eb46d45206533c176c88a926608e79ca927d';

@ProviderFor(habitsDao)
final habitsDaoProvider = HabitsDaoProvider._();

final class HabitsDaoProvider
    extends $FunctionalProvider<HabitsDao, HabitsDao, HabitsDao>
    with $Provider<HabitsDao> {
  HabitsDaoProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'habitsDaoProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$habitsDaoHash();

  @$internal
  @override
  $ProviderElement<HabitsDao> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  HabitsDao create(Ref ref) {
    return habitsDao(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(HabitsDao value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<HabitsDao>(value),
    );
  }
}

String _$habitsDaoHash() => r'6d116374bced51974decc6c6bc60b9d54cc735c9';
