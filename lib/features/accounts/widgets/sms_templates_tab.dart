import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:drift/drift.dart' as drift;
import 'package:easy_localization/easy_localization.dart';
import '../../sms_templates/providers/sms_template_providers.dart';
import '../../../core/database/app_database.dart' as db;
import '../../../core/database/providers/dao_providers.dart';
import '../../../core/navigation/route_paths.dart';
import '../../sms_management/widgets/sms_template_tester.dart';
import '../../sms_notifications/widgets/all_sms_tab.dart';
import '../../sms_notifications/widgets/notifications_tab.dart';
import '../../sms_notifications/widgets/pending_confirmations_tab.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/loading_skeleton.dart';
import '../../../core/widgets/error_state.dart';

class SmsTemplatesTab extends ConsumerStatefulWidget {
  const SmsTemplatesTab({super.key});

  @override
  ConsumerState<SmsTemplatesTab> createState() => _SmsTemplatesTabState();
}

class _SmsTemplatesTabState extends ConsumerState<SmsTemplatesTab>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  late TabController _tabController;
  bool _isIOS = false;

  @override
  void initState() {
    super.initState();
    // Detect iOS platform
    _isIOS = !kIsWeb && Platform.isIOS;
    // On iOS: Pending, Templates, and Notifications (3 tabs, no SMS reading)
    // On Android: Pending, Templates, SMS, and Notifications (4 tabs)
    _tabController = TabController(length: _isIOS ? 3 : 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: [
            Tab(
              icon: const Icon(Icons.pending_outlined),
              text: 'pending_confirmations'.tr(),
            ),
            Tab(
              icon: const Icon(Icons.pattern_outlined),
              text: 'sms_templates'.tr(),
            ),
            if (!_isIOS)
              Tab(icon: const Icon(Icons.sms_outlined), text: 'all_sms'.tr()),
            Tab(
              icon: const Icon(Icons.notifications_outlined),
              text: 'notifications'.tr(),
            ),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              const PendingConfirmationsTab(),
              _buildTemplatesTab(),
              if (!_isIOS) const AllSmsTab(),
              const NotificationsTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTemplatesTab() {
    return _buildUnifiedTemplatesList();
  }

  Widget _buildUnifiedTemplatesList() {
    final templatesAsync = ref.watch(smsTemplatesProvider);

    return templatesAsync.when(
      data: (templates) {
        if (templates.isEmpty) {
          return EmptyState(
            icon: Icons.message_outlined,
            title: 'no_sms_templates'.tr(),
            subtitle: 'add_first_template'.tr(),
            actionLabel: 'add_template'.tr(),
            onAction: _navigateToAddTemplate,
          );
        }

        return ListView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: [
            // Section header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'sms_templates'.tr(),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add),
                    tooltip: 'add_template'.tr(),
                    onPressed: _navigateToAddTemplate,
                  ),
                ],
              ),
            ),
            // Template cards
            ...templates.map(
              (template) => _buildTemplateCard(context, template),
            ),
          ],
        );
      },
      loading: () => const SkeletonList(itemCount: 5, itemHeight: 80),
      error: (error, stack) => ErrorState(
        title: 'error_loading_templates'.tr(),
        message: error.toString(),
        onRetry: () => ref.invalidate(smsTemplatesProvider),
      ),
    );
  }

  Widget _buildTemplateCard(BuildContext context, db.SmsTemplate template) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: const Icon(Icons.message),
            title: Text(
              template.pattern.length > 50
                  ? '${template.pattern.substring(0, 50)}...'
                  : template.pattern,
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (template.senderPattern != null &&
                    template.senderPattern!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '${'sender_pattern'.tr()}: ${template.senderPattern}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'priority_label'.tr(args: [template.priority.toString()]),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Switch(
                  value: template.isActive,
                  onChanged: (value) {
                    HapticFeedback.lightImpact();
                    _toggleTemplateActive(template, value);
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.edit),
                  tooltip: 'edit'.tr(),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    _navigateToEditTemplate(template);
                  },
                ),
              ],
            ),
            onTap: () {
              HapticFeedback.lightImpact();
              _navigateToEditTemplate(template);
            },
          ),
          // Test Template button
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: OutlinedButton.icon(
              onPressed: () {
                HapticFeedback.lightImpact();
                _showTemplateTester(context, template);
              },
              icon: const Icon(Icons.bug_report_outlined),
              label: Text('test_template'.tr()),
            ),
          ),
        ],
      ),
    );
  }

  void _showTemplateTester(BuildContext context, db.SmsTemplate template) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'test_template'.tr(),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: 'close'.tr(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Template tester content
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.all(16),
                child: SmsTemplateTester(
                  pattern: template.pattern,
                  extractionRules: template.extractionRules,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToAddTemplate() {
    context.push(RoutePaths.smsTemplateForm);
  }

  void _navigateToEditTemplate(db.SmsTemplate template) {
    context.push(RoutePaths.smsTemplateEdit(template.id));
  }

  Future<void> _toggleTemplateActive(
    db.SmsTemplate template,
    bool value,
  ) async {
    try {
      final dao = ref.read(smsTemplateDaoProvider);
      await dao.updateTemplate(
        db.SmsTemplatesCompanion(
          id: drift.Value(template.id),
          isActive: drift.Value(value),
        ),
      );
    } catch (e) {
      // Error handling is done by the DAO
    }
  }
}
