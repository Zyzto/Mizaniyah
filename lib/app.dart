import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/app_scroll_behavior.dart';
import 'features/settings/providers/settings_framework_providers.dart';
import 'features/settings/settings_definitions.dart';
import 'core/services/notification_service.dart';
import 'core/navigation/app_router.dart';
import 'package:flutter_logging_service/flutter_logging_service.dart';

/// Main application widget
class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    // Set router in NotificationService for navigation from notification taps
    NotificationService.setRouter(router);

    // Get settings from framework
    ThemeMode themeMode;
    int themeColor;
    double cardElevation;
    double cardBorderRadius;
    String fontSizeScale;
    Locale? locale;

    try {
      final settings = ref.watch(mizaniyahSettingsProvider);
      final themeModeStr = ref.watch(settings.provider(themeModeSettingDef));
      themeMode = _parseThemeMode(themeModeStr);
      themeColor = ref.watch(settings.provider(themeColorSettingDef));
      cardElevation = ref.watch(settings.provider(cardElevationSettingDef));
      cardBorderRadius = ref.watch(
        settings.provider(cardBorderRadiusSettingDef),
      );
      fontSizeScale = ref.watch(settings.provider(fontSizeScaleSettingDef));

      // Get language setting and update locale
      final languageCode = ref.watch(settings.provider(languageSettingDef));
      locale = Locale(languageCode);
      // Update context locale if it's different
      if (context.locale.languageCode != languageCode) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          context.setLocale(locale!);
        });
      }
    } catch (e) {
      Log.warning('Settings framework not initialized, using defaults');
      themeMode = ThemeMode.system;
      themeColor = 4283215696;
      cardElevation = 2.0;
      cardBorderRadius = 12.0;
      fontSizeScale = 'normal';
      locale = const Locale('en');
    }

    return MaterialApp.router(
      title: 'Mizaniyah',
      debugShowCheckedModeBanner: kDebugMode,
      scrollBehavior: AppScrollBehavior(),
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: locale,
      theme: AppTheme.lightTheme(
        seedColor: Color(themeColor),
        cardElevation: cardElevation,
        cardBorderRadius: cardBorderRadius,
        fontSizeScale: fontSizeScale,
      ),
      darkTheme: AppTheme.darkTheme(
        seedColor: Color(themeColor),
        cardElevation: cardElevation,
        cardBorderRadius: cardBorderRadius,
        fontSizeScale: fontSizeScale,
      ),
      themeMode: themeMode,
      routerConfig: router,
    );
  }

  ThemeMode _parseThemeMode(String themeModeStr) {
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
}
