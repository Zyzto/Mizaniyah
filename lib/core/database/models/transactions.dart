import 'package:drift/drift.dart';
import 'cards.dart';
import 'categories.dart';
import 'budgets.dart';

class Transactions extends Table {
  IntColumn get id => integer().autoIncrement()();
  RealColumn get amount => real()(); // Amount validation enforced at DAO level
  TextColumn get currencyCode =>
      text().withLength(min: 3, max: 3)(); // ISO 4217
  TextColumn get storeName => text().withLength(min: 1, max: 200)();
  IntColumn get cardId => integer().nullable().references(
    Cards,
    #id,
    onDelete: KeyAction.setNull,
  )();
  IntColumn get categoryId => integer().nullable().references(
    Categories,
    #id,
    onDelete: KeyAction.setNull,
  )();
  IntColumn get budgetId => integer().nullable().references(
    Budgets,
    #id,
    onDelete: KeyAction.setNull,
  )();
  DateTimeColumn get date => dateTime()();
  TextColumn get notes => text().nullable()();
  TextColumn get source => text().withDefault(
    const Constant('manual'),
  )(); // 'manual' or 'sms' (validated at DAO level)
  TextColumn get smsHash => text()
      .nullable()(); // Hash of sender + body + date for duplicate detection
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}
