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

/// Theme mode setting (system, light, dark)
const themeModeSettingDef = EnumSetting(
  'theme_mode',
  defaultValue: 'system',
  titleKey: 'theme',
  options: ['system', 'light', 'dark'],
  optionLabels: {'system': 'system', 'light': 'light', 'dark': 'dark'},
  icon: Icons.dark_mode,
  section: 'general',
  order: 0,
);

/// Theme color setting
const themeColorSettingDef = ColorSetting(
  'theme_color',
  defaultValue: 4283215696, // Default gray color
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

/// Card elevation
const cardElevationSettingDef = DoubleSetting(
  'card_elevation',
  defaultValue: 2.0,
  min: 0.0,
  max: 8.0,
  titleKey: 'card_elevation',
  icon: Icons.layers,
  section: 'appearance',
  order: 1,
);

/// Card border radius
const cardBorderRadiusSettingDef = DoubleSetting(
  'card_border_radius',
  defaultValue: 12.0,
  min: 0.0,
  max: 32.0,
  titleKey: 'card_border_radius',
  icon: Icons.rounded_corner,
  section: 'appearance',
  order: 2,
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

// =============================================================================
// CURRENCY SETTINGS
// =============================================================================

/// Default currency
const defaultCurrencySettingDef = StringSetting(
  'default_currency',
  defaultValue: 'USD',
  titleKey: 'default_currency',
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
  cardElevationSettingDef,
  cardBorderRadiusSettingDef,

  // SMS
  smsDetectionEnabledSettingDef,
  autoConfirmTransactionsSettingDef,

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
