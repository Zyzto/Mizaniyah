import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:drift/drift.dart' as drift;
import 'package:easy_localization/easy_localization.dart';
import '../../sms_templates/providers/sms_template_providers.dart';
import '../../../core/database/app_database.dart' as db;
import '../../../core/database/providers/dao_providers.dart';
import '../../banks/pages/sms_pattern_page.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/loading_skeleton.dart';
import '../../../core/widgets/error_state.dart';

class SmsTemplatesTab extends ConsumerStatefulWidget {
  const SmsTemplatesTab({super.key});

  @override
  ConsumerState<SmsTemplatesTab> createState() => _SmsTemplatesTabState();
}

class _SmsTemplatesTabState extends ConsumerState<SmsTemplatesTab>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              icon: const Icon(Icons.message),
              text: 'sms_templates'.tr(),
            ),
            Tab(
              icon: const Icon(Icons.pattern_outlined),
              text: 'sms_patterns'.tr(),
            ),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildSmsTemplatesTab(),
              const SmsPatternPage(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSmsTemplatesTab() {
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

        return ListView.builder(
          itemCount: templates.length,
          itemBuilder: (context, index) {
            final template = templates[index];
            return Card(
              margin: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              child: ListTile(
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
                      Text(
                        'sender_pattern'.tr() + ': ${template.senderPattern}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    Text(
                      'priority_label'.tr(args: [template.priority.toString()]),
                      style: Theme.of(context).textTheme.bodySmall,
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
            );
          },
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

  void _navigateToAddTemplate() {
    context.push('/banks/sms-template-form');
  }

  void _navigateToEditTemplate(db.SmsTemplate template) {
    context.push('/banks/sms-template/${template.id}/edit');
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
