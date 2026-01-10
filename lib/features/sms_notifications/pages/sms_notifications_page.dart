import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/pending_confirmations_tab.dart';
import '../widgets/all_sms_tab.dart';
import '../widgets/notifications_tab.dart';

class SmsNotificationsPage extends ConsumerStatefulWidget {
  final TabController tabController;

  const SmsNotificationsPage({
    super.key,
    required this.tabController,
  });

  @override
  ConsumerState<SmsNotificationsPage> createState() =>
      _SmsNotificationsPageState();
}

class _SmsNotificationsPageState extends ConsumerState<SmsNotificationsPage> {
  @override
  Widget build(BuildContext context) {
    return TabBarView(
      controller: widget.tabController,
      children: const [
        PendingConfirmationsTab(),
        AllSmsTab(),
        NotificationsTab(),
      ],
    );
  }
}
