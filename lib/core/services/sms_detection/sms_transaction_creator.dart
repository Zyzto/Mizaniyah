import 'package:drift/drift.dart' as drift;
import 'package:flutter_logging_service/flutter_logging_service.dart';
import 'package:mizaniyah/core/database/app_database.dart' as db;
import 'package:mizaniyah/core/database/daos/card_dao.dart';
import 'package:mizaniyah/core/database/daos/transaction_dao.dart';
import 'package:mizaniyah/core/services/sms_parsing_service.dart';
import 'package:mizaniyah/core/services/sms_detection/category_assigner.dart';
import 'package:mizaniyah/core/services/sms_detection/error_handler.dart';
import 'sms_detection_constants.dart';

/// Exception thrown when a duplicate transaction is detected
class DuplicateTransactionException implements Exception {
  final db.Transaction duplicateTransaction;
  final String smsHash;

  DuplicateTransactionException({
    required this.duplicateTransaction,
    required this.smsHash,
  });

  @override
  String toString() =>
      'DuplicateTransactionException: Transaction ${duplicateTransaction.id} already exists with smsHash=$smsHash';
}

/// Service responsible for creating transactions from SMS data
class SmsTransactionCreator with Loggable {
  final TransactionDao _transactionDao;
  final CardDao _cardDao;
  final CategoryAssigner? _categoryAssigner;

  SmsTransactionCreator(
    this._transactionDao,
    this._cardDao, {
    CategoryAssigner? categoryAssigner,
  }) : _categoryAssigner = categoryAssigner;

  /// Create a transaction from parsed SMS data
  /// Returns transaction ID if successful, null otherwise
  /// Throws DuplicateTransactionException if duplicate is detected
  Future<int?> createTransactionFromSms(
    ParsedSmsData parsedData,
    double confidence, {
    bool allowDuplicate = false,
  }) async {
    logDebug(
      'Creating transaction from SMS: store=${parsedData.storeName}, amount=${parsedData.amount}, confidence=$confidence',
    );

    try {
      // Check for duplicate transaction
      if (!allowDuplicate) {
        final smsHash = parsedData.generateSmsHash();
        final duplicate = await _transactionDao.findDuplicateBySmsHash(smsHash);
        if (duplicate != null) {
          logWarning(
            'Duplicate transaction detected: smsHash=$smsHash, existing transaction id=${duplicate.id}',
          );
          throw DuplicateTransactionException(
            duplicateTransaction: duplicate,
            smsHash: smsHash,
          );
        }
      }

      // Find card by last 4 digits if available
      int? cardId;
      final cardLast4 = parsedData.cardLast4Digits;
      if (cardLast4 != null && cardLast4.length == 4) {
        cardId = await _findCardByLast4Digits(cardLast4);
      }

      // Auto-assign category based on store name
      int? categoryId;
      if (_categoryAssigner != null && parsedData.storeName != null) {
        categoryId = await _categoryAssigner.assignCategory(
          parsedData.storeName,
        );
      }

      // Use extracted transaction date or fallback to current time
      final transactionDate = parsedData.transactionDate ?? DateTime.now();

      // Generate SMS hash for duplicate detection
      final smsHash = parsedData.generateSmsHash();

      // Create transaction
      // Note: smsHash will be set after insert via custom statement until build_runner generates the code
      final transaction = db.TransactionsCompanion(
        amount: drift.Value(parsedData.amount!),
        currencyCode: drift.Value(
          parsedData.currency ?? SmsDetectionConstants.defaultCurrency,
        ),
        storeName: drift.Value(parsedData.storeName!),
        cardId: cardId != null
            ? drift.Value(cardId)
            : const drift.Value.absent(),
        categoryId: categoryId != null
            ? drift.Value(categoryId)
            : const drift.Value.absent(),
        date: drift.Value(transactionDate),
        source: const drift.Value(SmsDetectionConstants.smsTransactionSource),
        notes: drift.Value(
          'Auto-created from SMS (confidence: ${confidence.toStringAsFixed(2)})',
        ),
      );

      final transactionId = await _transactionDao.insertTransaction(
        transaction,
      );

      // Update smsHash after insert (temporary workaround until build_runner generates code)
      // TODO: Remove this after running build_runner - smsHash will be in TransactionsCompanion
      try {
        await _transactionDao.db.customStatement(
          'UPDATE transactions SET sms_hash = ? WHERE id = ?',
          [smsHash, transactionId],
        );
      } catch (e) {
        logWarning('Failed to set smsHash for transaction $transactionId: $e');
        // Continue anyway - transaction was created successfully
      }

      logInfo(
        'Auto-created transaction with id=$transactionId, smsHash=$smsHash',
      );

      return transactionId;
    } on DuplicateTransactionException {
      rethrow;
    } catch (e, stackTrace) {
      SmsDetectionErrorHandler.logErrorWithContext(
        'createTransactionFromSms',
        e,
        stackTrace,
        additionalInfo: {
          'storeName': parsedData.storeName,
          'amount': parsedData.amount,
          'confidence': confidence,
        },
      );

      // Check if error is recoverable
      if (!SmsDetectionErrorHandler.isRecoverableError(e)) {
        logError(
          'Non-recoverable error creating transaction',
          error: e,
          stackTrace: stackTrace,
        );
        return null;
      }

      // For recoverable errors, log and return null (will be handled by confirmation)
      logWarning(
        'Recoverable error creating transaction, will be handled via confirmation',
        error: e,
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
