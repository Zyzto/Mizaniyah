import 'package:drift/drift.dart';

class NotificationHistory extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get confirmationId =>
      integer().nullable()(); // Link to pending SMS confirmation
  IntColumn get transactionId =>
      integer().nullable()(); // Link to created transaction
  TextColumn get notificationType =>
      text()(); // 'sms_confirmation', 'transaction_created', etc.
  TextColumn get title => text()();
  TextColumn get body => text()();
  TextColumn get payload => text().nullable()(); // Additional data as JSON
  BoolColumn get wasTapped => boolean().withDefault(const Constant(false))();
  BoolColumn get wasDismissed => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
