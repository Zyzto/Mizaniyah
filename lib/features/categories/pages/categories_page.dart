import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:drift/drift.dart' as drift;
import 'package:easy_localization/easy_localization.dart';
import '../providers/category_providers.dart';
import '../../transactions/providers/transaction_providers.dart';
import '../../../core/database/app_database.dart' as db;
import '../../../core/database/providers/dao_providers.dart';
import '../widgets/category_card.dart';
import '../../../core/widgets/error_snackbar.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/loading_skeleton.dart';
import '../../../core/widgets/error_state.dart';

class CategoriesPage extends ConsumerStatefulWidget {
  const CategoriesPage({super.key});

  @override
  ConsumerState<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends ConsumerState<CategoriesPage> {
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

  void _selectAll(List<db.Category> categories) {
    setState(() {
      if (_selectedCategoryIds.length == categories.length) {
        _selectedCategoryIds.clear();
      } else {
        _selectedCategoryIds.addAll(categories.map((c) => c.id));
      }
    });
    HapticFeedback.mediumImpact();
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final transactionsAsync = ref.watch(transactionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: _isEditMode
            ? Text(
                _selectedCategoryIds.isEmpty
                    ? 'select_items'.tr()
                    : 'selected_count'.tr(
                        args: [_selectedCategoryIds.length.toString()],
                      ),
              )
            : Text('categories'.tr()),
        automaticallyImplyLeading: false,
        actions: _isEditMode
            ? [
                IconButton(
                  icon: const Icon(Icons.select_all),
                  tooltip: 'select_all'.tr(),
                  onPressed: () {
                    categoriesAsync.whenData((categories) {
                      _selectAll(categories);
                    });
                  },
                ),
                if (_selectedCategoryIds.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    tooltip: 'delete_selected'.tr(),
                    onPressed: () => _bulkDelete(context, ref),
                  ),
                IconButton(
                  icon: const Icon(Icons.close),
                  tooltip: 'cancel'.tr(),
                  onPressed: _toggleEditMode,
                ),
              ]
            : [],
      ),
      body: categoriesAsync.when(
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
              final predefined = categories
                  .where((c) => c.isPredefined)
                  .toList();
              final custom = categories.where((c) => !c.isPredefined).toList();

              // Sort custom categories by sortOrder, then by createdAt
              custom.sort((a, b) {
                final orderCompare = a.sortOrder.compareTo(b.sortOrder);
                if (orderCompare != 0) return orderCompare;
                return a.createdAt.compareTo(b.createdAt);
              });

              return _isEditMode
                  ? _buildReorderableList(
                      context,
                      ref,
                      transactions,
                      custom,
                      theme,
                    )
                  : ListView(
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
                                isSelected: _selectedCategoryIds.contains(
                                  category.id,
                                ),
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
                                isSelected: _selectedCategoryIds.contains(
                                  category.id,
                                ),
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
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          HapticFeedback.lightImpact();
          _navigateToAdd(context);
        },
        tooltip: 'add_category_action'.tr(),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _navigateToAdd(BuildContext context) {
    context.push('/categories/add');
  }

  void _navigateToEdit(BuildContext context, db.Category category) {
    HapticFeedback.lightImpact();
    context.push('/categories/${category.id}/edit');
  }

  Widget _buildReorderableList(
    BuildContext context,
    WidgetRef ref,
    List<db.Transaction> transactions,
    List<db.Category> customCategories,
    ThemeData theme,
  ) {
    return ReorderableListView(
      padding: const EdgeInsets.all(16),
      onReorder: (oldIndex, newIndex) {
        if (newIndex > oldIndex) {
          newIndex -= 1;
        }
        setState(() {
          final item = customCategories.removeAt(oldIndex);
          customCategories.insert(newIndex, item);
        });
        _updateCategoryOrder(ref, customCategories);
      },
      children: [
        if (customCategories.isNotEmpty) ...[
          Text(
            'custom'.tr(),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            key: const ValueKey('custom_header'),
          ),
          const SizedBox(height: 16, key: ValueKey('custom_spacer')),
          ...customCategories.map((category) {
            final transactionCount = transactions
                .where((t) => t.categoryId == category.id)
                .length;
            return CategoryCard(
              key: ValueKey(category.id),
              category: category,
              transactionCount: transactionCount,
              isEditMode: true,
              isSelected: _selectedCategoryIds.contains(category.id),
              onSelectionChanged: (selected) => _toggleSelection(category.id),
            );
          }),
        ],
      ],
    );
  }

  Future<void> _updateCategoryOrder(
    WidgetRef ref,
    List<db.Category> categories,
  ) async {
    try {
      final dao = ref.read(categoryDaoProvider);
      for (int i = 0; i < categories.length; i++) {
        final category = categories[i];
        await dao.updateCategory(
          db.CategoriesCompanion(
            id: drift.Value(category.id),
            sortOrder: drift.Value(i),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ErrorSnackbar.show(context, 'failed_to_update_order'.tr());
      }
    }
  }

  Future<void> _bulkDelete(BuildContext context, WidgetRef ref) async {
    if (_selectedCategoryIds.isEmpty) return;

    // Check if any selected categories are used in transactions
    final transactions = await ref.read(transactionsProvider.future);
    final usedCategories = _selectedCategoryIds
        .where((id) => transactions.any((t) => t.categoryId == id))
        .toList();

    if (usedCategories.isNotEmpty) {
      if (context.mounted) {
        HapticFeedback.mediumImpact();
        ErrorSnackbar.show(context, 'category_in_use'.tr());
      }
      return;
    }

    // Confirm deletion
    if (!context.mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        return AlertDialog(
          title: Text('delete_selected'.tr()),
          content: Text(
            'delete_categories_confirmation'.tr(
              args: [_selectedCategoryIds.length.toString()],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                Navigator.of(context).pop(false);
              },
              child: Text('cancel'.tr()),
            ),
            TextButton(
              onPressed: () {
                HapticFeedback.mediumImpact();
                Navigator.of(context).pop(true);
              },
              style: TextButton.styleFrom(
                foregroundColor: theme.colorScheme.error,
              ),
              child: Text('delete'.tr()),
            ),
          ],
        );
      },
    );

    if (confirmed == true && context.mounted) {
      try {
        final dao = ref.read(categoryDaoProvider);
        int deletedCount = 0;
        for (final id in _selectedCategoryIds) {
          await dao.deleteCategory(id);
          deletedCount++;
        }
        setState(() {
          _selectedCategoryIds.clear();
          _isEditMode = false;
        });
        if (context.mounted) {
          HapticFeedback.heavyImpact();
          ErrorSnackbar.showSuccess(
            context,
            'categories_deleted'.tr(args: [deletedCount.toString()]),
          );
        }
      } catch (e) {
        if (context.mounted) {
          HapticFeedback.heavyImpact();
          ErrorSnackbar.show(
            context,
            'category_delete_failed'.tr(args: [e.toString()]),
          );
        }
      }
    }
  }
}
