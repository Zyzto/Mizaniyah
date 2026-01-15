// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Centralized database provider for Riverpod 3.0
/// All DAO providers should depend on this provider

@ProviderFor(database)
const databaseProvider = DatabaseProvider._();

/// Centralized database provider for Riverpod 3.0
/// All DAO providers should depend on this provider

final class DatabaseProvider
    extends $FunctionalProvider<db.AppDatabase, db.AppDatabase, db.AppDatabase>
    with $Provider<db.AppDatabase> {
  /// Centralized database provider for Riverpod 3.0
  /// All DAO providers should depend on this provider
  const DatabaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'databaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$databaseHash();

  @$internal
  @override
  $ProviderElement<db.AppDatabase> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  db.AppDatabase create(Ref ref) {
    return database(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(db.AppDatabase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<db.AppDatabase>(value),
    );
  }
}

String _$databaseHash() => r'1aba9e7cd64cc6c91417b96dd6d80cd49f7f3013';
