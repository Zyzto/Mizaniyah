import 'package:drift/drift.dart';
import '../app_database.dart';
import '../models/cards.dart';
import 'package:flutter_logging_service/flutter_logging_service.dart';

part 'card_dao.g.dart';

@DriftAccessor(tables: [Cards])
class CardDao extends DatabaseAccessor<AppDatabase>
    with _$CardDaoMixin, Loggable {
  CardDao(super.db);

  Future<List<Card>> getAllCards() async {
    logDebug('getAllCards() called');
    try {
      final result = await select(db.cards).get();
      logInfo('getAllCards() returned ${result.length} cards');
      return result;
    } catch (e, stackTrace) {
      logError('getAllCards() failed', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Stream<List<Card>> watchAllCards() {
    logDebug('watchAllCards() called');
    return select(db.cards).watch();
  }

  Future<List<Card>> getCardsByBankId(int bankId) async {
    logDebug('getCardsByBankId(bankId=$bankId) called');
    try {
      final result = await (select(
        db.cards,
      )..where((c) => c.bankId.equals(bankId))).get();
      logInfo('getCardsByBankId() returned ${result.length} cards');
      return result;
    } catch (e, stackTrace) {
      logError('getCardsByBankId() failed', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<List<Card>> getActiveCards() async {
    logDebug('getActiveCards() called');
    try {
      final result = await (select(
        db.cards,
      )..where((c) => c.isActive.equals(true))).get();
      logInfo('getActiveCards() returned ${result.length} cards');
      return result;
    } catch (e, stackTrace) {
      logError('getActiveCards() failed', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<Card?> getCardById(int id) async {
    logDebug('getCardById(id=$id) called');
    try {
      final result = await (select(
        db.cards,
      )..where((c) => c.id.equals(id))).getSingleOrNull();
      logDebug(
        'getCardById(id=$id) returned ${result != null ? "card" : "null"}',
      );
      return result;
    } catch (e, stackTrace) {
      logError('getCardById(id=$id) failed', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<Card?> getCardByLast4Digits(String last4Digits) async {
    logDebug('getCardByLast4Digits(last4Digits=$last4Digits) called');
    try {
      final result = await (select(
        db.cards,
      )..where((c) => c.last4Digits.equals(last4Digits))).getSingleOrNull();
      logDebug(
        'getCardByLast4Digits() returned ${result != null ? "card" : "null"}',
      );
      return result;
    } catch (e, stackTrace) {
      logError(
        'getCardByLast4Digits() failed',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<int> insertCard(CardsCompanion card) async {
    logDebug('insertCard(name=${card.cardName.value}) called');
    try {
      final id = await into(db.cards).insert(card);
      logInfo('insertCard() inserted card with id=$id');
      return id;
    } catch (e, stackTrace) {
      logError('insertCard() failed', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<bool> updateCard(CardsCompanion card) async {
    final id = card.id.value;
    logDebug('updateCard(id=$id) called');
    try {
      final result = await update(db.cards).replace(card);
      logInfo('updateCard(id=$id) updated successfully');
      return result;
    } catch (e, stackTrace) {
      logError('updateCard(id=$id) failed', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<int> deleteCard(int id) async {
    logDebug('deleteCard(id=$id) called');
    try {
      final result = await (delete(
        db.cards,
      )..where((c) => c.id.equals(id))).go();
      logInfo('deleteCard(id=$id) deleted $result rows');
      return result;
    } catch (e, stackTrace) {
      logError('deleteCard(id=$id) failed', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }
}
