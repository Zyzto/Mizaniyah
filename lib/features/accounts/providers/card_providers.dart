import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mizaniyah/core/database/app_database.dart' as db;
import 'package:flutter_logging_service/flutter_logging_service.dart';
import '../../../core/database/providers/dao_providers.dart';

/// All cards stream - persisted across navigation
final allCardsProvider = StreamProvider<List<db.Card>>((ref) async* {
  ref.keepAlive();
  final dao = ref.watch(cardDaoProvider);
  try {
    await for (final cards in dao.watchAllCards()) {
      yield cards;
    }
  } catch (e, stackTrace) {
    Log.error(
      'Error in allCardsProvider stream',
      error: e,
      stackTrace: stackTrace,
    );
    yield []; // Yield empty list on error to prevent crashes
  }
});

/// Active cards only - derived from stream for reactivity
final activeCardsProvider = Provider<AsyncValue<List<db.Card>>>((ref) {
  ref.keepAlive();
  final cardsAsync = ref.watch(allCardsProvider);
  return cardsAsync.whenData(
    (cards) => cards.where((c) => c.isActive).toList(),
  );
});

/// Single card by ID - kept alive
final cardProvider = FutureProvider.family<db.Card?, int>((ref, id) async {
  ref.keepAlive();
  final dao = ref.watch(cardDaoProvider);
  try {
    return await dao.getCardById(id);
  } catch (e, stackTrace) {
    Log.error(
      'Error in cardProvider for id=$id',
      error: e,
      stackTrace: stackTrace,
    );
    return null;
  }
});

/// Provider for card statistics (transaction count and total spent) - kept alive
final cardStatisticsProvider = FutureProvider.family<CardStatistics, int>((
  ref,
  cardId,
) async {
  ref.keepAlive();
  final transactionDao = ref.watch(transactionDaoProvider);
  try {
    final stats = await transactionDao.getCardStatistics(cardId);
    return CardStatistics(count: stats.count, total: stats.total);
  } catch (e, stackTrace) {
    Log.error(
      'Error in cardStatisticsProvider for cardId=$cardId',
      error: e,
      stackTrace: stackTrace,
    );
    return CardStatistics(count: 0, total: 0.0);
  }
});

class CardStatistics {
  final int count;
  final double total;

  CardStatistics({required this.count, required this.total});
}
