import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_settings_framework/flutter_settings_framework.dart'
    show SettingsSectionWidget;
import '../../categories/pages/categories_page.dart';
import '../../categories/providers/category_providers.dart';

/// Management section widget for settings page
class ManagementSection {
  const ManagementSection._();

  static SettingsSectionWidget buildSection(BuildContext context, WidgetRef ref) {
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
                MaterialPageRoute(builder: (context) => const CategoriesPage()),
              );
            },
          ),
        ),
      ],
    );
  }
}
