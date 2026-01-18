// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings_framework_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provider for theme mode setting (returns string value)

@ProviderFor(themeModeString)
const themeModeStringProvider = ThemeModeStringProvider._();

/// Provider for theme mode setting (returns string value)

final class ThemeModeStringProvider
    extends $FunctionalProvider<String, String, String>
    with $Provider<String> {
  /// Provider for theme mode setting (returns string value)
  const ThemeModeStringProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'themeModeStringProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$themeModeStringHash();

  @$internal
  @override
  $ProviderElement<String> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  String create(Ref ref) {
    return themeModeString(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String>(value),
    );
  }
}

String _$themeModeStringHash() => r'fe233b7510856100d10b79a0b8dc061a930d6f43';

/// Provider for theme mode setting (returns ThemeMode enum)
/// Note: 'amoled' is handled separately in app.dart

@ProviderFor(themeMode)
const themeModeProvider = ThemeModeProvider._();

/// Provider for theme mode setting (returns ThemeMode enum)
/// Note: 'amoled' is handled separately in app.dart

final class ThemeModeProvider
    extends $FunctionalProvider<ThemeMode, ThemeMode, ThemeMode>
    with $Provider<ThemeMode> {
  /// Provider for theme mode setting (returns ThemeMode enum)
  /// Note: 'amoled' is handled separately in app.dart
  const ThemeModeProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'themeModeProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$themeModeHash();

  @$internal
  @override
  $ProviderElement<ThemeMode> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ThemeMode create(Ref ref) {
    return themeMode(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ThemeMode value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ThemeMode>(value),
    );
  }
}

String _$themeModeHash() => r'0b0be91fa91b9c14f39a5a63f3556cd24365f695';

/// Provider for theme color setting (returns Color)

@ProviderFor(themeColor)
const themeColorProvider = ThemeColorProvider._();

/// Provider for theme color setting (returns Color)

final class ThemeColorProvider extends $FunctionalProvider<Color, Color, Color>
    with $Provider<Color> {
  /// Provider for theme color setting (returns Color)
  const ThemeColorProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'themeColorProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$themeColorHash();

  @$internal
  @override
  $ProviderElement<Color> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Color create(Ref ref) {
    return themeColor(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Color value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Color>(value),
    );
  }
}

String _$themeColorHash() => r'35aead469d3919f427545bec3ea5085179f8a258';

/// Provider for theme color value setting (returns int for storage)

@ProviderFor(themeColorValue)
const themeColorValueProvider = ThemeColorValueProvider._();

/// Provider for theme color value setting (returns int for storage)

final class ThemeColorValueProvider extends $FunctionalProvider<int, int, int>
    with $Provider<int> {
  /// Provider for theme color value setting (returns int for storage)
  const ThemeColorValueProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'themeColorValueProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$themeColorValueHash();

  @$internal
  @override
  $ProviderElement<int> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  int create(Ref ref) {
    return themeColorValue(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int>(value),
    );
  }
}

String _$themeColorValueHash() => r'31e4acb866cbb3f3c727f699a89c93bc6a734c2d';

/// Provider for font size scale setting

@ProviderFor(fontSizeScale)
const fontSizeScaleProvider = FontSizeScaleProvider._();

/// Provider for font size scale setting

final class FontSizeScaleProvider
    extends $FunctionalProvider<String, String, String>
    with $Provider<String> {
  /// Provider for font size scale setting
  const FontSizeScaleProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'fontSizeScaleProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$fontSizeScaleHash();

  @$internal
  @override
  $ProviderElement<String> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  String create(Ref ref) {
    return fontSizeScale(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String>(value),
    );
  }
}

String _$fontSizeScaleHash() => r'f2efd090cda2c7cf849140d04034de80b8624d78';

/// Provider for language setting

@ProviderFor(languageSetting)
const languageSettingProvider = LanguageSettingProvider._();

/// Provider for language setting

final class LanguageSettingProvider
    extends $FunctionalProvider<String, String, String>
    with $Provider<String> {
  /// Provider for language setting
  const LanguageSettingProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'languageSettingProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$languageSettingHash();

  @$internal
  @override
  $ProviderElement<String> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  String create(Ref ref) {
    return languageSetting(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String>(value),
    );
  }
}

String _$languageSettingHash() => r'63c857a669b7680d53eff4dc4ab084eefcefe30b';

/// Provider for locale based on language setting

@ProviderFor(locale)
const localeProvider = LocaleProvider._();

/// Provider for locale based on language setting

final class LocaleProvider extends $FunctionalProvider<Locale, Locale, Locale>
    with $Provider<Locale> {
  /// Provider for locale based on language setting
  const LocaleProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'localeProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$localeHash();

  @$internal
  @override
  $ProviderElement<Locale> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Locale create(Ref ref) {
    return locale(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Locale value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Locale>(value),
    );
  }
}

String _$localeHash() => r'fb2834d26c768c41c02526c5c6ecfa558a690a1a';

/// Provider for SMS detection enabled setting

@ProviderFor(smsDetectionEnabled)
const smsDetectionEnabledProvider = SmsDetectionEnabledProvider._();

/// Provider for SMS detection enabled setting

final class SmsDetectionEnabledProvider
    extends $FunctionalProvider<bool, bool, bool>
    with $Provider<bool> {
  /// Provider for SMS detection enabled setting
  const SmsDetectionEnabledProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'smsDetectionEnabledProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$smsDetectionEnabledHash();

  @$internal
  @override
  $ProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  bool create(Ref ref) {
    return smsDetectionEnabled(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$smsDetectionEnabledHash() =>
    r'71ba9aea6c86be461b784d86ea7f738b277724ae';

/// Provider for auto-confirm transactions setting

@ProviderFor(autoConfirmTransactions)
const autoConfirmTransactionsProvider = AutoConfirmTransactionsProvider._();

/// Provider for auto-confirm transactions setting

final class AutoConfirmTransactionsProvider
    extends $FunctionalProvider<bool, bool, bool>
    with $Provider<bool> {
  /// Provider for auto-confirm transactions setting
  const AutoConfirmTransactionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'autoConfirmTransactionsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$autoConfirmTransactionsHash();

  @$internal
  @override
  $ProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  bool create(Ref ref) {
    return autoConfirmTransactions(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$autoConfirmTransactionsHash() =>
    r'608e6671f5c94bb5637eb115f04b9aeaecd36dfc';

/// Provider for confidence threshold setting

@ProviderFor(confidenceThreshold)
const confidenceThresholdProvider = ConfidenceThresholdProvider._();

/// Provider for confidence threshold setting

final class ConfidenceThresholdProvider
    extends $FunctionalProvider<double, double, double>
    with $Provider<double> {
  /// Provider for confidence threshold setting
  const ConfidenceThresholdProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'confidenceThresholdProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$confidenceThresholdHash();

  @$internal
  @override
  $ProviderElement<double> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  double create(Ref ref) {
    return confidenceThreshold(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(double value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<double>(value),
    );
  }
}

String _$confidenceThresholdHash() =>
    r'18915562874b05d05f84452b7da9ba5e297df313';

/// Provider for default currency setting

@ProviderFor(defaultCurrency)
const defaultCurrencyProvider = DefaultCurrencyProvider._();

/// Provider for default currency setting

final class DefaultCurrencyProvider
    extends $FunctionalProvider<String, String, String>
    with $Provider<String> {
  /// Provider for default currency setting
  const DefaultCurrencyProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'defaultCurrencyProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$defaultCurrencyHash();

  @$internal
  @override
  $ProviderElement<String> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  String create(Ref ref) {
    return defaultCurrency(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String>(value),
    );
  }
}

String _$defaultCurrencyHash() => r'903528f0c68fd1548db1f5f60aed490be3182de8';
