import 'package:mizaniyah/core/database/app_database.dart' as db;
import 'package:mizaniyah/core/database/daos/budget_dao.dart';
import 'package:flutter_logging_service/flutter_logging_service.dart';

class BudgetRepository with Loggable {
  final db.AppDatabase _db;
  late final BudgetDao _budgetDao;

  BudgetRepository(this._db) {
    logDebug('BudgetRepository initialized');
    _budgetDao = BudgetDao(_db);
  }

  Stream<List<db.Budget>> watchAllBudgets() => _budgetDao.watchAllBudgets();

  Future<List<db.Budget>> getAllBudgets() => _budgetDao.getAllBudgets();

  Future<List<db.Budget>> getActiveBudgets() => _budgetDao.getActiveBudgets();

  Future<List<db.Budget>> getBudgetsByCategory(int categoryId) =>
      _budgetDao.getBudgetsByCategory(categoryId);

  Future<db.Budget?> getBudgetById(int id) => _budgetDao.getBudgetById(id);

  Future<int> createBudget(db.BudgetsCompanion budget) async {
    logInfo('createBudget(categoryId=${budget.categoryId.value})');
    try {
      final budgetId = await _budgetDao.insertBudget(budget);
      logInfo('createBudget() created budget with id=$budgetId');
      return budgetId;
    } catch (e, stackTrace) {
      logError('createBudget() failed', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<bool> updateBudget(db.BudgetsCompanion budget) async {
    final id = budget.id.value;
    logInfo('updateBudget(id=$id)');
    try {
      final result = await _budgetDao.updateBudget(budget);
      logInfo('updateBudget(id=$id) updated successfully');
      return result;
    } catch (e, stackTrace) {
      logError('updateBudget(id=$id) failed', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<int> deleteBudget(int id) async {
    logInfo('deleteBudget(id=$id)');
    try {
      final result = await _budgetDao.deleteBudget(id);
      logInfo('deleteBudget(id=$id) deleted $result rows');
      return result;
    } catch (e, stackTrace) {
      logError('deleteBudget(id=$id) failed', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }
}
