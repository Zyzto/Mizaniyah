import 'package:drift/drift.dart';
import 'banks.dart';

class PendingSmsConfirmations extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get smsBody => text()();
  TextColumn get smsSender => text()();
  IntColumn get bankId => integer().nullable().references(
    Banks,
    #id,
    onDelete: KeyAction.setNull,
  )();
  TextColumn get parsedData => text()(); // JSON with extracted data
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get expiresAt => dateTime()(); // Auto-delete after this time
}
