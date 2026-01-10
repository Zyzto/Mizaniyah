import '../app_database.dart';
import 'base_validator.dart';

/// Validator for category data
class CategoryValidator {
  /// Validate category companion for insertion
  static void validateInsert(CategoriesCompanion category) {
    final name = category.name.value;
    BaseValidator.validateNonEmptyString(name, 'Category name');
    BaseValidator.validateMaxLength(name, 100, 'Category name');

    final color = category.color.value;
    BaseValidator.validateNumberRange(color, 0, 4294967295, 'Color');
  }

  /// Validate category companion for update
  static void validateUpdate(CategoriesCompanion category) {
    if (category.name.present) {
      final name = category.name.value;
      BaseValidator.validateNonEmptyString(name, 'Category name');
      BaseValidator.validateMaxLength(name, 100, 'Category name');
    }

    if (category.color.present) {
      final color = category.color.value;
      BaseValidator.validateNumberRange(color, 0, 4294967295, 'Color');
    }
  }
}
