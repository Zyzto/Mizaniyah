import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_logging_service/flutter_logging_service.dart';
import '../../../core/database/app_database.dart' as db;
import '../../../core/database/providers/dao_providers.dart';

/// All categories stream - persisted across navigation
final categoriesProvider = StreamProvider<List<db.Category>>((ref) async* {
  ref.keepAlive();
  final dao = ref.watch(categoryDaoProvider);
  try {
    await for (final categories in dao.watchAllCategories()) {
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

/// Active categories provider
final activeCategoriesProvider = FutureProvider<List<db.Category>>((ref) async {
  final dao = ref.watch(categoryDaoProvider);
  try {
    return await dao.getActiveCategories();
  } catch (e, stackTrace) {
    Log.error(
      'Error in activeCategoriesProvider',
      error: e,
      stackTrace: stackTrace,
    );
    return [];
  }
});

/// Single category by ID provider
final categoryProvider = FutureProvider.family<db.Category?, int>((
  ref,
  id,
) async {
  final dao = ref.watch(categoryDaoProvider);
  try {
    return await dao.getCategoryById(id);
  } catch (e, stackTrace) {
    Log.error(
      'Error in categoryProvider for id=$id',
      error: e,
      stackTrace: stackTrace,
    );
    return null;
  }
});
