import 'package:flutter/material.dart';
import '../../../core/database/app_database.dart' as db;
import '../../../core/utils/icon_utils.dart';

class CategoryCard extends StatelessWidget {
  final db.Category category;
  final int transactionCount;
  final VoidCallback? onTap;
  final ValueChanged<bool>? onToggleActive;
  final VoidCallback? onDelete;

  const CategoryCard({
    super.key,
    required this.category,
    required this.transactionCount,
    this.onTap,
    this.onToggleActive,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final iconData = category.icon != null
        ? IconUtils.getIconData(category.icon!)
        : Icons.category;
    final color = Color(category.color);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.2),
          child: Icon(iconData, color: color),
        ),
        title: Text(category.name),
        subtitle: Text(
          '$transactionCount transaction${transactionCount != 1 ? 's' : ''}',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (onToggleActive != null)
              Switch(value: category.isActive, onChanged: onToggleActive),
            if (onDelete != null)
              IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: onDelete,
                color: Colors.red,
              ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}
