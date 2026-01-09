import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../bank_repository.dart';
import 'package:flutter_logging_service/flutter_logging_service.dart';
import '../../../core/database/app_database.dart' as db_core;
import '../../../core/database/app_database.dart' as db;
import '../../../core/database/daos/card_dao.dart';

/// Singleton database instance to avoid multiple database warnings.
/// This ensures all parts of the app use the same database connection.
db_core.AppDatabase? _databaseInstance;

db_core.AppDatabase getDatabase() {
  _databaseInstance ??= db_core.AppDatabase();
  return _databaseInstance!;
}

final databaseProvider = Provider<db_core.AppDatabase>((ref) {
  return getDatabase();
});

final bankRepositoryProvider = Provider<BankRepository>((ref) {
  final database = ref.watch(databaseProvider);
  return BankRepository(database);
});

final banksProvider = StreamProvider<List<db.Bank>>((ref) async* {
  ref.keepAlive();
  final repository = ref.watch(bankRepositoryProvider);
  try {
    await for (final banks in repository.watchAllBanks()) {
      yield banks;
    }
  } catch (e, stackTrace) {
    Log.error(
      'Error in banksProvider stream',
      error: e,
      stackTrace: stackTrace,
    );
    yield []; // Yield empty list on error to prevent crashes
  }
});

final activeBanksProvider = FutureProvider<List<db.Bank>>((ref) async {
  final repository = ref.watch(bankRepositoryProvider);
  try {
    return await repository.getActiveBanks();
  } catch (e, stackTrace) {
    Log.error('Error in activeBanksProvider', error: e, stackTrace: stackTrace);
    return [];
  }
});

final bankProvider = FutureProvider.family<db.Bank?, int>((ref, id) async {
  final repository = ref.watch(bankRepositoryProvider);
  try {
    return await repository.getBankById(id);
  } catch (e, stackTrace) {
    Log.error(
      'Error in bankProvider for id=$id',
      error: e,
      stackTrace: stackTrace,
    );
    return null;
  }
});

final smsTemplatesProvider = FutureProvider.family<List<db.SmsTemplate>, int>((
  ref,
  bankId,
) async {
  final repository = ref.watch(bankRepositoryProvider);
  try {
    return await repository.getTemplatesByBankId(bankId);
  } catch (e, stackTrace) {
    Log.error(
      'Error in smsTemplatesProvider for bankId=$bankId',
      error: e,
      stackTrace: stackTrace,
    );
    return [];
  }
});

final activeSmsTemplatesProvider = FutureProvider<List<db.SmsTemplate>>((
  ref,
) async {
  final repository = ref.watch(bankRepositoryProvider);
  try {
    return await repository.getActiveTemplates();
  } catch (e, stackTrace) {
    Log.error(
      'Error in activeSmsTemplatesProvider',
      error: e,
      stackTrace: stackTrace,
    );
    return [];
  }
});

final cardsByBankProvider = FutureProvider.family<List<db.Card>, int>((
  ref,
  bankId,
) async {
  final repository = ref.watch(bankRepositoryProvider);
  try {
    return await repository.getCardsByBankId(bankId);
  } catch (e, stackTrace) {
    Log.error(
      'Error in cardsByBankProvider for bankId=$bankId',
      error: e,
      stackTrace: stackTrace,
    );
    return [];
  }
});

final allCardsProvider = StreamProvider<List<db.Card>>((ref) async* {
  ref.keepAlive();
  final database = ref.watch(databaseProvider);
  try {
    // Use CardDao directly to watch all cards
    final cardDao = CardDao(database);
    await for (final cards in cardDao.watchAllCards()) {
      yield cards;
    }
  } catch (e, stackTrace) {
    Log.error(
      'Error in allCardsProvider stream',
      error: e,
      stackTrace: stackTrace,
    );
    yield [];
  }
});
