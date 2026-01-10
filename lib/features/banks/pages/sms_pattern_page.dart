import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:drift/drift.dart' as drift;
import 'package:easy_localization/easy_localization.dart';
import '../../sms_templates/providers/sms_template_providers.dart';
import 'package:mizaniyah/core/database/app_database.dart' as db;
import '../../../core/database/providers/dao_providers.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/loading_skeleton.dart';
import '../../../core/widgets/error_state.dart';
import '../widgets/sms_pattern_tester.dart';

/// Standalone SMS Patterns page (for direct navigation)
/// This is a simplified version that can be used as a full page
class SmsPatternPage extends ConsumerStatefulWidget {
  const SmsPatternPage({super.key});

  @override
  ConsumerState<SmsPatternPage> createState() => _SmsPatternPageState();
}

class _SmsPatternPageState extends ConsumerState<SmsPatternPage> {
  @override
  Widget build(BuildContext context) {
    final templatesAsync = ref.watch(smsTemplatesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('sms_patterns'.tr()),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'add_template'.tr(),
            onPressed: () {
              HapticFeedback.lightImpact();
              _navigateToAddTemplate();
            },
          ),
        ],
      ),
      body: templatesAsync.when(
        data: (templates) {
          if (templates.isEmpty) {
            return EmptyState(
              icon: Icons.pattern_outlined,
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
                child: Text(
                  'sms_templates'.tr(),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              // Template cards
              ...templates.map((template) => _buildTemplateCard(context, template)),
            ],
          );
        },
        loading: () => const SkeletonList(itemCount: 3, itemHeight: 100),
        error: (error, stack) => ErrorState(
          title: 'error_loading_templates'.tr(),
          message: error.toString(),
          onRetry: () => ref.invalidate(smsTemplatesProvider),
        ),
      ),
    );
  }

  Widget _buildTemplateCard(BuildContext context, db.SmsTemplate template) {
    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ),
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
                      'sender_pattern'.tr() + ': ${template.senderPattern}',
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
          // Test Pattern button
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: OutlinedButton.icon(
              onPressed: () {
                HapticFeedback.lightImpact();
                _showPatternTester(context, template);
              },
              icon: const Icon(Icons.bug_report_outlined),
              label: Text('test_pattern'.tr()),
            ),
          ),
        ],
      ),
    );
  }

  void _showPatternTester(BuildContext context, db.SmsTemplate template) {
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
                      'test_pattern'.tr(),
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
            // Pattern tester content
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.all(16),
                child: SmsPatternTester(
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
