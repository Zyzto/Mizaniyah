import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_logging_service/flutter_logging_service.dart';
import 'package:mizaniyah/core/services/sms_detection_service.dart';
import 'package:mizaniyah/features/settings/providers/settings_framework_providers.dart';
import 'package:mizaniyah/features/settings/settings_definitions.dart'
    show smsDetectionEnabledSettingDef;

part 'sms_detection_provider.g.dart';

/// State class for SMS detection settings
class SmsDetectionState {
  final bool isEnabled;
  final bool autoConfirm;
  final double confidenceThreshold;
  final bool isListening;

  const SmsDetectionState({
    required this.isEnabled,
    required this.autoConfirm,
    required this.confidenceThreshold,
    required this.isListening,
  });

  SmsDetectionState copyWith({
    bool? isEnabled,
    bool? autoConfirm,
    double? confidenceThreshold,
    bool? isListening,
  }) {
    return SmsDetectionState(
      isEnabled: isEnabled ?? this.isEnabled,
      autoConfirm: autoConfirm ?? this.autoConfirm,
      confidenceThreshold: confidenceThreshold ?? this.confidenceThreshold,
      isListening: isListening ?? this.isListening,
    );
  }

  static const initial = SmsDetectionState(
    isEnabled: true,
    autoConfirm: false,
    confidenceThreshold: 0.7,
    isListening: false,
  );
}

/// Provider that manages SMS detection service based on settings
/// Returns the current state of SMS detection settings
@riverpod
class SmsDetectionManager extends _$SmsDetectionManager {
  @override
  SmsDetectionState build() {
    // Watch settings using convenience providers (they have built-in error handling)
    final smsDetectionEnabled = ref.watch(smsDetectionEnabledProvider);
    final autoConfirm = ref.watch(autoConfirmTransactionsProvider);
    final confidenceThreshold = ref.watch(confidenceThresholdProvider);

    // Update service settings (these are always safe to call)
    SmsDetectionService.instance.setAutoConfirm(autoConfirm);
    SmsDetectionService.instance.setConfidenceThreshold(confidenceThreshold);

    // Only start/stop listening if the state actually changes
    final isCurrentlyListening = SmsDetectionService.instance.isListening;

    if (smsDetectionEnabled && !isCurrentlyListening) {
      SmsDetectionService.instance.startListening();
      Log.debug('SMS detection enabled and listening started');
    } else if (!smsDetectionEnabled && isCurrentlyListening) {
      SmsDetectionService.instance.stop();
      Log.debug('SMS detection disabled and listening stopped');
    }

    return SmsDetectionState(
      isEnabled: smsDetectionEnabled,
      autoConfirm: autoConfirm,
      confidenceThreshold: confidenceThreshold,
      isListening: smsDetectionEnabled,
    );
  }

  /// Manually toggle SMS detection
  void toggleDetection() {
    try {
      final settings = ref.read(mizaniyahSettingsProvider);
      ref
          .read(settings.provider(smsDetectionEnabledSettingDef).notifier)
          .set(!state.isEnabled);
      Log.debug('SMS detection toggled to: ${!state.isEnabled}');
    } catch (e) {
      Log.error('Failed to toggle SMS detection', error: e);
    }
  }
}
