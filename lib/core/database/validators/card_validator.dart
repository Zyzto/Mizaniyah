import '../app_database.dart';
import 'base_validator.dart';

/// Validator for card data
class CardValidator {
  /// Validate card companion for insertion
  static void validateInsert(CardsCompanion card) {
    final cardName = card.cardName.value;
    BaseValidator.validateNonEmptyString(cardName, 'Card name');
    BaseValidator.validateMaxLength(cardName, 100, 'Card name');

    final last4Digits = card.last4Digits.value;
    BaseValidator.validateExactLength(last4Digits, 4, 'Last 4 digits');
    BaseValidator.validatePattern(
      last4Digits,
      RegExp(r'^\d{4}$'),
      'Last 4 digits',
      'must be exactly 4 numeric characters',
    );
  }

  /// Validate card companion for update
  static void validateUpdate(CardsCompanion card) {
    if (card.cardName.present) {
      final cardName = card.cardName.value;
      BaseValidator.validateNonEmptyString(cardName, 'Card name');
      BaseValidator.validateMaxLength(cardName, 100, 'Card name');
    }

    if (card.last4Digits.present) {
      final last4Digits = card.last4Digits.value;
      BaseValidator.validateExactLength(last4Digits, 4, 'Last 4 digits');
      BaseValidator.validatePattern(
        last4Digits,
        RegExp(r'^\d{4}$'),
        'Last 4 digits',
        'must be exactly 4 numeric characters',
      );
    }
  }
}
