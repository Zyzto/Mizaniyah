import 'package:flutter_test/flutter_test.dart';
import 'package:mizaniyah/core/services/budget_service.dart';
import 'package:mizaniyah/core/database/daos/budget_dao.dart';
import 'package:mizaniyah/core/database/daos/transaction_dao.dart';
import 'package:mizaniyah/core/database/daos/category_dao.dart';
import 'package:mizaniyah/core/database/app_database.dart' as db;
import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:drift/drift.dart' hide isNotNull;

void main() {
  group('BudgetService', () {
    late BudgetService budgetService;
    late BudgetDao budgetDao;
    late TransactionDao transactionDao;
    late CategoryDao categoryDao;
    late db.AppDatabase database;

    setUp(() {
      // Use in-memory database for testing
      database = db.AppDatabase(
        LazyDatabase(() async {
          return NativeDatabase.memory();
        }),
      );
      budgetDao = BudgetDao(database);
      transactionDao = TransactionDao(database);
      categoryDao = CategoryDao(database);
      budgetService = BudgetService(budgetDao, transactionDao);
    });

    tearDown(() async {
      await database.close();
    });

    test('calculateRemainingBudget returns correct remaining amount', () async {
      // Create a category
      final categoryId = await categoryDao.insertCategory(
        const db.CategoriesCompanion(
          name: drift.Value('Test Category'),
          color: drift.Value(0xFF000000),
        ),
      );

      // Create a budget
      final budgetId = await budgetDao.insertBudget(
        db.BudgetsCompanion(
          categoryId: drift.Value(categoryId),
          amount: const drift.Value(1000.0),
          period: const drift.Value('monthly'),
          startDate: drift.Value(DateTime(2024, 1, 1)),
        ),
      );

      final budgetObj = await budgetDao.getBudgetById(budgetId);
      expect(budgetObj, isNot(null));

      // Calculate remaining (should be full amount with no transactions)
      final remaining = await budgetService.calculateRemainingBudget(
        budgetObj!,
      );
      expect(remaining, equals(1000.0));
    });

    test(
      'getBudgetStatusColor returns correct color for different percentages',
      () async {
        // Create a category
        final categoryId = await categoryDao.insertCategory(
          const db.CategoriesCompanion(
            name: drift.Value('Test Category'),
            color: drift.Value(0xFF000000),
          ),
        );

        // Create a budget
        final budgetId = await budgetDao.insertBudget(
          db.BudgetsCompanion(
            categoryId: drift.Value(categoryId),
            amount: const drift.Value(1000.0),
            period: const drift.Value('monthly'),
            startDate: drift.Value(DateTime(2024, 1, 1)),
          ),
        );

        final budgetObj = await budgetDao.getBudgetById(budgetId);
        expect(budgetObj, isNot(null));

        // No spending - should be green (0)
        final color1 = await budgetService.getBudgetStatusColor(budgetObj!);
        expect(color1, equals(0));

        // Add transaction that uses 50% of budget
        await transactionDao.insertTransaction(
          db.TransactionsCompanion(
            amount: const drift.Value(500.0),
            currencyCode: const drift.Value('USD'),
            storeName: const drift.Value('Test Store'),
            categoryId: drift.Value(categoryId),
            date: drift.Value(DateTime.now()),
          ),
        );

        // 50% used - should still be green (0)
        final color2 = await budgetService.getBudgetStatusColor(budgetObj);
        expect(color2, equals(0));

        // Add more to reach 80%
        await transactionDao.insertTransaction(
          db.TransactionsCompanion(
            amount: const drift.Value(300.0),
            currencyCode: const drift.Value('USD'),
            storeName: const drift.Value('Test Store 2'),
            categoryId: drift.Value(categoryId),
            date: drift.Value(DateTime.now()),
          ),
        );

        // 80% used - should be yellow (1)
        final color3 = await budgetService.getBudgetStatusColor(budgetObj);
        expect(color3, equals(1));

        // Add more to exceed budget
        await transactionDao.insertTransaction(
          db.TransactionsCompanion(
            amount: const drift.Value(300.0),
            currencyCode: const drift.Value('USD'),
            storeName: const drift.Value('Test Store 3'),
            categoryId: drift.Value(categoryId),
            date: drift.Value(DateTime.now()),
          ),
        );

        // Over budget - should be red (2)
        final color4 = await budgetService.getBudgetStatusColor(budgetObj);
        expect(color4, equals(2));
      },
    );
  });
}
