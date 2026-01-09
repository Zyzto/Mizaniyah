import 'package:drift/drift.dart';
import '../app_database.dart';
import '../models/categories.dart';
import 'package:flutter_logging_service/flutter_logging_service.dart';

part 'category_dao.g.dart';

@DriftAccessor(tables: [Categories])
class CategoryDao extends DatabaseAccessor<AppDatabase>
    with _$CategoryDaoMixin, Loggable {
  CategoryDao(super.db);

  Future<List<Category>> getAllCategories() async {
    logDebug('getAllCategories() called');
    try {
      final result = await select(db.categories).get();
      logInfo('getAllCategories() returned ${result.length} categories');
      return result;
    } catch (e, stackTrace) {
      logError('getAllCategories() failed', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Stream<List<Category>> watchAllCategories() {
    logDebug('watchAllCategories() called');
    return select(db.categories).watch();
  }

  Future<List<Category>> getActiveCategories() async {
    logDebug('getActiveCategories() called');
    try {
      final result = await (select(
        db.categories,
      )..where((c) => c.isActive.equals(true))).get();
      logInfo('getActiveCategories() returned ${result.length} categories');
      return result;
    } catch (e, stackTrace) {
      logError(
        'getActiveCategories() failed',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<Category?> getCategoryById(int id) async {
    logDebug('getCategoryById(id=$id) called');
    try {
      final result = await (select(
        db.categories,
      )..where((c) => c.id.equals(id))).getSingleOrNull();
      logDebug(
        'getCategoryById(id=$id) returned ${result != null ? "category" : "null"}',
      );
      return result;
    } catch (e, stackTrace) {
      logError(
        'getCategoryById(id=$id) failed',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<int> insertCategory(CategoriesCompanion category) async {
    logDebug('insertCategory(name=${category.name.value}) called');
    try {
      final id = await into(db.categories).insert(category);
      logInfo('insertCategory() inserted category with id=$id');
      return id;
    } catch (e, stackTrace) {
      logError('insertCategory() failed', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<bool> updateCategory(CategoriesCompanion category) async {
    final id = category.id.value;
    logDebug('updateCategory(id=$id) called');
    try {
      final result = await update(db.categories).replace(category);
      logInfo('updateCategory(id=$id) updated successfully');
      return result;
    } catch (e, stackTrace) {
      logError(
        'updateCategory(id=$id) failed',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<int> deleteCategory(int id) async {
    logDebug('deleteCategory(id=$id) called');
    try {
      final result = await (delete(
        db.categories,
      )..where((c) => c.id.equals(id))).go();
      logInfo('deleteCategory(id=$id) deleted $result rows');
      return result;
    } catch (e, stackTrace) {
      logError(
        'deleteCategory(id=$id) failed',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }
}
