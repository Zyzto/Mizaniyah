// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'error_handler_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Global error handler for Riverpod providers
/// Logs all provider errors to Siglat and provides user-friendly error messages

@ProviderFor(ErrorHandler)
const errorHandlerProvider = ErrorHandlerProvider._();

/// Global error handler for Riverpod providers
/// Logs all provider errors to Siglat and provides user-friendly error messages
final class ErrorHandlerProvider extends $NotifierProvider<ErrorHandler, void> {
  /// Global error handler for Riverpod providers
  /// Logs all provider errors to Siglat and provides user-friendly error messages
  const ErrorHandlerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'errorHandlerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$errorHandlerHash();

  @$internal
  @override
  ErrorHandler create() => ErrorHandler();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$errorHandlerHash() => r'6bf6b63fb261de37024fc7bdaae2066a3b94387f';

/// Global error handler for Riverpod providers
/// Logs all provider errors to Siglat and provides user-friendly error messages

abstract class _$ErrorHandler extends $Notifier<void> {
  void build();
  @$mustCallSuper
  @override
  void runBuild() {
    build();
    final ref = this.ref as $Ref<void, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<void, void>,
              void,
              Object?,
              Object?
            >;
    element.handleValue(ref, null);
  }
}
