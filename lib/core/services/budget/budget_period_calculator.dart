import 'package:flutter_logging_service/flutter_logging_service.dart';
import 'package:mizaniyah/core/database/app_database.dart' as db;
import 'package:mizaniyah/core/services/budget/budget_constants.dart';

/// Service responsible for calculating budget period dates
class BudgetPeriodCalculator with Loggable {
  /// Get the current period start and end dates for a budget
  (DateTime start, DateTime end) getBudgetPeriodDates(db.Budget budget) {
    final now = DateTime.now();
    final startDate = budget.startDate;

    switch (budget.period) {
      case BudgetConstants.periodMonthly:
        return _calculateMonthlyPeriod(now, startDate);
      case BudgetConstants.periodWeekly:
        return _calculateWeeklyPeriod(now, startDate);
      case BudgetConstants.periodYearly:
        return _calculateYearlyPeriod(now, startDate);
      default:
        logWarning(
          'Unknown budget period: ${budget.period}, defaulting to monthly',
        );
        return _calculateMonthlyPeriod(now, startDate);
    }
  }

  /// Calculate monthly period dates
  (DateTime start, DateTime end) _calculateMonthlyPeriod(
    DateTime now,
    DateTime startDate,
  ) {
    // Calculate months since start
    final monthsSinceStart =
        (now.year - startDate.year) * 12 + (now.month - startDate.month);

    // Start from the original start date
    var periodStart = DateTime(startDate.year, startDate.month, startDate.day);

    // Advance to current period
    for (int i = 0; i < monthsSinceStart; i++) {
      periodStart = DateTime(
        periodStart.year,
        periodStart.month + 1,
        periodStart.day,
      );
    }

    // Adjust if we haven't reached the start day of current month yet
    if (now.day < startDate.day) {
      periodStart = DateTime(
        periodStart.year,
        periodStart.month - 1,
        periodStart.day,
      );
    }

    // Calculate period end (day before next period starts)
    final periodEnd = DateTime(
      periodStart.year,
      periodStart.month + 1,
      periodStart.day,
    ).subtract(const Duration(days: 1));

    return (periodStart, periodEnd);
  }

  /// Calculate weekly period dates
  (DateTime start, DateTime end) _calculateWeeklyPeriod(
    DateTime now,
    DateTime startDate,
  ) {
    final daysSinceStart = now.difference(startDate).inDays;
    final weeksSinceStart = daysSinceStart ~/ BudgetConstants.daysPerWeek;

    final periodStart = startDate.add(
      Duration(days: weeksSinceStart * BudgetConstants.daysPerWeek),
    );

    final periodEnd = periodStart.add(
      const Duration(days: BudgetConstants.daysPerWeek - 1),
    );

    return (periodStart, periodEnd);
  }

  /// Calculate yearly period dates
  (DateTime start, DateTime end) _calculateYearlyPeriod(
    DateTime now,
    DateTime startDate,
  ) {
    var periodStart = DateTime(startDate.year, startDate.month, startDate.day);

    // Adjust if we haven't reached the start date this year
    if (now.month < startDate.month ||
        (now.month == startDate.month && now.day < startDate.day)) {
      periodStart = DateTime(
        periodStart.year - 1,
        periodStart.month,
        periodStart.day,
      );
    }

    // Calculate period end (day before next period starts)
    final periodEnd = DateTime(
      periodStart.year + 1,
      periodStart.month,
      periodStart.day,
    ).subtract(const Duration(days: 1));

    return (periodStart, periodEnd);
  }
}
