import 'package:drift/drift.dart' as drift;
import 'package:flutter_logging_service/flutter_logging_service.dart';
import 'package:mizaniyah/core/database/app_database.dart' as db;
import 'package:mizaniyah/core/database/daos/card_dao.dart';
import 'package:mizaniyah/core/database/daos/transaction_dao.dart';
import 'package:mizaniyah/core/services/sms_parsing_service.dart';
import 'sms_detection_constants.dart';

/// Service responsible for creating transactions from SMS data
class SmsTransactionCreator with Loggable {
  final TransactionDao _transactionDao;
  final CardDao _cardDao;

  SmsTransactionCreator(this._transactionDao, this._cardDao);

  /// Create a transaction from parsed SMS data
  /// Returns transaction ID if successful, null otherwise
  Future<int?> createTransactionFromSms(
    ParsedSmsData parsedData,
    double confidence,
  ) async {
    logDebug(
      'Creating transaction from SMS: store=${parsedData.storeName}, amount=${parsedData.amount}, confidence=$confidence',
    );

    try {
      // Find card by last 4 digits if available
      int? cardId;
      if (parsedData.cardLast4Digits != null &&
          parsedData.cardLast4Digits!.length == 4) {
        cardId = await _findCardByLast4Digits(parsedData.cardLast4Digits!);
      }

      // Create transaction
      final transaction = db.TransactionsCompanion(
        amount: drift.Value(parsedData.amount!),
        currencyCode: drift.Value(
          parsedData.currency ?? SmsDetectionConstants.defaultCurrency,
        ),
        storeName: drift.Value(parsedData.storeName!),
        cardId: drift.Value(cardId),
        categoryId:
            const drift.Value.absent(), // Category can be assigned later
        date: drift.Value(DateTime.now()),
        source: const drift.Value(SmsDetectionConstants.smsTransactionSource),
        notes: drift.Value(
          'Auto-created from SMS (confidence: ${confidence.toStringAsFixed(2)})',
        ),
      );

      final transactionId = await _transactionDao.insertTransaction(
        transaction,
      );
      logInfo('Auto-created transaction with id=$transactionId');

      return transactionId;
    } catch (e, stackTrace) {
      logError(
        'Failed to create transaction from SMS',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  /// Find card by last 4 digits
  Future<int?> _findCardByLast4Digits(String last4Digits) async {
    try {
      final card = await _cardDao.getCardByLast4Digits(last4Digits);
      if (card != null) {
        logInfo('Found card with last 4 digits: $last4Digits');
        return card.id;
      }
      return null;
    } catch (e, stackTrace) {
      logError(
        'Failed to find card by last 4 digits: $last4Digits',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }
}
