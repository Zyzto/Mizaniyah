import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/app_scroll_behavior.dart';
import 'features/settings/providers/settings_framework_providers.dart';
import 'features/settings/settings_definitions.dart';
import 'features/transactions/pages/transactions_list_page.dart';
import 'features/accounts/pages/accounts_page.dart';
import 'features/sms_notifications/pages/sms_notifications_page.dart';
import 'core/services/notification_service.dart';
import 'core/widgets/floating_nav_bar.dart';
import 'package:flutter_logging_service/flutter_logging_service.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/transactions',
    routes: [
      ShellRoute(
        builder: (context, state, child) {
          // Determine selected index from current route
          final location = state.uri.path;
          int selectedIndex = 0;
          if (location.startsWith('/accounts')) {
            selectedIndex = 1;
          } else if (location.startsWith('/sms-notifications')) {
            selectedIndex = 2;
          }
          return MainScaffold(selectedIndex: selectedIndex, child: child);
        },
        routes: [
          GoRoute(
            path: '/transactions',
            builder: (context, state) => const TransactionsListPage(),
          ),
          GoRoute(
            path: '/accounts',
            builder: (context, state) => const AccountsPage(),
          ),
          GoRoute(
            path: '/sms-notifications',
            builder: (context, state) => const SmsNotificationsPage(),
          ),
        ],
      ),
    ],
  );
});

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

/// Main scaffold with bottom navigation bar
class MainScaffold extends ConsumerWidget {
  final int selectedIndex;
  final Widget child;

  const MainScaffold({
    super.key,
    required this.selectedIndex,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Stack(
        children: [
          // Main content with bottom padding for floating nav bar
          Padding(padding: const EdgeInsets.only(bottom: 100), child: child),
          // Floating navigation bar
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: FloatingNavBar(
              selectedIndex: selectedIndex,
              onDestinationSelected: (index) {
                switch (index) {
                  case 0:
                    context.go('/transactions');
                    break;
                  case 1:
                    context.go('/accounts');
                    break;
                  case 2:
                    context.go('/sms-notifications');
                    break;
                }
              },
              destinations: const [
                FloatingNavDestination(
                  icon: Icons.receipt_long_outlined,
                  selectedIcon: Icons.receipt_long,
                  label: 'Home',
                ),
                FloatingNavDestination(
                  icon: Icons.account_balance_wallet_outlined,
                  selectedIcon: Icons.account_balance_wallet,
                  label: 'Accounts',
                ),
                FloatingNavDestination(
                  icon: Icons.sms_outlined,
                  selectedIcon: Icons.sms,
                  label: 'SMS',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
