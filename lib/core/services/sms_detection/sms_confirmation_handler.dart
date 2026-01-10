import 'dart:convert';
import 'package:drift/drift.dart' as drift;
import 'package:flutter_logging_service/flutter_logging_service.dart';
import 'package:mizaniyah/core/database/app_database.dart' as db;
import 'package:mizaniyah/core/database/daos/pending_sms_confirmation_dao.dart';
import 'package:mizaniyah/core/services/notification_service.dart';
import 'package:mizaniyah/core/services/sms_parsing_service.dart';
import 'sms_detection_constants.dart';

/// Service responsible for handling SMS confirmations (pending and notifications)
class SmsConfirmationHandler with Loggable {
  final PendingSmsConfirmationDao _pendingSmsDao;

  SmsConfirmationHandler(this._pendingSmsDao);

  /// Create a pending confirmation from parsed SMS data
  /// Returns confirmation ID
  Future<int> createPendingConfirmation({
    required String smsBody,
    required String smsSender,
    required ParsedSmsData parsedData,
    required double confidence,
  }) async {
    logDebug('Creating pending confirmation with confidence=$confidence');

    try {
      final parsedDataWithConfidence = {
        ...parsedData.toJson(),
        'confidence': confidence,
      };

      final expiresAt = DateTime.now().add(
        Duration(hours: SmsDetectionConstants.confirmationExpirationHours),
      );

      final confirmation = db.PendingSmsConfirmationsCompanion(
        smsBody: drift.Value(smsBody),
        smsSender: drift.Value(smsSender),
        parsedData: drift.Value(jsonEncode(parsedDataWithConfidence)),
        expiresAt: drift.Value(expiresAt),
      );

      final confirmationId =
          await _pendingSmsDao.insertConfirmation(confirmation);

      logInfo(
        'Created pending confirmation with id=$confirmationId, confidence=$confidence',
      );

      return confirmationId;
    } catch (e, stackTrace) {
      logError(
        'Failed to create pending confirmation',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Delete a pending confirmation (e.g., after auto-creating transaction)
  Future<void> deleteConfirmation(int confirmationId) async {
    logDebug('Deleting confirmation id=$confirmationId');
    try {
      await _pendingSmsDao.deleteConfirmation(confirmationId);
      logInfo('Deleted pending confirmation $confirmationId');
    } catch (e, stackTrace) {
      logError(
        'Failed to delete confirmation id=$confirmationId',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Show notification for manual confirmation
  Future<void> showConfirmationNotification({
    required int confirmationId,
    required ParsedSmsData parsedData,
  }) async {
    logDebug('Showing confirmation notification for id=$confirmationId');

    try {
      await NotificationService.showSmsConfirmationNotification(
        confirmationId,
        parsedData.storeName!,
        parsedData.amount!,
        parsedData.currency ?? SmsDetectionConstants.defaultCurrency,
      );
    } catch (e, stackTrace) {
      logError(
        'Failed to show confirmation notification',
        error: e,
        stackTrace: stackTrace,
      );
      // Don't rethrow - notification failure shouldn't break SMS processing
    }
  }
}
