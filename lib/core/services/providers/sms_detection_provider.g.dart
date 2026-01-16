// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sms_detection_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provider that manages SMS detection service based on settings
/// Returns the current state of SMS detection settings

@ProviderFor(SmsDetectionManager)
const smsDetectionManagerProvider = SmsDetectionManagerProvider._();

/// Provider that manages SMS detection service based on settings
/// Returns the current state of SMS detection settings
final class SmsDetectionManagerProvider
    extends $NotifierProvider<SmsDetectionManager, SmsDetectionState> {
  /// Provider that manages SMS detection service based on settings
  /// Returns the current state of SMS detection settings
  const SmsDetectionManagerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'smsDetectionManagerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$smsDetectionManagerHash();

  @$internal
  @override
  SmsDetectionManager create() => SmsDetectionManager();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SmsDetectionState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SmsDetectionState>(value),
    );
  }
}

String _$smsDetectionManagerHash() =>
    r'8f19ced8ffff4d2ca165d14ee6822753def9c6a9';

/// Provider that manages SMS detection service based on settings
/// Returns the current state of SMS detection settings

abstract class _$SmsDetectionManager extends $Notifier<SmsDetectionState> {
  SmsDetectionState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<SmsDetectionState, SmsDetectionState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<SmsDetectionState, SmsDetectionState>,
              SmsDetectionState,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
