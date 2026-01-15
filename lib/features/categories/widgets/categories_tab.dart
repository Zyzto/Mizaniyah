import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import '../providers/category_providers.dart';
import '../../transactions/providers/transaction_providers.dart';
import '../../../core/database/app_database.dart' as db;
import '../widgets/category_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/loading_skeleton.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/navigation/route_paths.dart';

/// Categories tab widget for use in BudgetsPage (without Scaffold)
class CategoriesTab extends ConsumerStatefulWidget {
  const CategoriesTab({super.key});

  @override
  ConsumerState<CategoriesTab> createState() => _CategoriesTabState();
}

class _CategoriesTabState extends ConsumerState<CategoriesTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  bool _isEditMode = false;
  final Set<int> _selectedCategoryIds = <int>{};

  void _toggleEditMode() {
    setState(() {
      _isEditMode = !_isEditMode;
      if (!_isEditMode) {
        _selectedCategoryIds.clear();
      }
    });
    HapticFeedback.mediumImpact();
  }

  void _toggleSelection(int categoryId) {
    setState(() {
      if (_selectedCategoryIds.contains(categoryId)) {
        _selectedCategoryIds.remove(categoryId);
      } else {
        _selectedCategoryIds.add(categoryId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    final categoriesAsync = ref.watch(categoriesProvider);
    final transactionsAsync = ref.watch(transactionsProvider);

    return categoriesAsync.when(
      data: (categories) {
        if (categories.isEmpty) {
          return EmptyState(
            icon: Icons.category_outlined,
            title: 'no_categories'.tr(),
            subtitle: 'create_first_category'.tr(),
            actionLabel: 'add_category_action'.tr(),
            onAction: () => _navigateToAdd(context),
          );
        }

        return transactionsAsync.when(
          data: (transactions) {
            final theme = Theme.of(context);
            // Group categories by predefined vs custom
            final predefined = categories.where((c) => c.isPredefined).toList();
            final custom = categories.where((c) => !c.isPredefined).toList();

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (predefined.isNotEmpty) ...[
                  Text(
                    'predefined'.tr(),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...predefined.map((category) {
                    final transactionCount = transactions
                        .where((t) => t.categoryId == category.id)
                        .length;
                    return GestureDetector(
                      onLongPress: _toggleEditMode,
                      child: CategoryCard(
                        category: category,
                        transactionCount: transactionCount,
                        onTap: () => _navigateToEdit(context, category),
                        isEditMode: _isEditMode,
                        isSelected: _selectedCategoryIds.contains(category.id),
                        onSelectionChanged: (selected) =>
                            _toggleSelection(category.id),
                      ),
                    );
                  }),
                  const SizedBox(height: 24),
                ],
                if (custom.isNotEmpty) ...[
                  Text(
                    'custom'.tr(),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...custom.map((category) {
                    final transactionCount = transactions
                        .where((t) => t.categoryId == category.id)
                        .length;
                    return GestureDetector(
                      onLongPress: _toggleEditMode,
                      child: CategoryCard(
                        category: category,
                        transactionCount: transactionCount,
                        onTap: () => _navigateToEdit(context, category),
                        isEditMode: _isEditMode,
                        isSelected: _selectedCategoryIds.contains(category.id),
                        onSelectionChanged: (selected) =>
                            _toggleSelection(category.id),
                      ),
                    );
                  }),
                ],
              ],
            );
          },
          loading: () => const SkeletonList(itemCount: 5, itemHeight: 80),
          error: (error, stack) => ErrorState(
            title: 'error_loading_transactions'.tr(),
            message: error.toString(),
            onRetry: () => ref.invalidate(transactionsProvider),
          ),
        );
      },
      loading: () => const SkeletonList(itemCount: 5, itemHeight: 80),
      error: (error, stack) => ErrorState(
        title: 'error_loading_categories'.tr(),
        message: error.toString(),
        onRetry: () => ref.invalidate(categoriesProvider),
      ),
    );
  }

  void _navigateToAdd(BuildContext context) {
    context.push(RoutePaths.categoriesAdd);
  }

  void _navigateToEdit(BuildContext context, db.Category category) {
    HapticFeedback.lightImpact();
    context.push(RoutePaths.categoryEdit(category.id));
  }
}
