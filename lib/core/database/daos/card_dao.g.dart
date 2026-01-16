// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'card_dao.dart';

// ignore_for_file: type=lint
mixin _$CardDaoMixin on DatabaseAccessor<AppDatabase> {
  $AccountsTable get accounts => attachedDatabase.accounts;
  $CardsTable get cards => attachedDatabase.cards;
  CardDaoManager get managers => CardDaoManager(this);
}

class CardDaoManager {
  final _$CardDaoMixin _db;
  CardDaoManager(this._db);
  $$AccountsTableTableManager get accounts =>
      $$AccountsTableTableManager(_db.attachedDatabase, _db.accounts);
  $$CardsTableTableManager get cards =>
      $$CardsTableTableManager(_db.attachedDatabase, _db.cards);
}
