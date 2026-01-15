import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_settings_framework/flutter_settings_framework.dart'
    show
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
import '../widgets/theme_color_picker.dart'
    show ThemeColorPickerDialog, ThemeColorPalette;

/// Helper class for building setting tiles
class SettingTileBuilder {
  /// Get helper text key for a setting
  static String getHelperTextKey(SettingDefinition settingDef) {
    return '${settingDef.key}_helper';
  }

  /// Build helper text widget if available
  static Widget? buildHelperText(
    BuildContext context,
    SettingDefinition settingDef,
  ) {
    final helperKey = getHelperTextKey(settingDef);
    try {
      final helperText = helperKey.tr();
      // Check if translation exists (if tr() returns the key, translation doesn't exist)
      if (helperText != helperKey && helperText.isNotEmpty) {
        return Padding(
          padding: const EdgeInsets.only(
            left: 16,
            right: 16,
            top: 4,
            bottom: 8,
          ),
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
  static String getColorName(int colorValue) {
    final colorOption = ThemeColorPalette.getColorByValue(colorValue);
    if (colorOption != null) {
      return colorOption.name;
    }
    return 'custom_color'.tr();
  }

  /// Build setting tile widget
  static Widget buildSettingTile(
    BuildContext context,
    WidgetRef ref,
    SettingsProviders settings,
    SettingDefinition settingDef,
  ) {
    final currentValue = ref.watch(settings.provider(settingDef));
    final helperText = buildHelperText(context, settingDef);

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
      tile = _buildEnumSettingTile(
        context,
        ref,
        settings,
        settingDef,
        currentValue as String,
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
      tile = _buildColorSettingTile(
        context,
        ref,
        settings,
        settingDef,
        currentValue,
      );
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
      children: [tile, if (helperText != null) helperText],
    );
  }

  static Widget _buildEnumSettingTile(
    BuildContext context,
    WidgetRef ref,
    SettingsProviders settings,
    EnumSetting settingDef,
    String currentValueStr,
  ) {
    final options = settingDef.options ?? [];
    final currentLabelKey =
        settingDef.optionLabels?[currentValueStr] ?? currentValueStr;
    return ListTile(
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
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.8,
                ),
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
                    Flexible(
                      child: Scrollbar(
                        thumbVisibility: true,
                        thickness: 4.0,
                        radius: const Radius.circular(2),
                        child: ListView(
                          shrinkWrap: true,
                          children: [
                            ...options.map((option) {
                              final labelKey =
                                  settingDef.optionLabels?[option] ?? option;
                              final isSelected = option == currentValueStr;
                              return ListTile(
                                leading: isSelected
                                    ? Icon(
                                        Icons.check_circle,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.primary,
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
                      ),
                    ),
                  ],
                ),
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
  }

  static Widget _buildColorSettingTile(
    BuildContext context,
    WidgetRef ref,
    SettingsProviders settings,
    ColorSetting settingDef,
    int currentValue,
  ) {
    // Custom theme color picker for better UX
    if (settingDef.key == 'theme_color') {
      final currentColor = Color(currentValue);
      final colorName = getColorName(currentValue);
      final isCustom = !ThemeColorPalette.isPredefinedColor(currentValue);

      return ListTile(
        leading: settingDef.icon != null
            ? Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.primaryContainer.withValues(alpha: 0.3),
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
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
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
      return ColorSettingsTile.fromSetting(
        setting: settingDef,
        title: settingDef.titleKey.tr(),
        value: currentValue,
        onChanged: (value) {
          HapticFeedback.lightImpact();
          ref.read(settings.provider(settingDef).notifier).set(value);
        },
      );
    }
  }
}
