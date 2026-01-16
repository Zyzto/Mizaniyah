// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_history_dao.dart';

// ignore_for_file: type=lint
mixin _$NotificationHistoryDaoMixin on DatabaseAccessor<AppDatabase> {
  $NotificationHistoryTable get notificationHistory =>
      attachedDatabase.notificationHistory;
  NotificationHistoryDaoManager get managers =>
      NotificationHistoryDaoManager(this);
}

class NotificationHistoryDaoManager {
  final _$NotificationHistoryDaoMixin _db;
  NotificationHistoryDaoManager(this._db);
  $$NotificationHistoryTableTableManager get notificationHistory =>
      $$NotificationHistoryTableTableManager(
        _db.attachedDatabase,
        _db.notificationHistory,
      );
}
