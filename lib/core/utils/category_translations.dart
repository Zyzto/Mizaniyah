import 'package:easy_localization/easy_localization.dart';
import '../database/app_database.dart' as db;

/// Utility class for translating category names
class CategoryTranslations {
  /// Map of predefined category names to their translation keys
  static final Map<String, String> _categoryTranslationMap = {
    'Food & Dining': 'category_food_dining',
    'Shopping': 'category_shopping',
    'Transportation': 'category_transportation',
    'Bills & Utilities': 'category_bills_utilities',
    'Entertainment': 'category_entertainment',
    'Healthcare': 'category_healthcare',
    'Education': 'category_education',
    'Travel': 'category_travel',
    'Groceries': 'category_groceries',
    'Gas & Fuel': 'category_gas_fuel',
    'Clothing': 'category_clothing',
    'Home & Garden': 'category_home_garden',
  };

  /// Get the translated name for a category
  /// Returns the translated name for predefined categories,
  /// or the original name for custom categories
  static String getTranslatedName(db.Category category) {
    // If it's a predefined category, try to get the translation
    if (category.isPredefined) {
      final translationKey = _categoryTranslationMap[category.name];
      if (translationKey != null) {
        return translationKey.tr();
      }
    }
    // Return original name for custom categories or if translation not found
    return category.name;
  }

  /// Get the translated name from a category name string
  /// Useful when you only have the name and not the full category object
  static String getTranslatedNameFromString(String name, bool isPredefined) {
    if (isPredefined) {
      final translationKey = _categoryTranslationMap[name];
      if (translationKey != null) {
        return translationKey.tr();
      }
    }
    return name;
  }
}
