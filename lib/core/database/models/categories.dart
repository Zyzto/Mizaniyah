import 'package:drift/drift.dart';

class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get icon => text().nullable()(); // Material icon name
  IntColumn get color =>
      integer()(); // Color as integer (ARGB format, validated via check constraint)
  BoolColumn get isPredefined => boolean().withDefault(const Constant(false))();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  IntColumn get sortOrder => integer().withDefault(
    const Constant(0),
  )(); // Sort order for custom ordering
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
