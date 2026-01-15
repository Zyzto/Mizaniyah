import 'package:drift/drift.dart';
import 'categories.dart';

/// Category mappings for auto-assigning categories based on store name patterns
class CategoryMappings extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get storeNamePattern =>
      text().withLength(min: 1, max: 200)(); // Pattern to match store names
  IntColumn get categoryId =>
      integer().references(Categories, #id, onDelete: KeyAction.cascade)();
  RealColumn get confidence =>
      real().withDefault(const Constant(1.0))(); // Match confidence (0.0-1.0)
  BoolColumn get isActive => boolean().withDefault(
    const Constant(true),
  )(); // Whether mapping is active
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}
