import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mizaniyah/core/services/sms_detection_service.dart';
import 'package:mizaniyah/features/settings/providers/settings_framework_providers.dart';
import 'package:mizaniyah/features/settings/settings_definitions.dart';

/// Provider that manages SMS detection service based on settings
final smsDetectionManagerProvider = Provider<void>((ref) {
  final settings = ref.watch(mizaniyahSettingsProvider);
  final smsDetectionEnabled = ref.watch(
    settings.provider(smsDetectionEnabledSettingDef),
  );
  final autoConfirm = ref.watch(
    settings.provider(autoConfirmTransactionsSettingDef),
  );
  final confidenceThreshold = ref.watch(
    settings.provider(confidenceThresholdSettingDef),
  );

  // Update settings in service
  SmsDetectionService.instance.setAutoConfirm(autoConfirm);
  SmsDetectionService.instance.setConfidenceThreshold(confidenceThreshold);

  // Start or stop listening based on setting
  if (smsDetectionEnabled) {
    SmsDetectionService.instance.startListening();
  } else {
    SmsDetectionService.instance.stop();
  }

  return;
});
