import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/app_scroll_behavior.dart';
import 'features/settings/providers/settings_framework_providers.dart';
import 'features/settings/settings_definitions.dart';
import 'core/services/notification_service.dart';
import 'core/services/providers/sms_detection_provider.dart';
import 'core/navigation/app_router.dart';
import 'features/sms_notifications/providers/sms_providers.dart';
import 'package:flutter_logging_service/flutter_logging_service.dart';

/// Main application widget
class App extends ConsumerStatefulWidget {
  const App({super.key});

  @override
  ConsumerState<App> createState() => _AppState();
}

class _AppState extends ConsumerState<App> {
  bool _smsPreloaded = false;

  @override
  void initState() {
    super.initState();
    // Preload SMS in background after first frame (non-blocking)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Use a delay to ensure app is fully initialized and database is ready
      // Also ensures ProviderScope is fully set up
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted && !_smsPreloaded) {
          try {
            // Preload SMS in background without blocking
            // This happens in the background and doesn't hog the UI thread
            // Access the provider to trigger initialization, then preload
            final notifier = ref.read(smsListProvider.notifier);
            notifier.preloadSms();
            _smsPreloaded = true;
            Log.debug('SMS preloading started in background');
          } catch (e) {
            // Silently fail - SMS will load when page is accessed
            Log.debug('SMS preload skipped: $e');
          }
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);

    // Set router in NotificationService for navigation from notification taps
    NotificationService.setRouter(router);

    // Watch SMS detection settings to manage the service
    ref.watch(smsDetectionManagerProvider);

    // Get settings from framework
    ThemeMode themeMode;
    int themeColor;
    String fontSizeScale;
    Locale? locale;

    try {
      final settings = ref.watch(mizaniyahSettingsProvider);
      final themeModeStr = ref.watch(settings.provider(themeModeSettingDef));
      themeMode = _parseThemeMode(themeModeStr);
      themeColor = ref.watch(settings.provider(themeColorSettingDef));
      fontSizeScale = ref.watch(settings.provider(fontSizeScaleSettingDef));

      // Get language setting and update locale
      final languageCode = ref.watch(settings.provider(languageSettingDef));
      locale = Locale(languageCode);
      // Update EasyLocalization context locale if it's different
      if (context.locale.languageCode != languageCode) {
        // Use SchedulerBinding to ensure this runs after the current frame
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) {
            context.setLocale(locale!);
          }
        });
      }
    } catch (e) {
      Log.warning('Settings framework not initialized, using defaults');
      themeMode = ThemeMode.system;
      themeColor = 0xFF2E7D32; // Default Material Green
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
        fontSizeScale: fontSizeScale,
      ),
      darkTheme: AppTheme.darkTheme(
        seedColor: Color(themeColor),
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
