// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pending_sms_confirmation_dao.dart';

// ignore_for_file: type=lint
mixin _$PendingSmsConfirmationDaoMixin on DatabaseAccessor<AppDatabase> {
  $PendingSmsConfirmationsTable get pendingSmsConfirmations =>
      attachedDatabase.pendingSmsConfirmations;
  PendingSmsConfirmationDaoManager get managers =>
      PendingSmsConfirmationDaoManager(this);
}

class PendingSmsConfirmationDaoManager {
  final _$PendingSmsConfirmationDaoMixin _db;
  PendingSmsConfirmationDaoManager(this._db);
  $$PendingSmsConfirmationsTableTableManager get pendingSmsConfirmations =>
      $$PendingSmsConfirmationsTableTableManager(
        _db.attachedDatabase,
        _db.pendingSmsConfirmations,
      );
}
