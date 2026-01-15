import 'package:mizaniyah/core/database/app_database.dart' as db;
import 'package:mizaniyah/core/database/daos/budget_dao.dart';
import 'package:mizaniyah/core/database/daos/transaction_dao.dart';
import 'package:flutter_logging_service/flutter_logging_service.dart';
import 'package:mizaniyah/core/services/budget/budget_period_calculator.dart';
import 'package:mizaniyah/core/services/budget/budget_status_calculator.dart';

/// Budget Service
/// Handles budget calculations, remaining amounts, and rollover logic
class BudgetService with Loggable {
  final BudgetDao _budgetDao;
  final TransactionDao _transactionDao;
  final BudgetPeriodCalculator _periodCalculator;
  final BudgetStatusCalculator _statusCalculator;

  BudgetService(this._budgetDao, this._transactionDao)
    : _periodCalculator = BudgetPeriodCalculator(),
      _statusCalculator = BudgetStatusCalculator();

  /// Get the current period start and end dates for a budget
  (DateTime start, DateTime end) getBudgetPeriodDates(db.Budget budget) {
    return _periodCalculator.getBudgetPeriodDates(budget);
  }

  /// Calculate total spent for a budget in the current period
  Future<double> calculateSpentAmount(db.Budget budget) async {
    logDebug('calculateSpentAmount(budgetId=${budget.id})');
    try {
      final (periodStart, periodEnd) = getBudgetPeriodDates(budget);

      // Get transactions filtered by date range AND category in SQL (optimized)
      final transactions = await _transactionDao
          .getTransactionsByDateRangeAndCategory(
            periodStart,
            periodEnd,
            budget.categoryId,
          );

      // Sum amounts using fold (optimized - single pass)
      // TODO: Add currency conversion support
      final total = transactions.fold<double>(
        0.0,
        (sum, transaction) => sum + transaction.amount,
      );

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
      final statusColor = _statusCalculator.getBudgetStatusColor(
        budgetAmount: budget.amount,
        remainingAmount: remaining,
      );

      return statusColor.value;
    } catch (e, stackTrace) {
      logError(
        'getBudgetStatusColor() failed',
        error: e,
        stackTrace: stackTrace,
      );
      return BudgetStatusColor.green.value; // Default to green on error
    }
  }

  /// Get remaining budget for a category (finds active budget for category)
  Future<double?> getRemainingBudgetForCategory(int categoryId) async {
    logDebug('getRemainingBudgetForCategory(categoryId=$categoryId)');
    try {
      final budgets = await _budgetDao.getBudgetsByCategory(categoryId);
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
      final budgets = await _budgetDao.getBudgetsByCategory(categoryId);
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
