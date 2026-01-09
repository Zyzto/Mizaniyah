import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/pending_confirmations_tab.dart';
import '../widgets/all_sms_tab.dart';
import '../widgets/notifications_tab.dart';
import '../../banks/pages/sms_pattern_page.dart';

class SmsNotificationsPage extends ConsumerStatefulWidget {
  const SmsNotificationsPage({super.key});

  @override
  ConsumerState<SmsNotificationsPage> createState() =>
      _SmsNotificationsPageState();
}

class _SmsNotificationsPageState extends ConsumerState<SmsNotificationsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SMS & Notifications'),
        automaticallyImplyLeading: false,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.pending_outlined), text: 'Pending'),
            Tab(icon: Icon(Icons.sms_outlined), text: 'All SMS'),
            Tab(
              icon: Icon(Icons.notifications_outlined),
              text: 'Notifications',
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.pattern_outlined),
            tooltip: 'SMS Patterns',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const SmsPatternPage()),
              );
            },
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          PendingConfirmationsTab(),
          AllSmsTab(),
          NotificationsTab(),
        ],
      ),
    );
  }
}
