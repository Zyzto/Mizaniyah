import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../app_database.dart' as db;

part 'database_provider.g.dart';

/// Singleton database instance to avoid multiple database warnings.
/// This ensures all parts of the app use the same database connection.
db.AppDatabase? _databaseInstance;

db.AppDatabase getDatabase() {
  _databaseInstance ??= db.AppDatabase();
  return _databaseInstance!;
}

/// Centralized database provider for Riverpod 3.0
/// All DAO providers should depend on this provider
@riverpod
db.AppDatabase database(Ref ref) {
  return getDatabase();
}
