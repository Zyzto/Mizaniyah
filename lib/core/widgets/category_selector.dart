import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../features/categories/providers/category_providers.dart';
import '../utils/category_translations.dart';

/// A dropdown selector for choosing a category with icon and color display
class CategorySelector extends ConsumerWidget {
  final int? selectedCategoryId;
  final ValueChanged<int?>? onCategorySelected;
  final String? label;
  final String? hint;
  final String? Function(int?)? validator;
  final bool enabled;
  final bool showActiveOnly;

  const CategorySelector({
    super.key,
    this.selectedCategoryId,
    this.onCategorySelected,
    this.label,
    this.hint,
    this.validator,
    this.enabled = true,
    this.showActiveOnly = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = showActiveOnly
        ? ref.watch(activeCategoriesProvider)
        : ref.watch(categoriesProvider);

    return categoriesAsync.when(
      data: (categories) {
        if (categories.isEmpty) {
          return DropdownButtonFormField<int?>(
            initialValue: selectedCategoryId,
            decoration: InputDecoration(
              labelText: label ?? 'category'.tr(),
              hintText: hint ?? 'no_categories_available'.tr(),
              errorText: validator?.call(selectedCategoryId),
            ),
            items: const [],
            onChanged: null,
          );
        }

        return DropdownButtonFormField<int?>(
          initialValue: selectedCategoryId,
          decoration: InputDecoration(
            labelText: label ?? 'category'.tr(),
            hintText: hint ?? 'select_category'.tr(),
            errorText: validator?.call(selectedCategoryId),
          ),
          items: [
            DropdownMenuItem<int?>(value: null, child: Text('none'.tr())),
            ...categories.map((category) {
              return DropdownMenuItem<int?>(
                value: category.id,
                child: Row(
                  children: [
                    if (category.icon != null)
                      Icon(
                        _getIconData(category.icon!),
                        color: Color(category.color),
                        size: 20,
                      )
                    else
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: Color(category.color),
                          shape: BoxShape.circle,
                        ),
                      ),
                    const SizedBox(width: 8),
                    Text(CategoryTranslations.getTranslatedName(category)),
                  ],
                ),
              );
            }),
          ],
          onChanged: enabled ? onCategorySelected : null,
        );
      },
      loading: () => DropdownButtonFormField<int?>(
        initialValue: selectedCategoryId,
        decoration: InputDecoration(
          labelText: label ?? 'category'.tr(),
          hintText: 'loading_categories'.tr(),
        ),
        items: const [],
        onChanged: null,
      ),
      error: (error, stack) => DropdownButtonFormField<int?>(
        initialValue: selectedCategoryId,
        decoration: InputDecoration(
          labelText: label ?? 'category'.tr(),
          hintText: 'error_loading_categories'.tr(),
          errorText: 'error_loading_categories'.tr(),
        ),
        items: const [],
        onChanged: null,
      ),
    );
  }

  IconData? _getIconData(String iconName) {
    // Map common icon names to IconData
    // This is a simple mapping - you might want to use a more comprehensive solution
    switch (iconName.toLowerCase()) {
      case 'shopping_cart':
        return Icons.shopping_cart;
      case 'restaurant':
        return Icons.restaurant;
      case 'local_gas_station':
        return Icons.local_gas_station;
      case 'home':
        return Icons.home;
      case 'directions_car':
        return Icons.directions_car;
      case 'flight':
        return Icons.flight;
      case 'hotel':
        return Icons.hotel;
      case 'fitness_center':
        return Icons.fitness_center;
      case 'local_hospital':
        return Icons.local_hospital;
      case 'school':
        return Icons.school;
      default:
        return Icons.category;
    }
  }
}
