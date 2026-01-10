import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/navigation/route_paths.dart';
import 'pages/transactions_list_page.dart';
import 'pages/transaction_form_page.dart';
import 'pages/transaction_detail_page.dart';
import '../../../core/database/app_database.dart' as db;
import '../../../core/database/daos/transaction_dao.dart';
import '../../../core/database/providers/database_provider.dart';

/// Transaction routes for the application (inside ShellRoute - with nav bar)
/// Note: Transactions are displayed in the home page, so this route is kept for backward compatibility
List<RouteBase> getTransactionRoutes() {
  return [
    // Keep transactions route for backward compatibility (redirects to home)
    GoRoute(
      path: RoutePaths.transactions,
      redirect: (context, state) => RoutePaths.home,
    ),
    GoRoute(
      path: '/transactions/:id',
      builder: (context, state) {
        final id = int.tryParse(state.pathParameters['id'] ?? '');
        if (id == null) {
          return const TransactionsListPage();
        }
        // Load transaction from database
        return TransactionDetailPageLoader(transactionId: id);
      },
    ),
  ];
}

/// Transaction form routes (outside ShellRoute - full screen without nav bar)
List<RouteBase> getTransactionFormRoutes() {
  return [
    GoRoute(
      path: RoutePaths.transactionsAdd,
      builder: (context, state) => const TransactionFormPage(),
    ),
    GoRoute(
      path: '/transactions/:id/edit',
      builder: (context, state) {
        final id = int.tryParse(state.pathParameters['id'] ?? '');
        if (id == null) {
          return const TransactionsListPage();
        }
        // Load transaction from database
        return TransactionFormPageLoader(transactionId: id);
      },
    ),
  ];
}

/// Loader widget for transaction detail page
/// This loads the transaction from the database based on route parameter
class TransactionDetailPageLoader extends StatelessWidget {
  final int transactionId;

  const TransactionDetailPageLoader({
    super.key,
    required this.transactionId,
  });

  @override
  Widget build(BuildContext context) {
    final database = getDatabase();
    final transactionDao = TransactionDao(database);

    return FutureBuilder<db.Transaction?>(
      future: transactionDao.getTransactionById(transactionId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final transaction = snapshot.data;
        if (transaction == null) {
          // Transaction not found, go back to list
          WidgetsBinding.instance.addPostFrameCallback((_) {
            context.go(RoutePaths.home);
          });
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return TransactionDetailPage(transaction: transaction);
      },
    );
  }
}

/// Loader widget for transaction form page (edit mode)
/// This loads the transaction from the database based on route parameter
class TransactionFormPageLoader extends StatelessWidget {
  final int transactionId;

  const TransactionFormPageLoader({
    super.key,
    required this.transactionId,
  });

  @override
  Widget build(BuildContext context) {
    final database = getDatabase();
    final transactionDao = TransactionDao(database);

    return FutureBuilder<db.Transaction?>(
      future: transactionDao.getTransactionById(transactionId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final transaction = snapshot.data;
        if (transaction == null) {
          // Transaction not found, go back to list
          WidgetsBinding.instance.addPostFrameCallback((_) {
            context.go(RoutePaths.home);
          });
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return TransactionFormPage(transaction: transaction);
      },
    );
  }
}
