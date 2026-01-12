import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../transactions/providers/transaction_providers.dart';
import '../../budgets/providers/budget_providers.dart';
import '../../categories/providers/category_providers.dart';
import '../../../core/database/app_database.dart' as db;
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/category_translations.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/loading_skeleton.dart';

class StatisticsPage extends ConsumerWidget {
  const StatisticsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(transactionsProvider);
    final budgetsAsync = ref.watch(activeBudgetsProvider);
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(title: Text('statistics'.tr())),
      body: transactionsAsync.when(
        data: (transactions) {
          return categoriesAsync.when(
            data: (categories) {
              return budgetsAsync.when(
                data: (budgets) {
                  return _StatisticsContent(
                    transactions: transactions,
                    categories: categories,
                    budgets: budgets,
                  );
                },
                loading: () => const SkeletonList(itemCount: 3, itemHeight: 120),
                error: (error, stack) => ErrorState(
                  title: 'error_loading_budgets'.tr(),
                  message: error.toString(),
                  onRetry: () => ref.invalidate(activeBudgetsProvider),
                ),
              );
            },
            loading: () => const SkeletonList(itemCount: 3, itemHeight: 120),
            error: (error, stack) => ErrorState(
              title: 'error_loading_categories'.tr(),
              message: error.toString(),
              onRetry: () => ref.invalidate(categoriesProvider),
            ),
          );
        },
        loading: () => const SkeletonList(itemCount: 3, itemHeight: 120),
        error: (error, stack) => ErrorState(
          title: 'error_loading_transactions'.tr(),
          message: error.toString(),
          onRetry: () => ref.invalidate(transactionsProvider),
        ),
      ),
    );
  }
}

class _StatisticsContent extends StatelessWidget {
  final List<db.Transaction> transactions;
  final List<db.Category> categories;
  final List<db.Budget> budgets;

  const _StatisticsContent({
    required this.transactions,
    required this.categories,
    required this.budgets,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final thisMonthStart = DateTime(now.year, now.month, 1);
    final thisMonthEnd = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

    // Filter transactions for this month (optimized - single pass)
    final thisMonthTransactions = transactions
        .where(
          (t) =>
              t.date.isAfter(thisMonthStart) && t.date.isBefore(thisMonthEnd),
        )
        .toList();

    // Calculate total spent this month (optimized - single fold)
    final totalSpent = thisMonthTransactions.fold<double>(
      0.0,
      (sum, t) => sum + t.amount,
    );

    // Calculate spending by category (optimized - single pass)
    final spendingByCategory = <int, double>{};
    final categoryMap = {for (var cat in categories) cat.id: cat};

    for (final transaction in thisMonthTransactions) {
      final categoryId = transaction.categoryId;
      if (categoryId != null) {
        spendingByCategory[categoryId] =
            (spendingByCategory[categoryId] ?? 0.0) + transaction.amount;
      }
    }

    // Calculate budget vs actual
    final budgetVsActual = <int, Map<String, double>>{};
    for (final budget in budgets) {
      final spent = spendingByCategory[budget.categoryId] ?? 0.0;
      budgetVsActual[budget.categoryId] = {
        'budget': budget.amount,
        'spent': spent,
        'remaining': budget.amount - spent,
      };
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _SummaryCard(
          totalSpent: totalSpent,
          transactionCount: thisMonthTransactions.length,
        ),
        const SizedBox(height: 16),
        _SpendingByCategoryCard(
          spendingByCategory: spendingByCategory,
          categoryMap: categoryMap,
          totalSpent: totalSpent,
        ),
        if (budgetVsActual.isNotEmpty) ...[
          const SizedBox(height: 16),
          _BudgetVsActualCard(
            budgetVsActual: budgetVsActual,
            categoryMap: categoryMap,
          ),
        ],
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final double totalSpent;
  final int transactionCount;

  const _SummaryCard({
    required this.totalSpent,
    required this.transactionCount,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'this_month_summary'.tr(),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatItem(
                  label: 'total_spent'.tr(),
                  value: CurrencyFormatter.formatCompact(totalSpent),
                  icon: Icons.payments,
                ),
                _StatItem(
                  label: 'transactions'.tr(),
                  value: transactionCount.toString(),
                  icon: Icons.receipt,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SpendingByCategoryCard extends StatelessWidget {
  final Map<int, double> spendingByCategory;
  final Map<int, db.Category> categoryMap;
  final double totalSpent;

  const _SpendingByCategoryCard({
    required this.spendingByCategory,
    required this.categoryMap,
    required this.totalSpent,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'spending_by_category'.tr(),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            if (spendingByCategory.isEmpty)
              Text('no_spending_data'.tr())
            else
              ...spendingByCategory.entries.map((entry) {
                final category = categoryMap[entry.key];
                final amount = entry.value;
                final percentage = totalSpent > 0
                    ? (amount / totalSpent * 100)
                    : 0.0;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            category != null
                                ? CategoryTranslations.getTranslatedName(category)
                                : 'unknown_category'.tr(),
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          Text(
                            '${CurrencyFormatter.formatCompact(amount)} (${percentage.toStringAsFixed(1)}%)',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: percentage / 100,
                        minHeight: 8,
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}

class _BudgetVsActualCard extends StatelessWidget {
  final Map<int, Map<String, double>> budgetVsActual;
  final Map<int, db.Category> categoryMap;

  const _BudgetVsActualCard({
    required this.budgetVsActual,
    required this.categoryMap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'budget_vs_actual'.tr(),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            ...budgetVsActual.entries.map((entry) {
              final category = categoryMap[entry.key];
              final budgetData = entry.value;
              final budget = budgetData['budget'] ?? 0.0;
              final spent = budgetData['spent'] ?? 0.0;
              final remaining = budgetData['remaining'] ?? 0.0;
              final percentage = budget > 0 ? (spent / budget * 100) : 0.0;
              final colorScheme = Theme.of(context).colorScheme;
              final color = percentage >= 100
                  ? colorScheme.error
                  : percentage >= 80
                      ? colorScheme.tertiary
                      : colorScheme.primary;

              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category != null
                          ? CategoryTranslations.getTranslatedName(category)
                          : 'unknown_category'.tr(),
                      style: Theme.of(context).textTheme.bodyLarge
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${'budget'.tr()}: ${CurrencyFormatter.formatCompact(budget)}',
                        ),
                        Text(
                          '${'spent'.tr()}: ${CurrencyFormatter.formatCompact(spent)}',
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: color.withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            remaining >= 0
                                ? '${CurrencyFormatter.formatCompact(remaining)} ${'remaining'.tr()}'
                                : '${CurrencyFormatter.formatCompact(-remaining)} ${'over'.tr()}',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: color,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: (percentage / 100).clamp(0.0, 1.0),
                      backgroundColor: color.withValues(alpha: 0.2),
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                      minHeight: 8,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${percentage.toStringAsFixed(0)}% ${'used'.tr()}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
