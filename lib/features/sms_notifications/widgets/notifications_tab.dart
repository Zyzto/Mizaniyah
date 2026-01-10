import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/widgets/empty_state.dart';

/// Notifications history tab
/// TODO: Implement notification history tracking
class NotificationsTab extends StatelessWidget {
  const NotificationsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.notifications_none_outlined,
      title: 'no_notifications'.tr(),
      subtitle: 'notification_history_description'.tr(),
    );
  }
}
