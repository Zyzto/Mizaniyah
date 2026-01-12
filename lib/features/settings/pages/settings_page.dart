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
import '../widgets/theme_color_picker.dart'
    show ThemeColorPickerDialog, ThemeColorPalette;
import '../../categories/pages/categories_page.dart';
import '../../categories/providers/category_providers.dart';
import '../../../core/services/providers/export_providers.dart';
import '../../../core/widgets/error_snackbar.dart';

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
    } catch (e, stackTrace) {
      // If settings framework is not initialized, show error
      // Log the error for debugging
      debugPrint('Settings page error: $e');
      debugPrint('Stack trace: $stackTrace');
      
      return Scaffold(
        appBar: AppBar(
          title: Text('settings'.tr()),
        ),
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

  /// Get helper text key for a setting
  String _getHelperTextKey(SettingDefinition settingDef) {
    return '${settingDef.key}_helper';
  }

  /// Build helper text widget if available
  Widget? _buildHelperText(BuildContext context, SettingDefinition settingDef) {
    final helperKey = _getHelperTextKey(settingDef);
    try {
      final helperText = helperKey.tr();
      // Check if translation exists (if tr() returns the key, translation doesn't exist)
      if (helperText != helperKey && helperText.isNotEmpty) {
        return Padding(
          padding: const EdgeInsets.only(left: 16, right: 16, top: 4, bottom: 8),
          child: Text(
            helperText,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        );
      }
    } catch (e) {
      // Translation key doesn't exist, skip helper text
    }
    return null;
  }

  /// Get color name from color value
  String _getColorName(int colorValue) {
    final colorOption = ThemeColorPalette.getColorByValue(colorValue);
    if (colorOption != null) {
      return colorOption.name;
    }
    return 'custom_color'.tr();
  }


  Widget _buildSettingTile(
    BuildContext context,
    WidgetRef ref,
    SettingsProviders settings,
    SettingDefinition settingDef,
  ) {
    final currentValue = ref.watch(settings.provider(settingDef));
    final helperText = _buildHelperText(context, settingDef);

    // Build appropriate tile based on setting type
    Widget tile;
    if (settingDef is BoolSetting) {
      tile = SwitchSettingsTile.fromSetting(
        setting: settingDef,
        title: settingDef.titleKey.tr(),
        value: currentValue as bool,
        onChanged: (value) {
          HapticFeedback.lightImpact();
          ref.read(settings.provider(settingDef).notifier).set(value);
        },
      );
    } else if (settingDef is EnumSetting) {
      final options = settingDef.options ?? [];
      // Use ModalBottomSheet for all enum settings for consistent UX
      final currentValueStr = currentValue as String;
      final currentLabelKey = settingDef.optionLabels?[currentValueStr] ?? currentValueStr;
      tile = ListTile(
        leading: settingDef.icon != null ? Icon(settingDef.icon) : null,
        title: Text(settingDef.titleKey.tr()),
        subtitle: Text(currentLabelKey.tr()),
        trailing: Icon(
          Icons.chevron_right_rounded,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        onTap: () {
          HapticFeedback.lightImpact();
          showModalBottomSheet<String>(
            context: context,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            builder: (sheetContext) {
              return SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        settingDef.titleKey.tr(),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const Divider(height: 1),
                    ...options.map((option) {
                      final labelKey = settingDef.optionLabels?[option] ?? option;
                      final isSelected = option == currentValueStr;
                      return ListTile(
                        leading: isSelected
                            ? Icon(
                                Icons.check_circle,
                                color: Theme.of(context).colorScheme.primary,
                              )
                            : const SizedBox(width: 24),
                        title: Text(labelKey.tr()),
                        onTap: () {
                          Navigator.of(sheetContext).pop(option);
                        },
                      );
                    }),
                    const SizedBox(height: 8),
                  ],
                ),
              );
            },
          ).then((value) {
            if (value != null && context.mounted) {
              ref.read(settings.provider(settingDef).notifier).set(value);
            }
          });
        },
      );
    } else if (settingDef is DoubleSetting) {
      final min = settingDef.min ?? 0.0;
      final max = settingDef.max ?? 100.0;
      final step = settingDef.step;
      tile = SliderSettingsTile(
        leading: settingDef.icon != null ? Icon(settingDef.icon) : null,
        title: Text(settingDef.titleKey.tr()),
        value: currentValue,
        min: min,
        max: max,
        divisions: step > 0 ? ((max - min) / step).round() : null,
        onChanged: (value) {
          HapticFeedback.lightImpact();
          ref.read(settings.provider(settingDef).notifier).set(value);
        },
      );
    } else if (settingDef is ColorSetting) {
      // Custom theme color picker for better UX
      if (settingDef.key == 'theme_color') {
        final currentColor = Color(currentValue);
        final colorName = _getColorName(currentValue);
        final isCustom = !ThemeColorPalette.isPredefinedColor(currentValue);

        tile = ListTile(
          leading: settingDef.icon != null
              ? Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .primaryContainer
                        .withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    settingDef.icon,
                    size: 20,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                )
              : null,
          title: Text(settingDef.titleKey.tr()),
          subtitle: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: currentColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline,
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: currentColor.withValues(alpha: 0.3),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      colorName,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                    if (isCustom)
                      Text(
                        '#${currentValue.toRadixString(16).substring(2).toUpperCase()}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                              fontFamily: 'monospace',
                            ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          trailing: Icon(
            Icons.chevron_right_rounded,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          onTap: () {
            HapticFeedback.lightImpact();
            showDialog(
              context: context,
              builder: (dialogContext) => ThemeColorPickerDialog(
                currentValue: currentValue,
                onColorSelected: (value) {
                  ref.read(settings.provider(settingDef).notifier).set(value);
                },
              ),
            );
          },
        );
      } else {
        // Fallback to default ColorSettingsTile for other color settings
        tile = ColorSettingsTile.fromSetting(
          setting: settingDef,
          title: settingDef.titleKey.tr(),
          value: currentValue,
          onChanged: (value) {
            HapticFeedback.lightImpact();
            ref.read(settings.provider(settingDef).notifier).set(value);
          },
        );
      }
    } else if (settingDef is StringSetting) {
      // String settings are not used anymore (defaultCurrency converted to EnumSetting)
      // Fallback implementation
      tile = ListTile(
        leading: settingDef.icon != null ? Icon(settingDef.icon) : null,
        title: Text(settingDef.titleKey.tr()),
        subtitle: Text(currentValue),
        onTap: () {
          HapticFeedback.lightImpact();
        },
      );
    } else {
      // Fallback for unknown setting types
      tile = ListTile(
        leading: settingDef.icon != null ? Icon(settingDef.icon) : null,
        title: Text(settingDef.titleKey.tr()),
        subtitle: const Text('Unsupported setting type'),
      );
    }

    // Wrap tile with helper text if available
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        tile,
        if (helperText != null) helperText,
      ],
    );
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
