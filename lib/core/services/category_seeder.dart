import 'package:flutter/material.dart';
import 'package:mizaniyah/core/database/app_database.dart' as db;
import 'package:mizaniyah/core/database/daos/category_dao.dart';
import 'package:flutter_logging_service/flutter_logging_service.dart';
import 'package:drift/drift.dart' as drift;

/// Service to seed predefined categories
class CategorySeeder with Loggable {
  final CategoryDao _categoryDao;

  CategorySeeder(this._categoryDao);

  /// Seed predefined categories if they don't exist
  Future<void> seedPredefinedCategories() async {
    logInfo('Seeding predefined categories');

    try {
      final existingCategories = await _categoryDao.getAllCategories();
      final existingNames = existingCategories
          .map((c) => c.name.toLowerCase())
          .toSet();

      final predefinedCategories = [
        _CategoryData('Food & Dining', Icons.restaurant, 0xFF4CAF50),
        _CategoryData('Shopping', Icons.shopping_bag, 0xFF2196F3),
        _CategoryData('Transportation', Icons.directions_car, 0xFF9C27B0),
        _CategoryData('Bills & Utilities', Icons.receipt, 0xFFFF9800),
        _CategoryData('Entertainment', Icons.movie, 0xFFE91E63),
        _CategoryData('Healthcare', Icons.local_hospital, 0xFFF44336),
        _CategoryData('Education', Icons.school, 0xFF00BCD4),
        _CategoryData('Travel', Icons.flight, 0xFF3F51B5),
        _CategoryData('Groceries', Icons.shopping_cart, 0xFF8BC34A),
        _CategoryData('Gas & Fuel', Icons.local_gas_station, 0xFFFFC107),
        _CategoryData('Clothing', Icons.checkroom, 0xFFE91E63),
        _CategoryData('Home & Garden', Icons.home, 0xFF795548),
      ];

      int created = 0;
      for (final categoryData in predefinedCategories) {
        if (!existingNames.contains(categoryData.name.toLowerCase())) {
          final category = db.CategoriesCompanion(
            name: drift.Value(categoryData.name),
            icon: drift.Value(categoryData.icon.codePoint.toString()),
            color: drift.Value(categoryData.color),
            isPredefined: const drift.Value(true),
            isActive: const drift.Value(true),
          );

          await _categoryDao.insertCategory(category);
          created++;
          logInfo('Created predefined category: ${categoryData.name}');
        }
      }

      logInfo('Category seeding completed. Created $created new categories.');
    } catch (e, stackTrace) {
      logError(
        'Failed to seed predefined categories',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }
}

class _CategoryData {
  final String name;
  final IconData icon;
  final int color;

  _CategoryData(this.name, this.icon, this.color);
}
