import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_logging_service/flutter_logging_service.dart';
import 'package:another_telephony/telephony.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:mizaniyah/core/services/sms_detection/sms_matcher.dart';
import 'package:mizaniyah/core/services/sms_detection/sms_transaction_creator.dart';
import 'package:mizaniyah/core/services/sms_detection/sms_confirmation_handler.dart';
import 'package:mizaniyah/core/services/sms_detection/sms_detection_constants.dart';
import 'package:mizaniyah/core/services/sms_detection/category_assigner.dart';
import 'package:mizaniyah/core/database/daos/category_mapping_dao.dart';
import 'package:mizaniyah/core/database/daos/sms_template_dao.dart';
import 'package:mizaniyah/core/database/daos/card_dao.dart';
import 'package:mizaniyah/core/database/daos/pending_sms_confirmation_dao.dart';
import 'package:mizaniyah/core/database/daos/transaction_dao.dart';
import 'package:mizaniyah/core/database/daos/category_dao.dart';

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
  // Singleton instance for backward compatibility
  static SmsDetectionService? _instance;
  static SmsDetectionService get instance {
    _instance ??= SmsDetectionService._();
    return _instance!;
  }

  SmsDetectionService._();

  // Service dependencies
  SmsMatcher? _smsMatcher;
  SmsTransactionCreator? _transactionCreator;
  SmsConfirmationHandler? _confirmationHandler;
  Telephony? _telephony;
  bool _isInitialized = false;
  bool _isListening = false;
  bool _autoConfirm = false;
  double _confidenceThreshold =
      SmsDetectionConstants.defaultAutoCreateConfidenceThreshold;

  /// Public getter to check if SMS listening is active
  bool get isListening => _isListening;

  /// Initialize the SMS detection service
  /// Prefer using the factory constructor for new code
  Future<void> init(
    SmsTemplateDao smsTemplateDao,
    PendingSmsConfirmationDao pendingSmsDao, {
    TransactionDao? transactionDao,
    CardDao? cardDao,
    CategoryDao? categoryDao,
    bool shouldStartListening = true,
  }) async {
    if (_isInitialized) {
      logWarning('SmsDetectionService already initialized');
      return;
    }

    // Initialize service dependencies
    _smsMatcher = SmsMatcher(smsTemplateDao);

    if (transactionDao != null && cardDao != null) {
      _transactionCreator = SmsTransactionCreator(transactionDao, cardDao);
    }

    _confirmationHandler = SmsConfirmationHandler(pendingSmsDao);

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

      // Check and request SMS permissions
      final hasPermissions = await _checkAndRequestSmsPermissions();
      if (!hasPermissions) {
        logWarning(
          'SMS permissions not granted, SMS detection will not work. '
          'Please grant SMS permissions in app settings.',
        );
        _isInitialized = true;
        return;
      }

      // Only start listening if enabled
      if (shouldStartListening) {
        await _startListening();
      }
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

  /// Factory constructor for dependency injection (preferred for new code)
  factory SmsDetectionService.create({
    required SmsTemplateDao smsTemplateDao,
    required PendingSmsConfirmationDao pendingSmsDao,
    TransactionDao? transactionDao,
    CardDao? cardDao,
    CategoryDao? categoryDao,
    CategoryMappingDao? categoryMappingDao,
  }) {
    final service = SmsDetectionService._();
    service._smsMatcher = SmsMatcher(smsTemplateDao);

    if (transactionDao != null && cardDao != null) {
      CategoryAssigner? categoryAssigner;
      if (categoryMappingDao != null) {
        categoryAssigner = CategoryAssigner(categoryMappingDao);
      }
      service._transactionCreator = SmsTransactionCreator(
        transactionDao,
        cardDao,
        categoryAssigner: categoryAssigner,
      );
    }

    service._confirmationHandler = SmsConfirmationHandler(pendingSmsDao);

    return service;
  }

  /// Check if SMS permissions are granted
  Future<bool> _checkSmsPermissions() async {
    if (kIsWeb) {
      return false;
    }

    try {
      final smsStatus = await Permission.sms.status;
      return smsStatus.isGranted;
    } catch (e, stackTrace) {
      logError(
        'Failed to check SMS permissions',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  /// Check and request SMS permissions with user-friendly error handling
  Future<bool> _checkAndRequestSmsPermissions() async {
    if (kIsWeb) {
      return false;
    }

    try {
      // First check if already granted
      if (await _checkSmsPermissions()) {
        return true;
      }

      // Request permissions using both methods for compatibility
      // Try permission_handler first (more reliable)
      final smsStatus = await Permission.sms.request();

      if (smsStatus.isGranted) {
        logInfo('SMS permissions granted via permission_handler');
        return true;
      }

      // Fallback to telephony's permission request
      if (_telephony != null) {
        final telephonyGranted =
            await _telephony!.requestPhoneAndSmsPermissions;
        if (telephonyGranted == true) {
          logInfo('SMS permissions granted via telephony');
          return true;
        }
      }

      // Permission denied
      if (smsStatus.isPermanentlyDenied) {
        logWarning(
          'SMS permissions permanently denied. '
          'Please enable SMS permissions in app settings.',
        );
      } else {
        logWarning(
          'SMS permissions denied. '
          'Please grant SMS permissions to enable transaction detection.',
        );
      }

      return false;
    } catch (e, stackTrace) {
      logError(
        'Failed to request SMS permissions',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  /// Start listening for SMS (public method to allow starting/stopping based on settings)
  Future<void> startListening() async {
    // Check permissions before starting
    final hasPermissions = await _checkSmsPermissions();
    if (!hasPermissions) {
      logWarning(
        'Cannot start SMS listening: permissions not granted. '
        'Requesting permissions...',
      );
      final granted = await _checkAndRequestSmsPermissions();
      if (!granted) {
        logError(
          'Failed to start SMS listening: permissions not granted after request',
        );
        return;
      }
    }

    await _startListening();
  }

  /// Start listening for SMS (internal)
  Future<void> _startListening() async {
    if (_isListening || _telephony == null) {
      logWarning('SMS listening already active or telephony not initialized');
      return;
    }

    // Double-check permissions
    final hasPermissions = await _checkSmsPermissions();
    if (!hasPermissions) {
      logError('Cannot start SMS listening: permissions not granted');
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
  /// Processes SMS in background to prevent UI blocking
  Future<void> _handleSms(SmsMessage message) async {
    final sender = message.address ?? '';
    final body = message.body ?? '';

    logDebug('Received SMS from $sender: $body');

    if (_smsMatcher == null || _confirmationHandler == null) {
      logWarning('SmsDetectionService not initialized, ignoring SMS');
      return;
    }

    try {
      // Match SMS to template and parse transaction data (runs in background isolate)
      final matchResult = await _smsMatcher!.matchSms(sender, body);
      if (matchResult == null) {
        return; // No match found, silently ignore
      }

      // Handle auto-create or pending confirmation
      // This runs on main isolate but is fast (DB operations are async)
      await _processMatchedSms(
        matchResult: matchResult,
        smsBody: body,
        smsSender: sender,
        autoConfirm: _autoConfirm,
      );
    } catch (e, stackTrace) {
      logError('Failed to process SMS', error: e, stackTrace: stackTrace);
    }
  }

  /// Process matched SMS: auto-create transaction or create pending confirmation
  Future<void> _processMatchedSms({
    required SmsMatchResult matchResult,
    required String smsBody,
    required String smsSender,
    required bool autoConfirm,
  }) async {
    final confidence = matchResult.confidence;
    final parsedData = matchResult.parsedData;

    // Create pending confirmation first
    final confirmationId = await _confirmationHandler!
        .createPendingConfirmation(
          smsBody: smsBody,
          smsSender: smsSender,
          parsedData: parsedData,
          confidence: confidence,
        );

    // Auto-create transaction if confidence is high enough
    // If auto-confirm is enabled, it will auto-create for high confidence transactions
    // If auto-confirm is disabled, it will still auto-create for high confidence (default behavior)
    // The auto-confirm setting only affects whether we skip the confirmation dialog
    // for high-confidence transactions (currently always auto-creates high confidence)
    final isHighConfidence = confidence >= _confidenceThreshold;

    if (isHighConfidence && _transactionCreator != null) {
      try {
        final transactionId = await _transactionCreator!
            .createTransactionFromSms(parsedData, confidence);

        if (transactionId != null) {
          // Delete pending confirmation since we auto-created
          await _confirmationHandler!.deleteConfirmation(confirmationId);
          logInfo(
            'Transaction auto-created successfully, skipping notification',
          );
          return; // Don't show notification
        } else {
          logWarning(
            'Failed to auto-create transaction, keeping as pending confirmation',
          );
          // Continue to show notification for manual confirmation
        }
      } on DuplicateTransactionException catch (e) {
        logWarning(
          'Duplicate transaction detected, skipping auto-create: ${e.smsHash}',
        );
        // Delete pending confirmation since transaction already exists
        await _confirmationHandler!.deleteConfirmation(confirmationId);
        return; // Don't show notification for duplicates
      }
    }

    // Show notification for manual confirmation
    await _confirmationHandler!.showConfirmationNotification(
      confirmationId: confirmationId,
      parsedData: parsedData,
    );
  }

  /// Set auto-confirm setting
  void setAutoConfirm(bool autoConfirm) {
    _autoConfirm = autoConfirm;
    logInfo('Auto-confirm transactions set to: $autoConfirm');
  }

  /// Set confidence threshold for auto-creating transactions
  void setConfidenceThreshold(double threshold) {
    _confidenceThreshold = threshold.clamp(0.0, 1.0);
    logInfo('Confidence threshold set to: $_confidenceThreshold');
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
    _smsMatcher = null;
    _transactionCreator = null;
    _confirmationHandler = null;
    logInfo('SmsDetectionService disposed');
  }
}
