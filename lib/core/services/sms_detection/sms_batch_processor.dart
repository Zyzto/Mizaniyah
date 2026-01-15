import 'dart:async';
import 'package:flutter_logging_service/flutter_logging_service.dart';
import 'package:another_telephony/telephony.dart';
import 'package:mizaniyah/core/database/daos/sms_template_dao.dart';
import 'package:mizaniyah/core/services/sms_reader_service.dart';
import 'package:mizaniyah/core/services/sms_detection/sms_matcher.dart';
import 'package:mizaniyah/core/services/sms_detection/sms_transaction_creator.dart';
import 'package:mizaniyah/core/services/sms_detection/sms_confirmation_handler.dart';
import 'package:mizaniyah/core/services/sms_detection/sms_detection_constants.dart';

/// Result of batch processing
class BatchProcessingResult {
  final int totalProcessed;
  final int matchedCount;
  final int createdCount;
  final int errorCount;
  final List<String> errors;

  BatchProcessingResult({
    required this.totalProcessed,
    required this.matchedCount,
    required this.createdCount,
    required this.errorCount,
    required this.errors,
  });
}

/// Service for batch processing historical SMS messages
class SmsBatchProcessor with Loggable {
  final SmsReaderService _smsReaderService;
  final SmsMatcher _smsMatcher;
  final SmsTransactionCreator? _transactionCreator;
  final SmsConfirmationHandler _confirmationHandler;

  SmsBatchProcessor({
    required SmsReaderService smsReaderService,
    required SmsMatcher smsMatcher,
    SmsTransactionCreator? transactionCreator,
    required SmsConfirmationHandler confirmationHandler,
  }) : _smsReaderService = smsReaderService,
       _smsMatcher = smsMatcher,
       _transactionCreator = transactionCreator,
       _confirmationHandler = confirmationHandler;

  /// Process SMS messages in a date range
  /// Returns progress stream and result
  Stream<({int processed, int total, int matched, int created})>
  processDateRange({
    required DateTime startDate,
    required DateTime endDate,
    required SmsTemplateDao smsTemplateDao,
    bool autoCreate = false,
    double? confidenceThreshold,
  }) async* {
    final threshold =
        confidenceThreshold ??
        SmsDetectionConstants.defaultAutoCreateConfidenceThreshold;

    logInfo(
      'Starting batch processing: startDate=$startDate, endDate=$endDate, autoCreate=$autoCreate',
    );

    try {
      await _smsReaderService.init();

      int processed = 0;
      int matched = 0;
      int created = 0;
      int total = 0;

      // Get all SMS in date range
      final allSms = await _smsReaderService.getInboxSms(
        limit: 10000, // Large limit for batch processing
        offset: 0,
        forceRefresh: true,
      );

      // Filter by date range
      final filteredSms = allSms.where((sms) {
        final smsDate = sms.date;
        if (smsDate == null) return false;
        // SmsMessage.date is int (timestamp in milliseconds)
        final date = DateTime.fromMillisecondsSinceEpoch(smsDate);
        return date.isAfter(startDate.subtract(const Duration(days: 1))) &&
            date.isBefore(endDate.add(const Duration(days: 1)));
      }).toList();

      total = filteredSms.length;
      logInfo('Found $total SMS messages in date range');

      // Process in batches to avoid blocking
      const batchSize = 10;
      for (int i = 0; i < filteredSms.length; i += batchSize) {
        final batch = filteredSms.sublist(
          i,
          (i + batchSize).clamp(0, filteredSms.length),
        );

        for (final sms in batch) {
          try {
            final sender = sms.address ?? '';
            final body = sms.body ?? '';

            if (body.isEmpty) {
              processed++;
              yield (
                processed: processed,
                total: total,
                matched: matched,
                created: created,
              );
              continue;
            }

            // Match SMS
            final matchResult = await _smsMatcher.matchSms(sender, body);

            if (matchResult != null) {
              matched++;
              final confidence = matchResult.confidence;
              final parsedData = matchResult.parsedData;

              // Auto-create if enabled and confidence is high enough
              if (autoCreate &&
                  confidence >= threshold &&
                  _transactionCreator != null) {
                try {
                  final transactionId = await _transactionCreator
                      .createTransactionFromSms(parsedData, confidence);

                  if (transactionId != null) {
                    created++;
                    logInfo(
                      'Auto-created transaction from batch: id=$transactionId',
                    );
                  }
                } catch (e) {
                  // Create pending confirmation on error
                  await _confirmationHandler.createPendingConfirmation(
                    smsBody: body,
                    smsSender: sender,
                    parsedData: parsedData,
                    confidence: confidence,
                  );
                }
              } else {
                // Create pending confirmation
                await _confirmationHandler.createPendingConfirmation(
                  smsBody: body,
                  smsSender: sender,
                  parsedData: parsedData,
                  confidence: confidence,
                );
              }
            }

            processed++;
            yield (
              processed: processed,
              total: total,
              matched: matched,
              created: created,
            );
          } catch (e, stackTrace) {
            logError(
              'Error processing SMS in batch',
              error: e,
              stackTrace: stackTrace,
            );
            processed++;
            yield (
              processed: processed,
              total: total,
              matched: matched,
              created: created,
            );
          }
        }
      }

      logInfo(
        'Batch processing completed: processed=$processed, matched=$matched, created=$created',
      );
    } catch (e, stackTrace) {
      logError('Batch processing failed', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Get preview of SMS that would be processed
  Future<List<SmsMessage>> getPreview({
    required DateTime startDate,
    required DateTime endDate,
    int limit = 50,
  }) async {
    try {
      await _smsReaderService.init();
      final allSms = await _smsReaderService.getInboxSms(
        limit: 1000,
        offset: 0,
        forceRefresh: true,
      );

      final filtered = allSms
          .where((sms) {
            final smsDate = sms.date;
            if (smsDate == null) return false;
            // SmsMessage.date is int (timestamp in milliseconds)
            final date = DateTime.fromMillisecondsSinceEpoch(smsDate);
            return date.isAfter(startDate.subtract(const Duration(days: 1))) &&
                date.isBefore(endDate.add(const Duration(days: 1)));
          })
          .take(limit)
          .toList();

      return filtered;
    } catch (e, stackTrace) {
      logError('Failed to get preview', error: e, stackTrace: stackTrace);
      return [];
    }
  }
}
