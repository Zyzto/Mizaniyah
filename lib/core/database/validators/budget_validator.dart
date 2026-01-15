import '../app_database.dart';
import 'base_validator.dart';

/// Validator for budget data
class BudgetValidator {
  /// Valid budget periods
  static const validPeriods = ['monthly', 'weekly', 'yearly'];

  /// Validate budget companion for insertion
  static void validateInsert(BudgetsCompanion budget) {
    final amount = budget.amount.value;
    BaseValidator.validatePositiveNumber(amount, 'Budget amount');

    final period = budget.period.value;
    if (!validPeriods.contains(period)) {
      throw ArgumentError('Period must be one of: ${validPeriods.join(", ")}');
    }

    final rolloverPercentage = budget.rolloverPercentage.value;
    BaseValidator.validateNumberRange(
      rolloverPercentage,
      0,
      100,
      'Rollover percentage',
    );
  }

  /// Validate budget companion for update
  static void validateUpdate(BudgetsCompanion budget) {
    if (budget.amount.present) {
      BaseValidator.validatePositiveNumber(
        budget.amount.value,
        'Budget amount',
      );
    }

    if (budget.period.present) {
      final period = budget.period.value;
      if (!validPeriods.contains(period)) {
        throw ArgumentError(
          'Period must be one of: ${validPeriods.join(", ")}',
        );
      }
    }

    if (budget.rolloverPercentage.present) {
      final rolloverPercentage = budget.rolloverPercentage.value;
      BaseValidator.validateNumberRange(
        rolloverPercentage,
        0,
        100,
        'Rollover percentage',
      );
    }
  }
}
