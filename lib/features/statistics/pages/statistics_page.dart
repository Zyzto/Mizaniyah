import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../transactions/providers/transaction_providers.dart';
import '../../budgets/providers/budget_providers.dart';
import '../../categories/providers/category_providers.dart';
import '../../../core/database/app_database.dart' as db;

class StatisticsPage extends ConsumerWidget {
  const StatisticsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(transactionsProvider);
    final budgetsAsync = ref.watch(activeBudgetsProvider);
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Statistics')),
      body: transactionsAsync.when(
        data: (transactions) {
          return categoriesAsync.when(
            data: (categories) {
              return budgetsAsync.when(
                data: (budgets) {
                  return _buildStatisticsContent(
                    context,
                    transactions,
                    categories,
                    budgets,
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) =>
                    const Center(child: Text('Error loading budgets')),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) =>
                const Center(child: Text('Error loading categories')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) =>
            const Center(child: Text('Error loading transactions')),
      ),
    );
  }

  Widget _buildStatisticsContent(
    BuildContext context,
    List<db.Transaction> transactions,
    List<db.Category> categories,
    List<db.Budget> budgets,
  ) {
    final now = DateTime.now();
    final thisMonthStart = DateTime(now.year, now.month, 1);
    final thisMonthEnd = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

    // Filter transactions for this month
    final thisMonthTransactions = transactions
        .where(
          (t) =>
              t.date.isAfter(thisMonthStart) && t.date.isBefore(thisMonthEnd),
        )
        .toList();

    // Calculate total spent this month
    final totalSpent = thisMonthTransactions.fold<double>(
      0.0,
      (sum, t) => sum + t.amount,
    );

    // Calculate spending by category
    final spendingByCategory = <int, double>{};
    final categoryMap = {for (var cat in categories) cat.id: cat};

    for (final transaction in thisMonthTransactions) {
      if (transaction.categoryId != null) {
        spendingByCategory[transaction.categoryId!] =
            (spendingByCategory[transaction.categoryId] ?? 0.0) +
            transaction.amount;
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
        // Summary card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'This Month Summary',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _StatItem(
                      label: 'Total Spent',
                      value: totalSpent.toStringAsFixed(2),
                      icon: Icons.payments,
                    ),
                    _StatItem(
                      label: 'Transactions',
                      value: thisMonthTransactions.length.toString(),
                      icon: Icons.receipt,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Spending by category
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Spending by Category',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                if (spendingByCategory.isEmpty)
                  const Text('No spending data for this month')
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
                                category?.name ?? 'Unknown',
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                              Text(
                                '${amount.toStringAsFixed(2)} (${percentage.toStringAsFixed(1)}%)',
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
        ),
        const SizedBox(height: 16),
        // Budget vs Actual
        if (budgetVsActual.isNotEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Budget vs Actual',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  ...budgetVsActual.entries.map((entry) {
                    final category = categoryMap[entry.key];
                    final budget = entry.value['budget']!;
                    final spent = entry.value['spent']!;
                    final remaining = entry.value['remaining']!;
                    final percentage = budget > 0
                        ? (spent / budget * 100)
                        : 0.0;
                    final color = percentage >= 100
                        ? Colors.red
                        : percentage >= 80
                        ? Colors.orange
                        : Colors.green;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            category?.name ?? 'Unknown',
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Budget: ${budget.toStringAsFixed(2)}'),
                              Text('Spent: ${spent.toStringAsFixed(2)}'),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: color),
                                ),
                                child: Text(
                                  remaining >= 0
                                      ? '${remaining.toStringAsFixed(2)} left'
                                      : '${(-remaining).toStringAsFixed(2)} over',
                                  style: TextStyle(
                                    color: color,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          LinearProgressIndicator(
                            value: (percentage / 100).clamp(0.0, 1.0),
                            backgroundColor: color.withValues(alpha: 0.2),
                            valueColor: AlwaysStoppedAnimation<Color>(color),
                            minHeight: 8,
                          ),
                          Text(
                            '${percentage.toStringAsFixed(0)}% used',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
      ],
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
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
