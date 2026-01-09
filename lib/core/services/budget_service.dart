import 'package:mizaniyah/core/database/app_database.dart' as db;
import 'package:mizaniyah/features/budgets/budget_repository.dart';
import 'package:mizaniyah/features/transactions/transaction_repository.dart';
import 'package:flutter_logging_service/flutter_logging_service.dart';

/// Budget Service
/// Handles budget calculations, remaining amounts, and rollover logic
class BudgetService with Loggable {
  final BudgetRepository _budgetRepository;
  final TransactionRepository _transactionRepository;

  BudgetService(this._budgetRepository, this._transactionRepository);

  /// Get the current period start and end dates for a budget
  (DateTime start, DateTime end) getBudgetPeriodDates(db.Budget budget) {
    final now = DateTime.now();
    final startDate = budget.startDate;

    // Calculate current period based on start date
    DateTime periodStart;
    DateTime periodEnd;

    switch (budget.period) {
      case 'monthly':
        // Find the current month period based on start date
        final monthsSinceStart =
            (now.year - startDate.year) * 12 + (now.month - startDate.month);
        periodStart = DateTime(startDate.year, startDate.month, startDate.day);
        for (int i = 0; i < monthsSinceStart; i++) {
          periodStart = DateTime(
            periodStart.year,
            periodStart.month + 1,
            periodStart.day,
          );
        }
        // Ensure we're in the correct period
        if (now.day < startDate.day) {
          periodStart = DateTime(
            periodStart.year,
            periodStart.month - 1,
            periodStart.day,
          );
        }
        periodEnd = DateTime(
          periodStart.year,
          periodStart.month + 1,
          periodStart.day,
        ).subtract(const Duration(days: 1));
        break;
      case 'weekly':
        final daysSinceStart = now.difference(startDate).inDays;
        final weeksSinceStart = daysSinceStart ~/ 7;
        periodStart = startDate.add(Duration(days: weeksSinceStart * 7));
        periodEnd = periodStart.add(const Duration(days: 6));
        break;
      case 'yearly':
        periodStart = DateTime(startDate.year, startDate.month, startDate.day);
        if (now.month < startDate.month ||
            (now.month == startDate.month && now.day < startDate.day)) {
          periodStart = DateTime(
            periodStart.year - 1,
            periodStart.month,
            periodStart.day,
          );
        }
        periodEnd = DateTime(
          periodStart.year + 1,
          periodStart.month,
          periodStart.day,
        ).subtract(const Duration(days: 1));
        break;
      default:
        // Default to monthly
        periodStart = DateTime(now.year, now.month, startDate.day);
        periodEnd = DateTime(
          periodStart.year,
          periodStart.month + 1,
          periodStart.day,
        ).subtract(const Duration(days: 1));
    }

    return (periodStart, periodEnd);
  }

  /// Calculate total spent for a budget in the current period
  Future<double> calculateSpentAmount(db.Budget budget) async {
    logDebug('calculateSpentAmount(budgetId=${budget.id})');
    try {
      final (periodStart, periodEnd) = getBudgetPeriodDates(budget);

      // Get all transactions for this category in the period
      final transactions = await _transactionRepository
          .getTransactionsByDateRange(periodStart, periodEnd);

      // Filter by category
      final categoryTransactions = transactions
          .where((t) => t.categoryId == budget.categoryId)
          .toList();

      // Sum amounts (assuming same currency for now)
      double total = 0.0;
      for (final transaction in categoryTransactions) {
        total += transaction.amount;
      }

      logInfo(
        'calculateSpentAmount() returned total=$total for budget ${budget.id}',
      );
      return total;
    } catch (e, stackTrace) {
      logError(
        'calculateSpentAmount() failed',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Calculate remaining budget amount
  Future<double> calculateRemainingBudget(db.Budget budget) async {
    logDebug('calculateRemainingBudget(budgetId=${budget.id})');
    try {
      final spent = await calculateSpentAmount(budget);
      final remaining = budget.amount - spent;

      logInfo(
        'calculateRemainingBudget() returned remaining=$remaining for budget ${budget.id}',
      );
      return remaining;
    } catch (e, stackTrace) {
      logError(
        'calculateRemainingBudget() failed',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Get budget status color (green/yellow/red)
  /// Returns: 0 = green (good), 1 = yellow (warning), 2 = red (over budget)
  Future<int> getBudgetStatusColor(db.Budget budget) async {
    logDebug('getBudgetStatusColor(budgetId=${budget.id})');
    try {
      final remaining = await calculateRemainingBudget(budget);
      final percentageUsed = (budget.amount - remaining) / budget.amount;

      if (remaining < 0) {
        // Over budget - red
        return 2;
      } else if (percentageUsed >= 0.8) {
        // 80% or more used - yellow
        return 1;
      } else {
        // Less than 80% used - green
        return 0;
      }
    } catch (e, stackTrace) {
      logError(
        'getBudgetStatusColor() failed',
        error: e,
        stackTrace: stackTrace,
      );
      return 0; // Default to green on error
    }
  }

  /// Get remaining budget for a category (finds active budget for category)
  Future<double?> getRemainingBudgetForCategory(int categoryId) async {
    logDebug('getRemainingBudgetForCategory(categoryId=$categoryId)');
    try {
      final budgets = await _budgetRepository.getBudgetsByCategory(categoryId);
      if (budgets.isEmpty) {
        logDebug('No active budget found for category $categoryId');
        return null;
      }

      // Get the most recent active budget
      final budget = budgets.first;
      final remaining = await calculateRemainingBudget(budget);

      logInfo(
        'getRemainingBudgetForCategory() returned remaining=$remaining for category $categoryId',
      );
      return remaining;
    } catch (e, stackTrace) {
      logError(
        'getRemainingBudgetForCategory() failed',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  /// Get budget status color for a category
  Future<int?> getBudgetStatusColorForCategory(int categoryId) async {
    logDebug('getBudgetStatusColorForCategory(categoryId=$categoryId)');
    try {
      final budgets = await _budgetRepository.getBudgetsByCategory(categoryId);
      if (budgets.isEmpty) {
        return null;
      }

      final budget = budgets.first;
      return await getBudgetStatusColor(budget);
    } catch (e, stackTrace) {
      logError(
        'getBudgetStatusColorForCategory() failed',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  /// Handle rollover logic when creating a new period budget
  Future<double> calculateRolloverAmount(db.Budget budget) async {
    logDebug('calculateRolloverAmount(budgetId=${budget.id})');
    try {
      if (!budget.rolloverEnabled) {
        return 0.0;
      }

      final remaining = await calculateRemainingBudget(budget);
      if (remaining <= 0) {
        return 0.0;
      }

      final rolloverAmount = remaining * (budget.rolloverPercentage / 100.0);
      logInfo(
        'calculateRolloverAmount() returned rollover=$rolloverAmount for budget ${budget.id}',
      );
      return rolloverAmount;
    } catch (e, stackTrace) {
      logError(
        'calculateRolloverAmount() failed',
        error: e,
        stackTrace: stackTrace,
      );
      return 0.0;
    }
  }
}
