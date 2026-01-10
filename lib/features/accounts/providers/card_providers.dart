import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mizaniyah/core/database/app_database.dart' as db;
import 'package:flutter_logging_service/flutter_logging_service.dart';
import '../../../core/database/providers/dao_providers.dart';

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

final activeCardsProvider = FutureProvider<List<db.Card>>((ref) async {
  final dao = ref.watch(cardDaoProvider);
  try {
    return await dao.getActiveCards();
  } catch (e, stackTrace) {
    Log.error(
      'Error in activeCardsProvider',
      error: e,
      stackTrace: stackTrace,
    );
    return [];
  }
});

final cardProvider = FutureProvider.family<db.Card?, int>((ref, id) async {
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

/// Provider for card statistics (transaction count and total spent)
final cardStatisticsProvider =
    FutureProvider.family<CardStatistics, int>((ref, cardId) async {
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
