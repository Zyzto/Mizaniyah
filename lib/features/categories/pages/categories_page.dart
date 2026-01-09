import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import '../providers/category_providers.dart';
import '../../transactions/providers/transaction_providers.dart';
import '../../../core/database/app_database.dart' as db;
import '../widgets/category_card.dart';
import 'category_form_page.dart';
import '../../../core/widgets/error_snackbar.dart';

class CategoriesPage extends ConsumerWidget {
  const CategoriesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final transactionsAsync = ref.watch(transactionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Categories'),
        automaticallyImplyLeading: false,
      ),
      body: categoriesAsync.when(
        data: (categories) {
          if (categories.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.category_outlined,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No categories yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Create your first category to organize transactions',
                    style: TextStyle(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return transactionsAsync.when(
            data: (transactions) {
              // Group categories by predefined vs custom
              final predefined = categories
                  .where((c) => c.isPredefined)
                  .toList();
              final custom = categories.where((c) => !c.isPredefined).toList();

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (predefined.isNotEmpty) ...[
                    const Text(
                      'Predefined',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...predefined.map((category) {
                      final transactionCount = transactions
                          .where((t) => t.categoryId == category.id)
                          .length;
                      return CategoryCard(
                        category: category,
                        transactionCount: transactionCount,
                        onTap: () => _navigateToEdit(context, category),
                        onToggleActive: (value) =>
                            _toggleActive(ref, category, value),
                        onDelete: () => _deleteCategory(context, ref, category),
                      );
                    }),
                    const SizedBox(height: 24),
                  ],
                  if (custom.isNotEmpty) ...[
                    const Text(
                      'Custom',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...custom.map((category) {
                      final transactionCount = transactions
                          .where((t) => t.categoryId == category.id)
                          .length;
                      return CategoryCard(
                        category: category,
                        transactionCount: transactionCount,
                        onTap: () => _navigateToEdit(context, category),
                        onToggleActive: (value) =>
                            _toggleActive(ref, category, value),
                        onDelete: () => _deleteCategory(context, ref, category),
                      );
                    }),
                  ],
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) =>
                Center(child: Text('Error loading transactions: $error')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToAdd(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _navigateToAdd(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const CategoryFormPage()));
  }

  void _navigateToEdit(BuildContext context, db.Category category) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CategoryFormPage(category: category),
      ),
    );
  }

  Future<void> _toggleActive(
    WidgetRef ref,
    db.Category category,
    bool value,
  ) async {
    try {
      final repository = ref.read(categoryRepositoryProvider);
      await repository.updateCategory(
        db.CategoriesCompanion(
          id: drift.Value(category.id),
          isActive: drift.Value(value),
        ),
      );
    } catch (e) {
      // Error handling is done by the repository
    }
  }

  Future<void> _deleteCategory(
    BuildContext context,
    WidgetRef ref,
    db.Category category,
  ) async {
    // Check if category is used in transactions
    final transactions = await ref.read(transactionsProvider.future);
    final isUsed = transactions.any((t) => t.categoryId == category.id);

    if (isUsed) {
      if (context.mounted) {
        ErrorSnackbar.show(
          context,
          'Cannot delete category that is used in transactions',
        );
      }
      return;
    }

    // Confirm deletion - check context before async operation
    if (!context.mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Category'),
        content: Text('Are you sure you want to delete "${category.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        final repository = ref.read(categoryRepositoryProvider);
        await repository.deleteCategory(category.id);
        if (context.mounted) {
          ErrorSnackbar.showSuccess(context, 'Category deleted');
        }
      } catch (e) {
        if (context.mounted) {
          ErrorSnackbar.show(context, 'Failed to delete category: $e');
        }
      }
    }
  }
}
