import 'package:mizaniyah/core/database/app_database.dart' as db;
import 'package:mizaniyah/core/database/daos/category_dao.dart';
import 'package:flutter_logging_service/flutter_logging_service.dart';

class CategoryRepository with Loggable {
  final db.AppDatabase _db;
  late final CategoryDao _categoryDao;

  CategoryRepository(this._db) {
    logDebug('CategoryRepository initialized');
    _categoryDao = CategoryDao(_db);
  }

  // Categories
  Stream<List<db.Category>> watchAllCategories() =>
      _categoryDao.watchAllCategories();

  Future<List<db.Category>> getAllCategories() =>
      _categoryDao.getAllCategories();

  Future<List<db.Category>> getActiveCategories() =>
      _categoryDao.getActiveCategories();

  Future<db.Category?> getCategoryById(int id) =>
      _categoryDao.getCategoryById(id);

  Future<int> createCategory(db.CategoriesCompanion category) async {
    logInfo('createCategory(name=${category.name.value})');
    try {
      final categoryId = await _categoryDao.insertCategory(category);
      logInfo('createCategory() created category with id=$categoryId');
      return categoryId;
    } catch (e, stackTrace) {
      logError('createCategory() failed', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<bool> updateCategory(db.CategoriesCompanion category) async {
    final id = category.id.value;
    logInfo('updateCategory(id=$id)');
    try {
      final result = await _categoryDao.updateCategory(category);
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
    logInfo('deleteCategory(id=$id)');
    try {
      final result = await _categoryDao.deleteCategory(id);
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
