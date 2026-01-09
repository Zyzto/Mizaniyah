import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../category_repository.dart';
import 'package:flutter_logging_service/flutter_logging_service.dart';
import '../../banks/providers/bank_providers.dart';
import '../../../core/database/app_database.dart' as db;

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  final database = ref.watch(databaseProvider);
  return CategoryRepository(database);
});

final categoriesProvider = StreamProvider<List<db.Category>>((ref) async* {
  ref.keepAlive();
  final repository = ref.watch(categoryRepositoryProvider);
  try {
    await for (final categories in repository.watchAllCategories()) {
      yield categories;
    }
  } catch (e, stackTrace) {
    Log.error(
      'Error in categoriesProvider stream',
      error: e,
      stackTrace: stackTrace,
    );
    yield []; // Yield empty list on error to prevent crashes
  }
});

final activeCategoriesProvider = FutureProvider<List<db.Category>>((ref) async {
  final repository = ref.watch(categoryRepositoryProvider);
  try {
    return await repository.getActiveCategories();
  } catch (e, stackTrace) {
    Log.error(
      'Error in activeCategoriesProvider',
      error: e,
      stackTrace: stackTrace,
    );
    return [];
  }
});

final categoryProvider = FutureProvider.family<db.Category?, int>((
  ref,
  id,
) async {
  final repository = ref.watch(categoryRepositoryProvider);
  try {
    return await repository.getCategoryById(id);
  } catch (e, stackTrace) {
    Log.error(
      'Error in categoryProvider for id=$id',
      error: e,
      stackTrace: stackTrace,
    );
    return null;
  }
});
