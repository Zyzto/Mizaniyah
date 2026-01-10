import 'package:go_router/go_router.dart';
import '../../../core/navigation/route_paths.dart';
import 'pages/statistics_page.dart';

/// Statistics routes for the application
List<RouteBase> getStatisticsRoutes() {
  return [
    GoRoute(
      path: RoutePaths.statistics,
      builder: (context, state) => const StatisticsPage(),
    ),
  ];
}
