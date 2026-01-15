import 'package:drift/drift.dart';
import '../app_database.dart';
import '../models/cards.dart';
import 'package:flutter_logging_service/flutter_logging_service.dart';
import 'base_dao_mixin.dart';
import '../validators/card_validator.dart';

part 'card_dao.g.dart';

@DriftAccessor(tables: [Cards])
class CardDao extends DatabaseAccessor<AppDatabase>
    with _$CardDaoMixin, Loggable, BaseDaoMixin {
  CardDao(super.db);

  Future<List<Card>> getAllCards() async {
    return executeWithErrorHandling<List<Card>>(
      operationName: 'getAllCards',
      operation: () async {
        final result = await select(db.cards).get();
        logInfo('getAllCards() returned ${result.length} cards');
        return result;
      },
      onError: () => <Card>[],
    );
  }

  Stream<List<Card>> watchAllCards() {
    logDebug('watchAllCards() called');
    return select(db.cards).watch();
  }

  Future<List<Card>> getActiveCards() async {
    return executeWithErrorHandling<List<Card>>(
      operationName: 'getActiveCards',
      operation: () async {
        final result = await (select(
          db.cards,
        )..where((c) => c.isActive.equals(true))).get();
        logInfo('getActiveCards() returned ${result.length} cards');
        return result;
      },
      onError: () => <Card>[],
    );
  }

  Future<Card?> getCardById(int id) async {
    return executeWithErrorHandling<Card?>(
      operationName: 'getCardById',
      operation: () async {
        final result = await (select(
          db.cards,
        )..where((c) => c.id.equals(id))).getSingleOrNull();
        logDebug(
          'getCardById(id=$id) returned ${result != null ? "card" : "null"}',
        );
        return result;
      },
      onError: () => null,
    );
  }

  Future<Card?> getCardByLast4Digits(String last4Digits) async {
    return executeWithErrorHandling<Card?>(
      operationName: 'getCardByLast4Digits',
      operation: () async {
        final result = await (select(
          db.cards,
        )..where((c) => c.last4Digits.equals(last4Digits))).getSingleOrNull();
        logDebug(
          'getCardByLast4Digits() returned ${result != null ? "card" : "null"}',
        );
        return result;
      },
      onError: () => null,
    );
  }

  Future<int> insertCard(CardsCompanion card) async {
    return executeWithErrorHandling<int>(
      operationName: 'insertCard',
      operation: () async {
        CardValidator.validateInsert(card);
        final id = await into(db.cards).insert(card);
        logInfo('insertCard() inserted card with id=$id');
        return id;
      },
    );
  }

  Future<bool> updateCard(CardsCompanion card) async {
    final id = card.id.value;
    return executeWithErrorHandling<bool>(
      operationName: 'updateCard',
      operation: () async {
        CardValidator.validateUpdate(card);
        final result = await update(db.cards).replace(card);
        logInfo('updateCard(id=$id) updated successfully');
        return result;
      },
    );
  }

  Future<int> deleteCard(int id) async {
    return executeWithErrorHandling<int>(
      operationName: 'deleteCard',
      operation: () async {
        final result = await (delete(
          db.cards,
        )..where((c) => c.id.equals(id))).go();
        logInfo('deleteCard(id=$id) deleted $result rows');
        return result;
      },
    );
  }

  /// Get count of active cards (optimized with SQL aggregation)
  Future<int> getActiveCardsCount() async {
    return executeWithErrorHandling<int>(
      operationName: 'getActiveCardsCount',
      operation: () async {
        final query = selectOnly(db.cards)
          ..addColumns([db.cards.id.count()])
          ..where(db.cards.isActive.equals(true));

        final result = await query.getSingle();
        final count = result.read(db.cards.id.count()) ?? 0;
        logInfo('getActiveCardsCount() returned $count');
        return count;
      },
      onError: () => 0,
    );
  }
}
