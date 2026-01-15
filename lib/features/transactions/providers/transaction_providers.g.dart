// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transaction_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Search query state notifier - manages search query for transactions

@ProviderFor(TransactionSearchQuery)
const transactionSearchQueryProvider = TransactionSearchQueryProvider._();

/// Search query state notifier - manages search query for transactions
final class TransactionSearchQueryProvider
    extends $NotifierProvider<TransactionSearchQuery, String> {
  /// Search query state notifier - manages search query for transactions
  const TransactionSearchQueryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'transactionSearchQueryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$transactionSearchQueryHash();

  @$internal
  @override
  TransactionSearchQuery create() => TransactionSearchQuery();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String>(value),
    );
  }
}

String _$transactionSearchQueryHash() =>
    r'2dd2c2e37e165f36a07e3f9408e7539072fb3dc3';

/// Search query state notifier - manages search query for transactions

abstract class _$TransactionSearchQuery extends $Notifier<String> {
  String build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<String, String>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<String, String>,
              String,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
