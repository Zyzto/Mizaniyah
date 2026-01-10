import '../app_database.dart';
import 'base_validator.dart';

/// Validator for transaction data
/// Centralizes all transaction validation logic
class TransactionValidator {
  /// Validate transaction companion for insertion
  static void validateInsert(TransactionsCompanion transaction) {
    final amount = transaction.amount.value;
    BaseValidator.validatePositiveNumber(amount, 'Transaction amount');

    final storeName = transaction.storeName.value;
    BaseValidator.validateNonEmptyString(storeName, 'Store name');
    BaseValidator.validateMaxLength(storeName, 200, 'Store name');

    final source = transaction.source.value;
    if (source != 'manual' && source != 'sms') {
      throw ArgumentError('Source must be either "manual" or "sms"');
    }

    final currencyCode = transaction.currencyCode.value;
    if (currencyCode.length != 3) {
      throw ArgumentError('Currency code must be exactly 3 characters');
    }
  }

  /// Validate transaction companion for update
  static void validateUpdate(TransactionsCompanion transaction) {
    if (transaction.amount.present) {
      BaseValidator.validatePositiveNumber(
        transaction.amount.value,
        'Transaction amount',
      );
    }

    if (transaction.storeName.present) {
      final storeName = transaction.storeName.value;
      BaseValidator.validateNonEmptyString(storeName, 'Store name');
      BaseValidator.validateMaxLength(storeName, 200, 'Store name');
    }

    if (transaction.source.present) {
      final source = transaction.source.value;
      if (source != 'manual' && source != 'sms') {
        throw ArgumentError('Source must be either "manual" or "sms"');
      }
    }

    if (transaction.currencyCode.present) {
      final currencyCode = transaction.currencyCode.value;
      if (currencyCode.length != 3) {
        throw ArgumentError('Currency code must be exactly 3 characters');
      }
    }
  }
}
