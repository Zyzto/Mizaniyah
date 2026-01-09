import 'package:drift/drift.dart';
import '../app_database.dart';
import '../models/budgets.dart';
import 'package:flutter_logging_service/flutter_logging_service.dart';

part 'budget_dao.g.dart';

@DriftAccessor(tables: [Budgets])
class BudgetDao extends DatabaseAccessor<AppDatabase>
    with _$BudgetDaoMixin, Loggable {
  BudgetDao(super.db);

  Future<List<Budget>> getAllBudgets() async {
    logDebug('getAllBudgets() called');
    try {
      final result = await select(db.budgets).get();
      logInfo('getAllBudgets() returned ${result.length} budgets');
      return result;
    } catch (e, stackTrace) {
      logError('getAllBudgets() failed', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Stream<List<Budget>> watchAllBudgets() {
    logDebug('watchAllBudgets() called');
    return select(db.budgets).watch();
  }

  Future<List<Budget>> getActiveBudgets() async {
    logDebug('getActiveBudgets() called');
    try {
      final result = await (select(
        db.budgets,
      )..where((b) => b.isActive.equals(true))).get();
      logInfo('getActiveBudgets() returned ${result.length} budgets');
      return result;
    } catch (e, stackTrace) {
      logError('getActiveBudgets() failed', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<List<Budget>> getBudgetsByCategory(int categoryId) async {
    logDebug('getBudgetsByCategory(categoryId=$categoryId) called');
    try {
      final result =
          await (select(db.budgets)
                ..where((b) => b.categoryId.equals(categoryId))
                ..where((b) => b.isActive.equals(true)))
              .get();
      logInfo('getBudgetsByCategory() returned ${result.length} budgets');
      return result;
    } catch (e, stackTrace) {
      logError(
        'getBudgetsByCategory() failed',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<Budget?> getBudgetById(int id) async {
    logDebug('getBudgetById(id=$id) called');
    try {
      final result = await (select(
        db.budgets,
      )..where((b) => b.id.equals(id))).getSingleOrNull();
      logDebug(
        'getBudgetById(id=$id) returned ${result != null ? "budget" : "null"}',
      );
      return result;
    } catch (e, stackTrace) {
      logError(
        'getBudgetById(id=$id) failed',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<int> insertBudget(BudgetsCompanion budget) async {
    logDebug('insertBudget(categoryId=${budget.categoryId.value}) called');
    try {
      final id = await into(db.budgets).insert(budget);
      logInfo('insertBudget() inserted budget with id=$id');
      return id;
    } catch (e, stackTrace) {
      logError('insertBudget() failed', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<bool> updateBudget(BudgetsCompanion budget) async {
    final id = budget.id.value;
    logDebug('updateBudget(id=$id) called');
    try {
      final result = await update(db.budgets).replace(budget);
      logInfo('updateBudget(id=$id) updated successfully');
      return result;
    } catch (e, stackTrace) {
      logError('updateBudget(id=$id) failed', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<int> deleteBudget(int id) async {
    logDebug('deleteBudget(id=$id) called');
    try {
      final result = await (delete(
        db.budgets,
      )..where((b) => b.id.equals(id))).go();
      logInfo('deleteBudget(id=$id) deleted $result rows');
      return result;
    } catch (e, stackTrace) {
      logError('deleteBudget(id=$id) failed', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }
}
