import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:another_telephony/telephony.dart';
import 'package:flutter_logging_service/flutter_logging_service.dart';
import '../../core/database/daos/sms_template_dao.dart';

/// Service for reading SMS messages from device inbox
/// Android only - iOS support is on hold
class SmsReaderService with Loggable {
  static SmsReaderService? _instance;

  static SmsReaderService get instance {
    _instance ??= SmsReaderService._();
    return _instance!;
  }

  SmsReaderService._();

  Telephony? _telephony;
  bool _isInitialized = false;
  List<SmsMessage>? _cachedSms;
  DateTime? _cacheTimestamp;
  static const _cacheDuration = Duration(minutes: 5);

  /// Initialize the SMS reader service
  Future<void> init() async {
    if (_isInitialized) {
      logWarning('SmsReaderService already initialized');
      return;
    }

    if (kIsWeb) {
      logWarning(
        'SMS reading: This app is Android-only, web platform not supported',
      );
      _isInitialized = true;
      return;
    }

    try {
      _telephony = Telephony.instance;
      _isInitialized = true;
      logInfo('SmsReaderService initialized successfully');
    } catch (e, stackTrace) {
      logError(
        'Failed to initialize SmsReaderService',
        error: e,
        stackTrace: stackTrace,
      );
      _isInitialized =
          true; // Don't throw - app can function without SMS reading
    }
  }

  /// Get all SMS messages from inbox
  /// Returns cached results if available and fresh
  Future<List<SmsMessage>> getInboxSms({
    int? limit,
    int offset = 0,
    bool forceRefresh = false,
  }) async {
    if (!_isInitialized || _telephony == null) {
      logWarning('SmsReaderService not initialized');
      return [];
    }

    // Return cached results if available and fresh
    if (!forceRefresh &&
        _cachedSms != null &&
        _cacheTimestamp != null &&
        DateTime.now().difference(_cacheTimestamp!) < _cacheDuration) {
      logDebug('Returning cached SMS list (${_cachedSms!.length} messages)');
      return _applyPagination(_cachedSms!, limit: limit, offset: offset);
    }

    try {
      // Request SMS permissions if needed
      final permissionsGranted =
          await _telephony!.requestPhoneAndSmsPermissions;
      if (permissionsGranted == false) {
        logWarning('SMS permissions not granted');
        return [];
      }

      // Read SMS from inbox
      final smsList = await _telephony!.getInboxSms(
        columns: [SmsColumn.ADDRESS, SmsColumn.BODY, SmsColumn.DATE],
        sortOrder: [OrderBy(SmsColumn.DATE, sort: Sort.DESC)],
      );

      // Cache results
      _cachedSms = smsList;
      _cacheTimestamp = DateTime.now();
      logInfo('Loaded ${smsList.length} SMS messages from inbox');

      return _applyPagination(smsList, limit: limit, offset: offset);
    } catch (e, stackTrace) {
      logError('Failed to read inbox SMS', error: e, stackTrace: stackTrace);
      return [];
    }
  }

  /// Get SMS messages filtered by sender
  Future<List<SmsMessage>> getSmsBySender(
    String senderPattern, {
    int? limit,
    int offset = 0,
  }) async {
    final allSms = await getInboxSms(forceRefresh: false);
    final pattern = RegExp(senderPattern, caseSensitive: false);
    final filtered = allSms
        .where((sms) => sms.address != null && pattern.hasMatch(sms.address!))
        .toList();
    return _applyPagination(filtered, limit: limit, offset: offset);
  }

  /// Filter SMS messages that match template sender patterns
  Future<List<SmsMessage>> filterSmsByTemplates(
    SmsTemplateDao smsTemplateDao, {
    int? limit,
    int offset = 0,
  }) async {
    try {
      final templates = await smsTemplateDao.getActiveTemplates();
      final allSms = await getInboxSms(forceRefresh: false);

      // Get unique sender patterns from templates
      final senderPatterns = <String>{};
      for (final template in templates) {
        if (template.senderPattern != null &&
            template.senderPattern!.isNotEmpty) {
          senderPatterns.add(template.senderPattern!);
        }
      }

      // If no templates have sender patterns, return all SMS
      if (senderPatterns.isEmpty) {
        logInfo('No sender patterns in templates, returning all SMS');
        return _applyPagination(allSms, limit: limit, offset: offset);
      }

      final matchedSms = <SmsMessage>[];
      for (final sms in allSms) {
        if (sms.address == null) continue;

        // Check if SMS sender matches any template sender pattern
        for (final patternStr in senderPatterns) {
          try {
            final pattern = RegExp(patternStr, caseSensitive: false);
            if (pattern.hasMatch(sms.address!)) {
              matchedSms.add(sms);
              break; // Don't add same SMS multiple times
            }
          } catch (e) {
            logWarning('Invalid sender pattern regex: $patternStr');
          }
        }
      }

      logInfo(
        'Filtered ${matchedSms.length} SMS from ${allSms.length} total SMS',
      );
      return _applyPagination(matchedSms, limit: limit, offset: offset);
    } catch (e, stackTrace) {
      logError(
        'Failed to filter SMS by templates',
        error: e,
        stackTrace: stackTrace,
      );
      return [];
    }
  }

  /// Clear the SMS cache
  void clearCache() {
    _cachedSms = null;
    _cacheTimestamp = null;
    logDebug('SMS cache cleared');
  }

  /// Apply pagination to SMS list
  List<SmsMessage> _applyPagination(
    List<SmsMessage> smsList, {
    int? limit,
    int offset = 0,
  }) {
    if (offset >= smsList.length) {
      return [];
    }

    final end = limit != null
        ? (offset + limit).clamp(0, smsList.length)
        : smsList.length;
    return smsList.sublist(offset, end);
  }
}
