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
import '../../../core/navigation/route_paths.dart';
import '../widgets/sms_template_tester.dart';

/// SMS Template Library page
/// Focus: View and test existing SMS templates
/// Use this page to browse templates, test them, and view their details
class SmsTemplatePage extends ConsumerStatefulWidget {
  const SmsTemplatePage({super.key});

  @override
  ConsumerState<SmsTemplatePage> createState() => _SmsTemplatePageState();
}

class _SmsTemplatePageState extends ConsumerState<SmsTemplatePage> {
  String _filter = 'all'; // 'all', 'active', 'inactive'

  @override
  Widget build(BuildContext context) {
    final templatesAsync = ref.watch(smsTemplatesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('template_library'.tr()),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              setState(() {
                _filter = value;
              });
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'all',
                child: Text('all'.tr()),
              ),
              PopupMenuItem(
                value: 'active',
                child: Text('active'.tr()),
              ),
              PopupMenuItem(
                value: 'inactive',
                child: Text('inactive'.tr()),
              ),
            ],
          ),
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
          final filtered = _filterTemplates(templates);
          final activeCount = templates.where((t) => t.isActive).length;
          final inactiveCount = templates.length - activeCount;

          if (filtered.isEmpty) {
            return EmptyState(
              icon: Icons.pattern_outlined,
              title: _filter == 'all'
                  ? 'no_sms_templates'.tr()
                  : _filter == 'active'
                      ? 'no_active_templates'.tr()
                      : 'no_inactive_templates'.tr(),
              subtitle: _filter == 'all'
                  ? 'add_first_template'.tr()
                  : 'no_templates_match_filter'.tr(),
              actionLabel: _filter == 'all' ? 'add_template'.tr() : null,
              onAction: _filter == 'all' ? _navigateToAddTemplate : null,
            );
          }

          return Column(
            children: [
              if (templates.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      _buildStatChip(
                        context,
                        'total'.tr(),
                        templates.length.toString(),
                        Icons.list,
                      ),
                      const SizedBox(width: 8),
                      _buildStatChip(
                        context,
                        'active'.tr(),
                        activeCount.toString(),
                        Icons.check_circle,
                        Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      _buildStatChip(
                        context,
                        'inactive'.tr(),
                        inactiveCount.toString(),
                        Icons.cancel,
                        Theme.of(context).colorScheme.error,
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  children: [
                    // Section header
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      child: Text(
                        'template_library'.tr(),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                    // Template cards
                    ...filtered.map(
                      (template) => _buildTemplateCard(context, template),
                    ),
                  ],
                ),
              ),
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: template.isActive
                    ? colorScheme.primaryContainer
                    : colorScheme.surfaceContainerHighest,
              ),
              child: Icon(
                template.isActive ? Icons.check_circle : Icons.cancel,
                color: template.isActive
                    ? colorScheme.onPrimaryContainer
                    : colorScheme.onSurfaceVariant,
              ),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    template.pattern.length > 50
                        ? '${template.pattern.substring(0, 50)}...'
                        : template.pattern,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (!template.isActive)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'inactive'.tr(),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.onErrorContainer,
                      ),
                    ),
                  ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (template.senderPattern != null &&
                    template.senderPattern!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      children: [
                        Icon(
                          Icons.phone,
                          size: 14,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            template.senderPattern!,
                            style: theme.textTheme.bodySmall,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    children: [
                      Icon(
                        Icons.priority_high,
                        size: 14,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'priority_label'.tr(args: [template.priority.toString()]),
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
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
              _showTemplateTester(context, template);
            },
          ),
          // Action buttons
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      _showTemplateTester(context, template);
                    },
                    icon: const Icon(Icons.bug_report_outlined),
                    label: Text('test_template'.tr()),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      _navigateToEditTemplate(template);
                    },
                    icon: const Icon(Icons.edit),
                    label: Text('edit'.tr()),
                  ),
                ),
              ],
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

  List<db.SmsTemplate> _filterTemplates(List<db.SmsTemplate> templates) {
    switch (_filter) {
      case 'active':
        return templates.where((t) => t.isActive).toList();
      case 'inactive':
        return templates.where((t) => !t.isActive).toList();
      default:
        return templates;
    }
  }

  Widget _buildStatChip(
    BuildContext context,
    String label,
    String value,
    IconData icon, [
    Color? color,
  ]) {
    final chipColor = color ?? Theme.of(context).colorScheme.surfaceContainerHighest;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: chipColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Theme.of(context).colorScheme.onSurface),
          const SizedBox(width: 4),
          Text(
            '$label: $value',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
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
