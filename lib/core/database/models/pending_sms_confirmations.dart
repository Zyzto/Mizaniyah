import 'package:drift/drift.dart';

class PendingSmsConfirmations extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get smsBody => text()();
  TextColumn get smsSender => text()();
  TextColumn get parsedData => text()(); // JSON with extracted data
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get expiresAt => dateTime()(); // Auto-delete after this time
}
