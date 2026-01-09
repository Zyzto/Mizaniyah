import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_logging_service/flutter_logging_service.dart';
import 'package:drift/drift.dart' as drift;
import 'package:mizaniyah/core/database/app_database.dart' as db;
import 'package:mizaniyah/features/banks/bank_repository.dart';
import 'package:mizaniyah/features/pending_sms/pending_sms_repository.dart';
import 'package:mizaniyah/features/transactions/transaction_repository.dart';
import 'package:mizaniyah/features/categories/category_repository.dart';
import 'package:mizaniyah/core/services/sms_parsing_service.dart';
import 'package:mizaniyah/core/services/notification_service.dart';
import 'package:another_telephony/telephony.dart';

/// Background message handler for incoming SMS (when app is in background)
/// This must be a top-level function
@pragma('vm:entry-point')
void backgroundMessageHandler(SmsMessage message) async {
  // Handle background SMS messages
  // Note: Heavy computations should be avoided here as Android may kill long-running operations
  // Initialize logging service in background isolate if needed
  try {
    // Log the received SMS (minimal processing in background)
    // The actual processing will happen when the app comes to foreground
    // via the foreground handler
  } catch (e) {
    // Silently fail in background handler to avoid crashes
  }
}

/// SMS Detection Service
/// Listens for incoming SMS and processes them for transaction detection
/// Android only - iOS support is on hold
class SmsDetectionService with Loggable {
  static SmsDetectionService? _instance;
  static SmsDetectionService get instance {
    _instance ??= SmsDetectionService._();
    return _instance!;
  }

  SmsDetectionService._();

  BankRepository? _bankRepository;
  PendingSmsRepository? _pendingSmsRepository;
  TransactionRepository? _transactionRepository;
  CategoryRepository? _categoryRepository;
  Telephony? _telephony;
  bool _isInitialized = false;
  bool _isListening = false;

  /// Initialize the SMS detection service
  Future<void> init(
    BankRepository bankRepository,
    PendingSmsRepository pendingSmsRepository, {
    TransactionRepository? transactionRepository,
    CategoryRepository? categoryRepository,
  }) async {
    if (_isInitialized) {
      logWarning('SmsDetectionService already initialized');
      return;
    }

    _bankRepository = bankRepository;
    _pendingSmsRepository = pendingSmsRepository;
    _transactionRepository = transactionRepository;
    _categoryRepository = categoryRepository;

    // This app is Android-only (iOS on hold)
    if (kIsWeb) {
      logWarning(
        'SMS detection: This app is Android-only, web platform not supported',
      );
      _isInitialized = true;
      return;
    }

    try {
      _telephony = Telephony.instance;

      // Request SMS permissions
      final permissionsGranted =
          await _telephony!.requestPhoneAndSmsPermissions;
      if (permissionsGranted == false) {
        logWarning('SMS permissions not granted, SMS detection will not work');
        _isInitialized = true;
        return;
      }

      await _startListening();
      _isInitialized = true;
      logInfo('SmsDetectionService initialized successfully');
    } catch (e, stackTrace) {
      logError(
        'Failed to initialize SmsDetectionService',
        error: e,
        stackTrace: stackTrace,
      );
      // Don't throw - app can function without SMS detection
    }
  }

  /// Start listening for SMS
  Future<void> _startListening() async {
    if (_isListening || _telephony == null) {
      logWarning('SMS listening already active or telephony not initialized');
      return;
    }

    try {
      _telephony!.listenIncomingSms(
        onNewMessage: _handleSms,
        onBackgroundMessage: backgroundMessageHandler,
        listenInBackground: true,
      );

      _isListening = true;
      logInfo('Started listening for SMS');
    } catch (e, stackTrace) {
      logError(
        'Failed to start SMS listening',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Handle incoming SMS
  Future<void> _handleSms(SmsMessage message) async {
    final sender = message.address ?? '';
    final body = message.body ?? '';

    logDebug('Received SMS from $sender: $body');

    if (_bankRepository == null || _pendingSmsRepository == null) {
      logWarning('SmsDetectionService not initialized, ignoring SMS');
      return;
    }

    try {
      // Get active banks
      final banks = await _bankRepository!.getActiveBanks();

      // Find matching bank by sender pattern
      db.Bank? matchedBank;
      for (final bank in banks) {
        if (bank.smsSenderPattern != null &&
            bank.smsSenderPattern!.isNotEmpty) {
          final pattern = RegExp(bank.smsSenderPattern!, caseSensitive: false);
          if (pattern.hasMatch(sender)) {
            matchedBank = bank;
            break;
          }
        }
      }

      if (matchedBank == null) {
        logDebug('SMS sender $sender does not match any bank pattern');
        return;
      }

      logInfo('Matched SMS to bank: ${matchedBank.name}');

      // Get active templates for this bank
      final templates = await _bankRepository!.getTemplatesByBankId(
        matchedBank.id,
      );

      if (templates.isEmpty) {
        logWarning('No active templates found for bank ${matchedBank.name}');
        return;
      }

      // Try to parse SMS with templates
      final match = SmsParsingService.findMatchingTemplate(body, templates);

      if (match == null) {
        logDebug(
          'SMS does not match any template for bank ${matchedBank.name}',
        );
        return;
      }

      final parsedData = match['parsed_data'] as ParsedSmsData;
      final confidence = match['confidence'] as double? ?? 0.5;

      // Validate parsed data (should not be null if parsing succeeded, but check for safety)
      if (parsedData.storeName == null || parsedData.amount == null) {
        logWarning(
          'Parsed SMS data missing required fields: storeName=${parsedData.storeName}, amount=${parsedData.amount}',
        );
        return;
      }

      logInfo(
        'Successfully parsed SMS: store=${parsedData.storeName}, amount=${parsedData.amount}, confidence=$confidence',
      );

      // Store as pending confirmation (include confidence in parsed data)
      final parsedDataWithConfidence = {
        ...parsedData.toJson(),
        'confidence': confidence,
      };

      final expiresAt = DateTime.now().add(const Duration(hours: 24));
      final confirmation = db.PendingSmsConfirmationsCompanion(
        smsBody: drift.Value(body),
        smsSender: drift.Value(sender),
        bankId: drift.Value(matchedBank.id),
        parsedData: drift.Value(jsonEncode(parsedDataWithConfidence)),
        expiresAt: drift.Value(expiresAt),
      );

      final confirmationId = await _pendingSmsRepository!.createConfirmation(
        confirmation,
      );
      logInfo(
        'Created pending confirmation with id=$confirmationId, confidence=$confidence',
      );

      // Smart auto-create: if confidence is high (>= 0.7), auto-create transaction
      if (confidence >= 0.7 &&
          _transactionRepository != null &&
          _bankRepository != null) {
        logInfo(
          'High confidence match (>= 0.7), attempting auto-create transaction',
        );
        try {
          // Find card by last 4 digits if available
          int? cardId;
          if (parsedData.cardLast4Digits != null &&
              parsedData.cardLast4Digits!.length == 4) {
            final card = await _bankRepository!.getCardByLast4Digits(
              parsedData.cardLast4Digits!,
            );
            cardId = card?.id;
            if (cardId != null) {
              logInfo(
                'Found card with last 4 digits: ${parsedData.cardLast4Digits}',
              );
            }
          }

          // Create transaction
          final transaction = db.TransactionsCompanion(
            amount: drift.Value(parsedData.amount!),
            currencyCode: drift.Value(parsedData.currency ?? 'USD'),
            storeName: drift.Value(parsedData.storeName!),
            cardId: drift.Value(cardId),
            categoryId:
                const drift.Value.absent(), // Category can be assigned later
            date: drift.Value(DateTime.now()),
            source: const drift.Value('sms'),
            notes: drift.Value(
              'Auto-created from SMS (confidence: ${confidence.toStringAsFixed(2)})',
            ),
          );

          final transactionId = await _transactionRepository!.createTransaction(
            transaction,
          );
          logInfo('Auto-created transaction with id=$transactionId');

          // Delete the pending confirmation since we auto-created
          await _pendingSmsRepository!.deleteConfirmation(confirmationId);
          logInfo(
            'Deleted pending confirmation $confirmationId after auto-create',
          );

          // Transaction auto-created successfully - no notification needed
          // User will see it in their transactions list
          logInfo(
            'Transaction auto-created successfully, skipping notification',
          );
          return; // Don't show the regular confirmation notification
        } catch (e, stackTrace) {
          logError(
            'Failed to auto-create transaction, keeping as pending confirmation',
            error: e,
            stackTrace: stackTrace,
          );
          // Continue to show notification for manual confirmation
        }
      }

      // Show notification for manual confirmation (parsedData.storeName and parsedData.amount are guaranteed non-null here)
      await NotificationService.showSmsConfirmationNotification(
        confirmationId,
        parsedData.storeName!,
        parsedData.amount!,
        parsedData.currency ??
            'USD', // Currency defaults to USD in parsing service, but keep null check for safety
      );
    } catch (e, stackTrace) {
      logError('Failed to process SMS', error: e, stackTrace: stackTrace);
    }
  }

  /// Stop listening for SMS
  Future<void> stop() async {
    // another_telephony doesn't have an explicit stop method
    // The listener will stop when the app is closed
    _isListening = false;
    logInfo('Stopped listening for SMS');
  }

  /// Dispose the service
  Future<void> dispose() async {
    await stop();
    _isInitialized = false;
    logInfo('SmsDetectionService disposed');
  }
}
