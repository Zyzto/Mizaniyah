/// Constants for budget service
class BudgetConstants {
  /// Percentage threshold for warning status (0.0-1.0)
  /// Budgets at 80% or more usage show yellow warning
  static const double warningThreshold = 0.8;

  /// Budget period types
  static const String periodMonthly = 'monthly';
  static const String periodWeekly = 'weekly';
  static const String periodYearly = 'yearly';

  /// Days in a week
  static const int daysPerWeek = 7;
}
