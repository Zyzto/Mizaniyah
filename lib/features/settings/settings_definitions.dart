/// Mizaniyah Settings Definitions
///
/// All app settings defined using the Flutter Settings Framework.
library;

import 'package:flutter/material.dart';
import 'package:flutter_settings_framework/flutter_settings_framework.dart';

// =============================================================================
// SECTIONS
// =============================================================================

/// General settings section
const generalSection = SettingSection(
  key: 'general',
  titleKey: 'general',
  icon: Icons.settings,
  order: 0,
  initiallyExpanded: true,
);

/// Appearance settings section
const appearanceSection = SettingSection(
  key: 'appearance',
  titleKey: 'appearance',
  icon: Icons.palette,
  order: 1,
);

/// SMS Detection settings section
const smsSection = SettingSection(
  key: 'sms',
  titleKey: 'sms_detection',
  icon: Icons.sms,
  order: 2,
);

/// Currency settings section
const currencySection = SettingSection(
  key: 'currency',
  titleKey: 'currency',
  icon: Icons.currency_exchange,
  order: 3,
);

// =============================================================================
// GENERAL SETTINGS
// =============================================================================

/// Theme mode setting (system, light, dark, amoled)
const themeModeSettingDef = EnumSetting(
  'theme_mode',
  defaultValue: 'system',
  titleKey: 'theme',
  options: ['system', 'light', 'dark', 'amoled'],
  optionLabels: {
    'system': 'system',
    'light': 'light',
    'dark': 'dark',
    'amoled': 'amoled',
  },
  icon: Icons.dark_mode,
  section: 'general',
  order: 0,
);

/// Theme color setting
const themeColorSettingDef = ColorSetting(
  'theme_color',
  defaultValue: 0xFF2E7D32, // Default Material Green (better than gray)
  titleKey: 'select_theme_color',
  icon: Icons.palette,
  section: 'general',
  order: 1,
);

/// Language setting
const languageSettingDef = EnumSetting(
  'language',
  defaultValue: 'en',
  titleKey: 'language',
  options: ['en', 'ar'],
  optionLabels: {'en': 'English', 'ar': 'العربية'},
  icon: Icons.language,
  section: 'general',
  order: 2,
);

// =============================================================================
// APPEARANCE SETTINGS
// =============================================================================

/// Font size scale
const fontSizeScaleSettingDef = EnumSetting(
  'font_size_scale',
  defaultValue: 'normal',
  titleKey: 'font_size',
  options: ['small', 'normal', 'large', 'extra_large'],
  optionLabels: {
    'small': 'small',
    'normal': 'normal',
    'large': 'large',
    'extra_large': 'extra_large',
  },
  icon: Icons.text_fields,
  section: 'appearance',
  order: 0,
);

// =============================================================================
// SMS DETECTION SETTINGS
// =============================================================================

/// SMS detection enabled
const smsDetectionEnabledSettingDef = BoolSetting(
  'sms_detection_enabled',
  defaultValue: true,
  titleKey: 'sms_detection_enabled',
  icon: Icons.sms,
  section: 'sms',
  order: 0,
);

/// Auto-confirm transactions (skip confirmation dialog)
const autoConfirmTransactionsSettingDef = BoolSetting(
  'auto_confirm_transactions',
  defaultValue: false,
  titleKey: 'auto_confirm_transactions',
  icon: Icons.check_circle,
  section: 'sms',
  order: 1,
);

/// Confidence threshold for auto-creating transactions (0.5-1.0)
const confidenceThresholdSettingDef = DoubleSetting(
  'sms_confidence_threshold',
  defaultValue: 0.7,
  min: 0.5,
  max: 1.0,
  step: 0.05,
  titleKey: 'confidence_threshold',
  icon: Icons.trending_up,
  section: 'sms',
  order: 2,
);

// =============================================================================
// CURRENCY SETTINGS
// =============================================================================

/// Default currency
const defaultCurrencySettingDef = EnumSetting(
  'default_currency',
  defaultValue: 'USD',
  titleKey: 'default_currency',
  options: [
    'USD',
    'EUR',
    'GBP',
    'JPY',
    'AUD',
    'CAD',
    'CHF',
    'CNY',
    'INR',
    'SGD',
    'AED',
    'SAR',
    'EGP',
  ],
  optionLabels: {
    'USD': 'US Dollar',
    'EUR': 'Euro',
    'GBP': 'British Pound',
    'JPY': 'Japanese Yen',
    'AUD': 'Australian Dollar',
    'CAD': 'Canadian Dollar',
    'CHF': 'Swiss Franc',
    'CNY': 'Chinese Yuan',
    'INR': 'Indian Rupee',
    'SGD': 'Singapore Dollar',
    'AED': 'UAE Dirham',
    'SAR': 'Saudi Riyal',
    'EGP': 'Egyptian Pound',
  },
  icon: Icons.attach_money,
  section: 'currency',
  order: 0,
);

// =============================================================================
// ALL SETTINGS
// =============================================================================

/// All setting sections.
const allSections = [
  generalSection,
  appearanceSection,
  smsSection,
  currencySection,
];

/// All setting definitions.
const allSettings = <SettingDefinition>[
  // General
  themeModeSettingDef,
  themeColorSettingDef,
  languageSettingDef,

  // Appearance
  fontSizeScaleSettingDef,

  // SMS
  smsDetectionEnabledSettingDef,
  autoConfirmTransactionsSettingDef,
  confidenceThresholdSettingDef,

  // Currency
  defaultCurrencySettingDef,
];

/// Create the Mizaniyah settings registry.
SettingsRegistry createMizaniyahSettingsRegistry() {
  return SettingsRegistry.withSettings(
    sections: allSections,
    settings: allSettings,
  );
}
