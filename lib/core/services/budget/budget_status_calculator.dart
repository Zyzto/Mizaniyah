import 'package:flutter_logging_service/flutter_logging_service.dart';
import 'package:mizaniyah/core/services/budget/budget_constants.dart';

/// Budget status color codes
enum BudgetStatusColor {
  green(0), // Good - less than 80% used
  yellow(1), // Warning - 80% or more used
  red(2); // Over budget

  final int value;
  const BudgetStatusColor(this.value);
}

/// Service responsible for calculating budget status and colors
class BudgetStatusCalculator with Loggable {
  /// Get budget status color based on remaining amount
  /// Returns: 0 = green (good), 1 = yellow (warning), 2 = red (over budget)
  BudgetStatusColor getBudgetStatusColor({
    required double budgetAmount,
    required double remainingAmount,
  }) {
    if (remainingAmount < 0) {
      return BudgetStatusColor.red; // Over budget
    }

    final percentageUsed = (budgetAmount - remainingAmount) / budgetAmount;
    if (percentageUsed >= BudgetConstants.warningThreshold) {
      return BudgetStatusColor.yellow; // 80% or more used
    }

    return BudgetStatusColor.green; // Less than 80% used
  }

  /// Get budget status color for a budget with spent amount
  BudgetStatusColor getBudgetStatusColorFromSpent({
    required double budgetAmount,
    required double spentAmount,
  }) {
    final remainingAmount = budgetAmount - spentAmount;
    return getBudgetStatusColor(
      budgetAmount: budgetAmount,
      remainingAmount: remainingAmount,
    );
  }
}
