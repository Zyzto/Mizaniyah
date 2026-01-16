import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_settings_framework/flutter_settings_framework.dart';
import 'package:flutter_logging_service/flutter_logging_service.dart';
import '../settings_definitions.dart';

part 'settings_framework_providers.g.dart';

// =============================================================================
// BASE SETTINGS PROVIDERS - These are overridden at runtime
// =============================================================================

/// Provider for Mizaniyah settings controller
final mizaniyahSettingsControllerProvider = Provider<SettingsController>((ref) {
  throw UnimplementedError('Settings controller must be overridden');
});

/// Provider for Mizaniyah settings search index
final mizaniyahSettingsSearchIndexProvider = Provider<SearchIndex>((ref) {
  throw UnimplementedError('Settings search index must be overridden');
});

/// Provider for Mizaniyah settings
final mizaniyahSettingsProvider = Provider<SettingsProviders>((ref) {
  throw UnimplementedError('Settings providers must be overridden');
});

/// Initialize the Mizaniyah settings framework.
Future<SettingsProviders> initializeMizaniyahSettings() async {
  try {
    final registry = createMizaniyahSettingsRegistry();
    final storage = SharedPreferencesStorage();

    return await initializeSettings(registry: registry, storage: storage);
  } catch (e) {
    // Re-throw with more context
    throw Exception('Failed to initialize settings framework: $e');
  }
}

// =============================================================================
// CONVENIENCE PROVIDERS - Simplified access to commonly used settings
// =============================================================================

/// Helper function to safely read a setting with error handling
T _safeReadSetting<T>(Ref ref, SettingDefinition settingDef, T defaultValue) {
  try {
    final settings = ref.watch(mizaniyahSettingsProvider);
    return ref.watch(settings.provider(settingDef)) as T;
  } catch (e) {
    Log.warning('Failed to read setting ${settingDef.key}, using default: $e');
    return defaultValue;
  }
}

/// Provider for theme mode setting
@riverpod
ThemeMode themeMode(Ref ref) {
  final themeModeStr = _safeReadSetting<String>(
    ref,
    themeModeSettingDef,
    'system',
  );

  switch (themeModeStr) {
    case 'light':
      return ThemeMode.light;
    case 'dark':
      return ThemeMode.dark;
    case 'system':
    default:
      return ThemeMode.system;
  }
}

/// Provider for theme color setting (returns Color)
@riverpod
Color themeColor(Ref ref) {
  final colorValue = _safeReadSetting<int>(
    ref,
    themeColorSettingDef,
    0xFF2E7D32, // Default green
  );
  return Color(colorValue);
}

/// Provider for theme color value setting (returns int for storage)
@riverpod
int themeColorValue(Ref ref) {
  return _safeReadSetting<int>(
    ref,
    themeColorSettingDef,
    0xFF2E7D32, // Default green
  );
}

/// Provider for font size scale setting
@riverpod
String fontSizeScale(Ref ref) {
  return _safeReadSetting<String>(ref, fontSizeScaleSettingDef, 'normal');
}

/// Provider for language setting
@riverpod
String languageSetting(Ref ref) {
  return _safeReadSetting<String>(ref, languageSettingDef, 'en');
}

/// Provider for locale based on language setting
@riverpod
Locale locale(Ref ref) {
  final languageCode = ref.watch(languageSettingProvider);
  return Locale(languageCode);
}

/// Provider for SMS detection enabled setting
@riverpod
bool smsDetectionEnabled(Ref ref) {
  return _safeReadSetting<bool>(ref, smsDetectionEnabledSettingDef, true);
}

/// Provider for auto-confirm transactions setting
@riverpod
bool autoConfirmTransactions(Ref ref) {
  return _safeReadSetting<bool>(ref, autoConfirmTransactionsSettingDef, false);
}

/// Provider for confidence threshold setting
@riverpod
double confidenceThreshold(Ref ref) {
  return _safeReadSetting<double>(ref, confidenceThresholdSettingDef, 0.7);
}

/// Provider for default currency setting
@riverpod
String defaultCurrency(Ref ref) {
  return _safeReadSetting<String>(ref, defaultCurrencySettingDef, 'USD');
}

// =============================================================================
// SETTINGS UPDATE HELPERS
// =============================================================================

/// Extension to easily update settings
extension SettingsUpdate on WidgetRef {
  /// Update theme mode setting
  void setThemeMode(String mode) {
    try {
      final settings = read(mizaniyahSettingsProvider);
      read(settings.provider(themeModeSettingDef).notifier).set(mode);
      Log.debug('Theme mode updated to: $mode');
    } catch (e) {
      Log.error('Failed to update theme mode', error: e);
    }
  }

  /// Update theme color setting
  void setThemeColor(int colorValue) {
    try {
      final settings = read(mizaniyahSettingsProvider);
      read(settings.provider(themeColorSettingDef).notifier).set(colorValue);
      Log.debug('Theme color updated to: ${colorValue.toRadixString(16)}');
    } catch (e) {
      Log.error('Failed to update theme color', error: e);
    }
  }

  /// Update font size scale setting
  void setFontSizeScale(String scale) {
    try {
      final settings = read(mizaniyahSettingsProvider);
      read(settings.provider(fontSizeScaleSettingDef).notifier).set(scale);
      Log.debug('Font size scale updated to: $scale');
    } catch (e) {
      Log.error('Failed to update font size scale', error: e);
    }
  }

  /// Update language setting
  void setLanguage(String languageCode) {
    try {
      final settings = read(mizaniyahSettingsProvider);
      read(settings.provider(languageSettingDef).notifier).set(languageCode);
      Log.debug('Language updated to: $languageCode');
    } catch (e) {
      Log.error('Failed to update language', error: e);
    }
  }

  /// Update SMS detection enabled setting
  void setSmsDetectionEnabled(bool enabled) {
    try {
      final settings = read(mizaniyahSettingsProvider);
      read(
        settings.provider(smsDetectionEnabledSettingDef).notifier,
      ).set(enabled);
      Log.debug('SMS detection enabled updated to: $enabled');
    } catch (e) {
      Log.error('Failed to update SMS detection enabled', error: e);
    }
  }

  /// Update auto-confirm transactions setting
  void setAutoConfirmTransactions(bool autoConfirm) {
    try {
      final settings = read(mizaniyahSettingsProvider);
      read(
        settings.provider(autoConfirmTransactionsSettingDef).notifier,
      ).set(autoConfirm);
      Log.debug('Auto-confirm transactions updated to: $autoConfirm');
    } catch (e) {
      Log.error('Failed to update auto-confirm transactions', error: e);
    }
  }

  /// Update confidence threshold setting
  void setConfidenceThreshold(double threshold) {
    try {
      final settings = read(mizaniyahSettingsProvider);
      read(
        settings.provider(confidenceThresholdSettingDef).notifier,
      ).set(threshold);
      Log.debug('Confidence threshold updated to: $threshold');
    } catch (e) {
      Log.error('Failed to update confidence threshold', error: e);
    }
  }

  /// Update default currency setting
  void setDefaultCurrency(String currency) {
    try {
      final settings = read(mizaniyahSettingsProvider);
      read(settings.provider(defaultCurrencySettingDef).notifier).set(currency);
      Log.debug('Default currency updated to: $currency');
    } catch (e) {
      Log.error('Failed to update default currency', error: e);
    }
  }
}
