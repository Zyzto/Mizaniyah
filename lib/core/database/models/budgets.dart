import 'package:drift/drift.dart';
import 'categories.dart';

class Budgets extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get categoryId =>
      integer().references(Categories, #id, onDelete: KeyAction.cascade)();
  RealColumn get amount => real()(); // Budget amount (must be > 0, enforced via check constraint)
  TextColumn get period => text().withDefault(
    const Constant('monthly'),
  )(); // 'monthly', 'weekly', 'yearly' (validated via check constraint)
  BoolColumn get rolloverEnabled =>
      boolean().withDefault(const Constant(false))();
  RealColumn get rolloverPercentage => real().withDefault(
    const Constant(100.0),
  )(); // 0-100, percentage of unused budget to rollover (validated via check constraint)
  DateTimeColumn get startDate =>
      dateTime()(); // Start date of the budget period
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}
