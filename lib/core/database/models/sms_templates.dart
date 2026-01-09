import 'package:drift/drift.dart';
import 'banks.dart';

class SmsTemplates extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get bankId =>
      integer().references(Banks, #id, onDelete: KeyAction.cascade)();
  TextColumn get pattern => text()(); // Regex pattern to match SMS body
  TextColumn get extractionRules =>
      text()(); // JSON with store_name, amount, currency, card_pattern
  IntColumn get priority => integer().withDefault(
    const Constant(0),
  )(); // Higher priority = checked first
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
