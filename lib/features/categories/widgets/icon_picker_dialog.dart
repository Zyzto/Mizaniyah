import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/utils/icon_utils.dart';

class IconPickerDialog extends StatelessWidget {
  final String? selectedIconName;
  final ValueChanged<String?> onIconSelected;

  const IconPickerDialog({
    super.key,
    this.selectedIconName,
    required this.onIconSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxHeight: 500),
        child: Column(
          children: [
            AppBar(
              title: Text('select_icon'.tr()),
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  icon: const Icon(Icons.close),
                  tooltip: 'close'.tr(),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: IconUtils.commonIcons.length + 1, // +1 for "None"
                itemBuilder: (context, index) {
                  if (index == 0) {
                    // "None" option
                    final isSelected = selectedIconName == null;
                    return InkWell(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        onIconSelected(null);
                        Navigator.of(context).pop();
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: isSelected
                                ? colorScheme.primary
                                : colorScheme.outline,
                            width: isSelected ? 2 : 1,
                          ),
                          borderRadius: BorderRadius.circular(8),
                          color: isSelected
                              ? colorScheme.primaryContainer
                              : null,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.block,
                              size: 32,
                              color: isSelected
                                  ? colorScheme.onPrimaryContainer
                                  : colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'none'.tr(),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: isSelected
                                    ? colorScheme.onPrimaryContainer
                                    : colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final icon = IconUtils.commonIcons[index - 1];
                  final iconName = IconUtils.getIconName(icon);
                  final isSelected = selectedIconName == iconName;

                  return InkWell(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      onIconSelected(iconName);
                      Navigator.of(context).pop();
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isSelected
                              ? colorScheme.primary
                              : colorScheme.outline,
                          width: isSelected ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(8),
                        color: isSelected ? colorScheme.primaryContainer : null,
                      ),
                      child: Icon(
                        icon,
                        size: 32,
                        color: isSelected
                            ? colorScheme.onPrimaryContainer
                            : colorScheme.onSurface,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
