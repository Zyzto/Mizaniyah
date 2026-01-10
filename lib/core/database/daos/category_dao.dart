import 'package:drift/drift.dart';
import '../app_database.dart';
import '../models/categories.dart';
import 'package:flutter_logging_service/flutter_logging_service.dart';
import 'base_dao_mixin.dart';
import '../validators/category_validator.dart';

part 'category_dao.g.dart';

@DriftAccessor(tables: [Categories])
class CategoryDao extends DatabaseAccessor<AppDatabase>
    with _$CategoryDaoMixin, Loggable, BaseDaoMixin {
  CategoryDao(super.db);

  Future<List<Category>> getAllCategories() async {
    return executeWithErrorHandling<List<Category>>(
      operationName: 'getAllCategories',
      operation: () async {
        final result = await select(db.categories).get();
        logInfo('getAllCategories() returned ${result.length} categories');
        return result;
      },
      onError: () => <Category>[],
    );
  }

  Stream<List<Category>> watchAllCategories() {
    logDebug('watchAllCategories() called');
    return select(db.categories).watch();
  }

  Future<List<Category>> getActiveCategories() async {
    return executeWithErrorHandling<List<Category>>(
      operationName: 'getActiveCategories',
      operation: () async {
        final result = await (select(
          db.categories,
        )..where((c) => c.isActive.equals(true))).get();
        logInfo('getActiveCategories() returned ${result.length} categories');
        return result;
      },
      onError: () => <Category>[],
    );
  }

  Future<Category?> getCategoryById(int id) async {
    return executeWithErrorHandling<Category?>(
      operationName: 'getCategoryById',
      operation: () async {
        final result = await (select(
          db.categories,
        )..where((c) => c.id.equals(id))).getSingleOrNull();
        logDebug(
          'getCategoryById(id=$id) returned ${result != null ? "category" : "null"}',
        );
        return result;
      },
      onError: () => null,
    );
  }

  Future<int> insertCategory(CategoriesCompanion category) async {
    return executeWithErrorHandling<int>(
      operationName: 'insertCategory',
      operation: () async {
        CategoryValidator.validateInsert(category);
        final id = await into(db.categories).insert(category);
        logInfo('insertCategory() inserted category with id=$id');
        return id;
      },
    );
  }

  Future<bool> updateCategory(CategoriesCompanion category) async {
    final id = category.id.value;
    return executeWithErrorHandling<bool>(
      operationName: 'updateCategory',
      operation: () async {
        CategoryValidator.validateUpdate(category);
        final result = await update(db.categories).replace(category);
        logInfo('updateCategory(id=$id) updated successfully');
        return result;
      },
    );
  }

  Future<int> deleteCategory(int id) async {
    return executeWithErrorHandling<int>(
      operationName: 'deleteCategory',
      operation: () async {
        final result = await (delete(
          db.categories,
        )..where((c) => c.id.equals(id))).go();
        logInfo('deleteCategory(id=$id) deleted $result rows');
        return result;
      },
    );
  }

  /// Get count of active categories (optimized with SQL aggregation)
  Future<int> getActiveCategoriesCount() async {
    return executeWithErrorHandling<int>(
      operationName: 'getActiveCategoriesCount',
      operation: () async {
        final query = selectOnly(db.categories)
          ..addColumns([db.categories.id.count()])
          ..where(db.categories.isActive.equals(true));

        final result = await query.getSingle();
        final count = result.read(db.categories.id.count()) ?? 0;
        logInfo('getActiveCategoriesCount() returned $count');
        return count;
      },
      onError: () => 0,
    );
  }
}
