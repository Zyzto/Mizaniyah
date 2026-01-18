import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/app_scroll_behavior.dart';
import 'core/theme/theme_config.dart';
import 'features/settings/providers/settings_framework_providers.dart';
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
  bool _initialLanguageSynced = false;

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
    // This now returns a proper state object instead of void
    ref.watch(smsDetectionManagerProvider);

    // Use convenience providers for cleaner access with built-in error handling
    final themeMode = ref.watch(themeModeProvider);
    final themeModeString = ref.watch(themeModeStringProvider);
    final themeColor = ref.watch(themeColorProvider);
    final fontSizeScale = ref.watch(fontSizeScaleProvider);

    // Listen to language setting changes and sync with EasyLocalization
    // Using ref.listen ensures we react to changes immediately
    ref.listen<String>(languageSettingProvider, (previous, next) {
      if (previous != next && context.mounted) {
        final newLocale = Locale(next);
        context.setLocale(newLocale);
        Log.debug('Language changed from $previous to $next');
      }
    });

    // On first build, sync saved language setting with EasyLocalization
    // This ensures app starts with the correct language from settings
    if (!_initialLanguageSynced) {
      _initialLanguageSynced = true;
      final savedLanguage = ref.read(languageSettingProvider);
      if (context.locale.languageCode != savedLanguage) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && context.mounted) {
            context.setLocale(Locale(savedLanguage));
            Log.debug('Initial language synced to: $savedLanguage');
          }
        });
      }
    }

    // Use EasyLocalization's locale (context.locale) as the source of truth
    // This ensures translations update immediately when language changes
    
    // Build current theme data for AnimatedTheme
    // Handle AMOLED theme separately
    final currentThemeData = themeModeString == 'amoled'
        ? AppTheme.amoledTheme(
            seedColor: themeColor,
            fontSizeScale: fontSizeScale,
          )
        : themeMode == ThemeMode.dark
            ? AppTheme.darkTheme(
                seedColor: themeColor,
                fontSizeScale: fontSizeScale,
              )
            : AppTheme.lightTheme(
                seedColor: themeColor,
                fontSizeScale: fontSizeScale,
              );
    
    // For AMOLED, we need to override both light and dark themes
    final lightTheme = AppTheme.lightTheme(
      seedColor: themeColor,
      fontSizeScale: fontSizeScale,
    );
    final darkTheme = themeModeString == 'amoled'
        ? AppTheme.amoledTheme(
            seedColor: themeColor,
            fontSizeScale: fontSizeScale,
          )
        : AppTheme.darkTheme(
            seedColor: themeColor,
            fontSizeScale: fontSizeScale,
          );
    
    return AnimatedTheme(
      data: currentThemeData,
      duration: ThemeConfig.animationMedium,
      child: MaterialApp.router(
        title: 'Mizaniyah',
        debugShowCheckedModeBanner: kDebugMode,
        scrollBehavior: AppScrollBehavior(),
        localizationsDelegates: context.localizationDelegates,
        supportedLocales: context.supportedLocales,
        locale: context.locale, // Use EasyLocalization's locale
        theme: lightTheme,
        darkTheme: darkTheme,
        themeMode: themeModeString == 'amoled' ? ThemeMode.dark : themeMode,
        routerConfig: router,
      ),
    );
  }
}
