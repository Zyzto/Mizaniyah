import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_settings_framework/flutter_settings_framework.dart'
    show
        SettingsPageScaffold,
        SettingsSectionWidget,
        SwitchSettingsTile,
        SelectSettingsTile,
        SliderSettingsTile,
        ColorSettingsTile,
        SettingsProviders,
        SettingDefinition,
        BoolSetting,
        EnumSetting,
        DoubleSetting,
        ColorSetting,
        StringSetting;
import '../providers/settings_framework_providers.dart';
import '../../categories/pages/categories_page.dart';
import '../../categories/providers/category_providers.dart';
import '../../../core/services/providers/export_providers.dart';
import '../../../core/widgets/error_snackbar.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    try {
      final settings = ref.read(mizaniyahSettingsProvider);

      // Build settings sections from registry
      final sections = settings.registry.sections.map((section) {
        final sectionSettings = settings.registry.settings
            .where((s) => s.section == section.key)
            .toList();

        // Build tiles for each setting in the section based on type
        final tiles = sectionSettings.map((settingDef) {
          return _buildSettingTile(context, ref, settings, settingDef);
        }).toList();

        return SettingsSectionWidget.fromDefinition(
          section: section,
          title: section.titleKey.tr(),
          children: tiles,
        );
      }).toList();

      // Add Management section with navigation tiles
      final managementSection = _buildManagementSection(context, ref);
      sections.add(managementSection);

      // Add Export section
      final exportSection = _buildExportSection(context, ref);
      sections.add(exportSection);

      return SettingsPageScaffold(
        title: 'settings'.tr(),
        sections: sections,
      );
    } catch (e) {
      // If settings framework is not initialized, show error
      return Scaffold(
        appBar: AppBar(
          title: Text('settings'.tr()),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'settings_not_available'.tr(),
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildSettingTile(
    BuildContext context,
    WidgetRef ref,
    SettingsProviders settings,
    SettingDefinition settingDef,
  ) {
    // Build appropriate tile based on setting type
    if (settingDef is BoolSetting) {
      return SwitchSettingsTile.fromSetting(
        setting: settingDef,
        title: settingDef.titleKey.tr(),
        value: ref.watch(settings.provider(settingDef)),
        onChanged: (value) {
          HapticFeedback.lightImpact();
          ref.read(settings.provider(settingDef).notifier).set(value);
        },
      );
    } else if (settingDef is EnumSetting) {
      final currentValue = ref.watch(settings.provider(settingDef));
      final options = settingDef.options ?? [];
      return SelectSettingsTile<String>(
        leading: settingDef.icon != null ? Icon(settingDef.icon) : null,
        title: Text(settingDef.titleKey.tr()),
        options: options,
        value: currentValue,
        itemBuilder: (option) {
          final label = settingDef.optionLabels?[option] ?? option;
          return Text(label.tr());
        },
        onChanged: (value) {
          if (value != null) {
            HapticFeedback.lightImpact();
            ref.read(settings.provider(settingDef).notifier).set(value);
          }
        },
      );
    } else if (settingDef is DoubleSetting) {
      final min = settingDef.min ?? 0.0;
      final max = settingDef.max ?? 100.0;
      final step = settingDef.step;
      return SliderSettingsTile(
        leading: settingDef.icon != null ? Icon(settingDef.icon) : null,
        title: Text(settingDef.titleKey.tr()),
        value: ref.watch(settings.provider(settingDef)),
        min: min,
        max: max,
        divisions: step > 0 ? ((max - min) / step).round() : null,
        onChanged: (value) {
          HapticFeedback.lightImpact();
          ref.read(settings.provider(settingDef).notifier).set(value);
        },
      );
    } else if (settingDef is ColorSetting) {
      final colorValue = ref.watch(settings.provider(settingDef));
      return ColorSettingsTile.fromSetting(
        setting: settingDef,
        title: settingDef.titleKey.tr(),
        value: colorValue,
        onChanged: (value) {
          HapticFeedback.lightImpact();
          ref.read(settings.provider(settingDef).notifier).set(value);
        },
      );
    } else if (settingDef is StringSetting) {
      // For string settings, use a basic tile that navigates to edit
      return ListTile(
        leading: settingDef.icon != null ? Icon(settingDef.icon) : null,
        title: Text(settingDef.titleKey.tr()),
        subtitle: Text(ref.watch(settings.provider(settingDef))),
        onTap: () {
          HapticFeedback.lightImpact();
          // TODO: Show dialog to edit string setting
        },
      );
    } else {
      // Fallback for unknown setting types
      return ListTile(
        leading: settingDef.icon != null ? Icon(settingDef.icon) : null,
        title: Text(settingDef.titleKey.tr()),
        subtitle: Text('Unsupported setting type'),
      );
    }
  }

  SettingsSectionWidget _buildManagementSection(
    BuildContext context,
    WidgetRef ref,
  ) {
    final categoriesAsync = ref.watch(categoriesProvider);

    return SettingsSectionWidget(
      title: 'management'.tr(),
      icon: Icons.manage_accounts,
      children: [
        categoriesAsync.when(
          data: (categories) {
            final activeCount = categories.where((c) => c.isActive).length;
            return ListTile(
              leading: const Icon(Icons.category),
              title: Text('categories'.tr()),
              subtitle: Text(
                'categories_count'.tr(args: [categories.length.toString()]),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (activeCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        activeCount.toString(),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  const SizedBox(width: 8),
                  const Icon(Icons.chevron_right),
                ],
              ),
              onTap: () {
                HapticFeedback.lightImpact();
                context.push('/categories');
              },
            );
          },
          loading: () => const ListTile(
            leading: CircularProgressIndicator(),
            title: Text('Loading...'),
          ),
          error: (error, stack) => ListTile(
            leading: const Icon(Icons.error_outline),
            title: Text('categories'.tr()),
            subtitle: Text('error_loading_categories'.tr()),
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const CategoriesPage(),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  SettingsSectionWidget _buildExportSection(
    BuildContext context,
    WidgetRef ref,
  ) {
    return SettingsSectionWidget(
      title: 'export'.tr(),
      icon: Icons.file_download,
      children: [
        ListTile(
          leading: const Icon(Icons.file_download),
          title: Text('export_transactions'.tr()),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            HapticFeedback.lightImpact();
            _exportTransactions(context, ref);
          },
        ),
        ListTile(
          leading: const Icon(Icons.download),
          title: Text('export_all'.tr()),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            HapticFeedback.lightImpact();
            _exportAll(context, ref);
          },
        ),
      ],
    );
  }

  Future<void> _exportTransactions(BuildContext context, WidgetRef ref) async {
    try {
      final exportService = ref.read(exportServiceProvider);
      final filePath = await exportService.exportTransactionsToCsv();

      if (!context.mounted) return;
      if (filePath != null) {
        ErrorSnackbar.showSuccess(context, 'exported_successfully'.tr());
      } else {
        ErrorSnackbar.show(context, 'export_failed'.tr());
      }
    } catch (e) {
      if (!context.mounted) return;
      ErrorSnackbar.show(context, 'export_failed'.tr());
    }
  }

  Future<void> _exportAll(BuildContext context, WidgetRef ref) async {
    try {
      final exportService = ref.read(exportServiceProvider);
      final results = await exportService.exportAll();

      if (!context.mounted) return;
      final transactionsPath = results['transactions'];
      final budgetsPath = results['budgets'];

      if (transactionsPath != null || budgetsPath != null) {
        ErrorSnackbar.showSuccess(context, 'exported_successfully'.tr());
      } else {
        ErrorSnackbar.show(context, 'export_failed'.tr());
      }
    } catch (e) {
      if (!context.mounted) return;
      ErrorSnackbar.show(context, 'export_failed'.tr());
    }
  }
}
