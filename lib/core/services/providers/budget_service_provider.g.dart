// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'budget_service_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

// Ref type definition
typedef BudgetServiceRef = Ref;

@ProviderFor(budgetService)
const budgetServiceProvider = BudgetServiceProvider._();

final class BudgetServiceProvider
    extends $FunctionalProvider<BudgetService, BudgetService, BudgetService>
    with $Provider<BudgetService> {
  const BudgetServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'budgetServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$budgetServiceHash();

  @$internal
  @override
  $ProviderElement<BudgetService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  BudgetService create(Ref ref) {
    return budgetService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BudgetService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BudgetService>(value),
    );
  }
}

String _$budgetServiceHash() => r'dfe4627a5e090e6adc3ae6d9e6b305a21b64ab7d';
