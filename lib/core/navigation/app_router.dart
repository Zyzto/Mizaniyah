import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:go_router/go_router.dart';
import 'route_paths.dart';
import '../../features/home/routes.dart';
import '../../features/transactions/routes.dart';
import '../../features/categories/routes.dart';
import '../../features/accounts/routes.dart';
import '../../features/budgets/routes.dart';
import '../../features/settings/routes.dart';
import '../../features/statistics/routes.dart';
import '../../features/sms_management/routes.dart';
import '../../features/sms_notifications/routes.dart';
import 'main_scaffold.dart';

part 'app_router.g.dart';

/// Provider for the GoRouter instance
@riverpod
GoRouter router(Ref ref) {
  return GoRouter(
    initialLocation: RoutePaths.home,
    routes: [
      // Form routes (outside ShellRoute - full screen without nav bar)
      ...getTransactionFormRoutes(),
      ...getAccountFormRoutes(),
      ...getBudgetFormRoutes(),
      ...getCategoryFormRoutes(),
      // ShellRoute wraps main pages with navigation bar
      ShellRoute(
        builder: (context, state, child) {
          // Determine selected index from current route
          final location = state.uri.path;
          int selectedIndex = 0;
          if (location.startsWith(RoutePaths.accounts)) {
            selectedIndex = 1;
          } else if (location.startsWith(RoutePaths.budget)) {
            selectedIndex = 2;
          } else if (location.startsWith(RoutePaths.home) ||
              location.startsWith(RoutePaths.transactions)) {
            selectedIndex = 0;
          }
          return MainScaffold(
            selectedIndex: selectedIndex,
            location: location,
            child: child,
          );
        },
        routes: [
          // Main routes (inside ShellRoute - with nav bar)
          ...getHomeRoutes(),
          ...getTransactionRoutes(),
          ...getAccountRoutes(),
          ...getCategoryRoutes(),
          ...getBudgetRoutes(),
          ...getSettingsRoutes(),
          ...getStatisticsRoutes(),
          ...getSmsManagementRoutes(),
          // Keep SMS notification routes for backward compatibility
          ...getSmsNotificationRoutes(),
        ],
      ),
    ],
  );
}
