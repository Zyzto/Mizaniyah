import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/navigation/route_paths.dart';
import 'pages/budget_form_page.dart';
import 'pages/budgets_page.dart';
import '../../../core/database/app_database.dart' as db;
import '../../../core/database/daos/budget_dao.dart';
import '../../../core/database/providers/database_provider.dart';

/// Budget routes for the application (inside ShellRoute - with nav bar)
List<RouteBase> getBudgetRoutes() {
  return [
    GoRoute(
      path: RoutePaths.budget,
      builder: (context, state) => const BudgetsPageLoader(),
    ),
  ];
}

/// Budget form routes (outside ShellRoute - full screen without nav bar)
List<RouteBase> getBudgetFormRoutes() {
  return [
    GoRoute(
      path: RoutePaths.budgetsAdd,
      builder: (context, state) => const BudgetFormPage(),
    ),
    GoRoute(
      path: '/budgets/:id/edit',
      builder: (context, state) {
        final id = int.tryParse(state.pathParameters['id'] ?? '');
        if (id == null) {
          // Redirect to accounts page (budgets tab)
          return const BudgetFormPage();
        }
        return BudgetFormPageLoader(budgetId: id);
      },
    ),
  ];
}

/// Loader widget for budgets page (creates TabController)
class BudgetsPageLoader extends StatefulWidget {
  const BudgetsPageLoader({super.key});

  @override
  State<BudgetsPageLoader> createState() => _BudgetsPageLoaderState();
}

class _BudgetsPageLoaderState extends State<BudgetsPageLoader>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BudgetsPage(tabController: _tabController);
  }
}

/// Loader widget for budget form page (edit mode)
class BudgetFormPageLoader extends StatelessWidget {
  final int budgetId;

  const BudgetFormPageLoader({super.key, required this.budgetId});

  @override
  Widget build(BuildContext context) {
    final database = getDatabase();
    final budgetDao = BudgetDao(database);

    return FutureBuilder<db.Budget?>(
      future: budgetDao.getBudgetById(budgetId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final budget = snapshot.data;
        if (budget == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            context.go(RoutePaths.budget);
          });
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return BudgetFormPage(budget: budget);
      },
    );
  }
}
