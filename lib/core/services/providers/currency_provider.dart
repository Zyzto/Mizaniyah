import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mizaniyah/features/settings/providers/settings_framework_providers.dart';
import 'package:mizaniyah/features/settings/settings_definitions.dart';

/// Provider for default currency from settings framework
final defaultCurrencyProvider = Provider<String>((ref) {
  try {
    final settings = ref.watch(mizaniyahSettingsProvider);
    return ref.watch(settings.provider(defaultCurrencySettingDef));
  } catch (e) {
    // Fallback to USD if settings framework is not available
    return 'USD';
  }
});
