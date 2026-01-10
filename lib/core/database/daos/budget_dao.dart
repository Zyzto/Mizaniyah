import 'package:drift/drift.dart';
import '../app_database.dart';
import '../models/budgets.dart';
import 'package:flutter_logging_service/flutter_logging_service.dart';
import 'base_dao_mixin.dart';
import '../validators/budget_validator.dart';

part 'budget_dao.g.dart';

@DriftAccessor(tables: [Budgets])
class BudgetDao extends DatabaseAccessor<AppDatabase>
    with _$BudgetDaoMixin, Loggable, BaseDaoMixin {
  BudgetDao(super.db);

  Future<List<Budget>> getAllBudgets() async {
    return executeWithErrorHandling<List<Budget>>(
      operationName: 'getAllBudgets',
      operation: () async {
        final result = await select(db.budgets).get();
        logInfo('getAllBudgets() returned ${result.length} budgets');
        return result;
      },
      onError: () => <Budget>[],
    );
  }

  Stream<List<Budget>> watchAllBudgets() {
    logDebug('watchAllBudgets() called');
    return select(db.budgets).watch();
  }

  Future<List<Budget>> getActiveBudgets() async {
    return executeWithErrorHandling<List<Budget>>(
      operationName: 'getActiveBudgets',
      operation: () async {
        final result = await (select(
          db.budgets,
        )..where((b) => b.isActive.equals(true))).get();
        logInfo('getActiveBudgets() returned ${result.length} budgets');
        return result;
      },
      onError: () => <Budget>[],
    );
  }

  Future<List<Budget>> getBudgetsByCategory(int categoryId) async {
    return executeWithErrorHandling<List<Budget>>(
      operationName: 'getBudgetsByCategory',
      operation: () async {
        final result =
            await (select(db.budgets)
                  ..where((b) => b.categoryId.equals(categoryId))
                  ..where((b) => b.isActive.equals(true)))
                .get();
        logInfo('getBudgetsByCategory() returned ${result.length} budgets');
        return result;
      },
      onError: () => <Budget>[],
    );
  }

  Future<Budget?> getBudgetById(int id) async {
    return executeWithErrorHandling<Budget?>(
      operationName: 'getBudgetById',
      operation: () async {
        final result = await (select(
          db.budgets,
        )..where((b) => b.id.equals(id))).getSingleOrNull();
        logDebug(
          'getBudgetById(id=$id) returned ${result != null ? "budget" : "null"}',
        );
        return result;
      },
      onError: () => null,
    );
  }

  Future<int> insertBudget(BudgetsCompanion budget) async {
    return executeWithErrorHandling<int>(
      operationName: 'insertBudget',
      operation: () async {
        BudgetValidator.validateInsert(budget);
        final id = await into(db.budgets).insert(budget);
        logInfo('insertBudget() inserted budget with id=$id');
        return id;
      },
    );
  }

  Future<bool> updateBudget(BudgetsCompanion budget) async {
    final id = budget.id.value;
    return executeWithErrorHandling<bool>(
      operationName: 'updateBudget',
      operation: () async {
        BudgetValidator.validateUpdate(budget);
        final result = await update(db.budgets).replace(budget);
        logInfo('updateBudget(id=$id) updated successfully');
        return result;
      },
    );
  }

  Future<int> deleteBudget(int id) async {
    return executeWithErrorHandling<int>(
      operationName: 'deleteBudget',
      operation: () async {
        final result = await (delete(
          db.budgets,
        )..where((b) => b.id.equals(id))).go();
        logInfo('deleteBudget(id=$id) deleted $result rows');
        return result;
      },
    );
  }

  /// Get count of active budgets (optimized with SQL aggregation)
  Future<int> getActiveBudgetsCount() async {
    return executeWithErrorHandling<int>(
      operationName: 'getActiveBudgetsCount',
      operation: () async {
        final query = selectOnly(db.budgets)
          ..addColumns([db.budgets.id.count()])
          ..where(db.budgets.isActive.equals(true));

        final result = await query.getSingle();
        final count = result.read(db.budgets.id.count()) ?? 0;
        logInfo('getActiveBudgetsCount() returned $count');
        return count;
      },
      onError: () => 0,
    );
  }

  /// Get count of budgets by category (optimized with SQL aggregation)
  Future<int> getBudgetsCountByCategory(int categoryId) async {
    return executeWithErrorHandling<int>(
      operationName: 'getBudgetsCountByCategory',
      operation: () async {
        final query = selectOnly(db.budgets)
          ..addColumns([db.budgets.id.count()])
          ..where(db.budgets.categoryId.equals(categoryId))
          ..where(db.budgets.isActive.equals(true));

        final result = await query.getSingle();
        final count = result.read(db.budgets.id.count()) ?? 0;
        logInfo(
          'getBudgetsCountByCategory(categoryId=$categoryId) returned $count',
        );
        return count;
      },
      onError: () => 0,
    );
  }
}
