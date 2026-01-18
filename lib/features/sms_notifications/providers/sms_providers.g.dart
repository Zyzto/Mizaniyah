// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sms_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provider for SMS list with parsing status
/// Uses progressive loading: shows SMS immediately, parses in background

@ProviderFor(SmsList)
const smsListProvider = SmsListProvider._();

/// Provider for SMS list with parsing status
/// Uses progressive loading: shows SMS immediately, parses in background
final class SmsListProvider
    extends $NotifierProvider<SmsList, AsyncValue<List<SmsWithStatus>>> {
  /// Provider for SMS list with parsing status
  /// Uses progressive loading: shows SMS immediately, parses in background
  const SmsListProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'smsListProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$smsListHash();

  @$internal
  @override
  SmsList create() => SmsList();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<List<SmsWithStatus>> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<List<SmsWithStatus>>>(
        value,
      ),
    );
  }
}

String _$smsListHash() => r'f121d2edbe106e1370cbe344d89d44e0cc385be9';

/// Provider for SMS list with parsing status
/// Uses progressive loading: shows SMS immediately, parses in background

abstract class _$SmsList extends $Notifier<AsyncValue<List<SmsWithStatus>>> {
  AsyncValue<List<SmsWithStatus>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref =
        this.ref
            as $Ref<
              AsyncValue<List<SmsWithStatus>>,
              AsyncValue<List<SmsWithStatus>>
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<List<SmsWithStatus>>,
                AsyncValue<List<SmsWithStatus>>
              >,
              AsyncValue<List<SmsWithStatus>>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
