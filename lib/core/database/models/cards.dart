import 'package:drift/drift.dart';
import 'banks.dart';

class Cards extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get bankId =>
      integer().references(Banks, #id, onDelete: KeyAction.cascade)();
  TextColumn get last4Digits => text().withLength(min: 4, max: 4)();
  TextColumn get cardName => text().withLength(min: 1, max: 100)();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
