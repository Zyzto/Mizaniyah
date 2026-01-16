import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/navigation/route_paths.dart';
import '../../../features/sms_notifications/widgets/batch_processing_dialog.dart';

/// AppBar for the SMS notifications page
PreferredSizeWidget buildSmsNotificationsAppBar(
  BuildContext context,
  WidgetRef ref,
  TabController? tabController, {
  required String location,
}) {
  // Only show actions on the main SMS notifications page (not sub-routes)
  final isMainPage = location == RoutePaths.smsNotifications;

  return AppBar(
    automaticallyImplyLeading: false,
    title: const SizedBox.shrink(),
    bottom: isMainPage
        ? TabBar(
            controller: tabController,
            tabs: [
              Tab(
                icon: const Icon(Icons.pending_outlined),
                text: 'pending_confirmations'.tr(),
              ),
              Tab(
                icon: const Icon(Icons.sms_outlined),
                text: 'sms_notifications'.tr(),
              ),
            ],
          )
        : null,
    actions: isMainPage
        ? [
            IconButton(
              icon: const Icon(Icons.batch_prediction_outlined),
              tooltip: 'batch_process_sms'.tr(),
              onPressed: () {
                HapticFeedback.lightImpact();
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => const BatchProcessingDialog(),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              tooltip: 'settings'.tr(),
              onPressed: () {
                HapticFeedback.lightImpact();
                context.push(RoutePaths.settings);
              },
            ),
          ]
        : [],
  );
}
