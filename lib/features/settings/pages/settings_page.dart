import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_settings_framework/flutter_settings_framework.dart'
    show SettingsPageScaffold, SettingsSectionWidget;
import '../providers/settings_framework_providers.dart';
import '../widgets/setting_tile_builder.dart';
import '../widgets/management_section.dart';
import '../widgets/export_section.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    try {
      // Use watch instead of read to ensure reactive updates
      final settings = ref.watch(mizaniyahSettingsProvider);

      // Build settings sections from registry
      final sections = settings.registry.sections.map((section) {
        final sectionSettings = settings.registry.settings
            .where((s) => s.section == section.key)
            .toList();

        // Build tiles for each setting in the section based on type
        final tiles = sectionSettings.map((settingDef) {
          return SettingTileBuilder.buildSettingTile(
            context,
            ref,
            settings,
            settingDef,
          );
        }).toList();

        return SettingsSectionWidget.fromDefinition(
          section: section,
          title: section.titleKey.tr(),
          children: tiles,
        );
      }).toList();

      // Add Management section with navigation tiles
      sections.add(ManagementSection.buildSection(context, ref));

      // Add Export section
      sections.add(ExportSection.buildSection(context, ref));

      return SettingsPageScaffold(title: 'settings'.tr(), sections: sections);
    } catch (e, stackTrace) {
      // If settings framework is not initialized, show error
      // Log the error for debugging
      debugPrint('Settings page error: $e');
      debugPrint('Stack trace: $stackTrace');

      return Scaffold(
        appBar: AppBar(title: Text('settings'.tr())),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
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
                const SizedBox(height: 8),
                Text(
                  'Please restart the app to initialize settings.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }
  }
}
