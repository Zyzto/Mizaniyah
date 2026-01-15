import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/navigation/route_paths.dart';
import 'pages/categories_page.dart';
import 'pages/category_form_page.dart';
import '../../../core/database/app_database.dart' as db;
import '../../../core/database/daos/category_dao.dart';
import '../../../core/database/providers/database_provider.dart';

/// Category routes for the application (inside ShellRoute - with nav bar)
List<RouteBase> getCategoryRoutes() {
  return [
    GoRoute(
      path: RoutePaths.categories,
      builder: (context, state) => const CategoriesPage(),
    ),
  ];
}

/// Category form routes (outside ShellRoute - full screen without nav bar)
List<RouteBase> getCategoryFormRoutes() {
  return [
    GoRoute(
      path: RoutePaths.categoriesAdd,
      builder: (context, state) => const CategoryFormPage(),
    ),
    GoRoute(
      path: '/categories/:id/edit',
      builder: (context, state) {
        final id = int.tryParse(state.pathParameters['id'] ?? '');
        if (id == null) {
          return const CategoriesPage();
        }
        return CategoryFormPageLoader(categoryId: id);
      },
    ),
  ];
}

/// Loader widget for category form page (edit mode)
class CategoryFormPageLoader extends StatelessWidget {
  final int categoryId;

  const CategoryFormPageLoader({super.key, required this.categoryId});

  @override
  Widget build(BuildContext context) {
    final database = getDatabase();
    final categoryDao = CategoryDao(database);

    return FutureBuilder<db.Category?>(
      future: categoryDao.getCategoryById(categoryId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final category = snapshot.data;
        if (category == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            context.go(RoutePaths.categories);
          });
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return CategoryFormPage(category: category);
      },
    );
  }
}
