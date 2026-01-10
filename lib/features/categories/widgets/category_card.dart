import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/database/app_database.dart' as db;
import '../../../core/utils/icon_utils.dart';

class CategoryCard extends StatelessWidget {
  final db.Category category;
  final int transactionCount;
  final VoidCallback? onTap;
  final ValueChanged<bool>? onToggleActive;
  final VoidCallback? onDelete;
  final bool isEditMode;
  final bool isSelected;
  final ValueChanged<bool>? onSelectionChanged;

  const CategoryCard({
    super.key,
    required this.category,
    required this.transactionCount,
    this.onTap,
    this.onToggleActive,
    this.onDelete,
    this.isEditMode = false,
    this.isSelected = false,
    this.onSelectionChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final iconData = category.icon != null
        ? IconUtils.getIconData(category.icon!)
        : Icons.category;
    final color = Color(category.color);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: isSelected ? colorScheme.primaryContainer : null,
      child: ListTile(
        leading: isEditMode
            ? Checkbox(
                value: isSelected,
                onChanged: onSelectionChanged != null
                    ? (value) {
                        HapticFeedback.selectionClick();
                        onSelectionChanged?.call(value ?? false);
                      }
                    : null,
              )
            : CircleAvatar(
                backgroundColor: color.withValues(alpha: 0.2),
                child: Icon(iconData, color: color),
              ),
        title: Text(category.name),
        subtitle: Text(
          transactionCount == 1
              ? 'one_transaction'.tr()
              : 'transactions_count'.tr(args: [transactionCount.toString()]),
        ),
        trailing: isEditMode
            ? const Icon(Icons.drag_handle)
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (onToggleActive != null)
                    Switch(
                      value: category.isActive,
                      onChanged: (value) {
                        HapticFeedback.lightImpact();
                        onToggleActive?.call(value);
                      },
                    ),
                ],
              ),
        onTap: isEditMode
            ? null
            : () {
                HapticFeedback.lightImpact();
                onTap?.call();
              },
        onLongPress: isEditMode
            ? null
            : () {
                HapticFeedback.mediumImpact();
                // Long press handled by parent
              },
      ),
    );
  }
}
