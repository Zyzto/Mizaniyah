import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/navigation/route_paths.dart';

/// SMS Notifications routes for the application
List<RouteBase> getSmsNotificationRoutes() {
  return [
    GoRoute(
      path: RoutePaths.smsNotifications,
      builder: (context, state) =>
          const SizedBox.shrink(), // Handled by MainScaffold
    ),
  ];
}
