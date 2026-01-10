import 'package:flutter_logging_service/flutter_logging_service.dart';
import 'package:mizaniyah/core/database/app_database.dart' as db;
import 'package:mizaniyah/core/database/daos/sms_template_dao.dart';
import 'package:mizaniyah/core/services/sms_parsing_service.dart';

/// Result of SMS matching operation
class SmsMatchResult {
  final ParsedSmsData parsedData;
  final double confidence;
  final db.SmsTemplate? template;

  SmsMatchResult({
    required this.parsedData,
    required this.confidence,
    this.template,
  });
}

/// Service responsible for matching SMS messages to templates
class SmsMatcher with Loggable {
  final SmsTemplateDao _smsTemplateDao;

  SmsMatcher(this._smsTemplateDao);

  /// Match SMS to templates and parse transaction data
  /// Returns SmsMatchResult if match found, null otherwise
  Future<SmsMatchResult?> matchSms(String sender, String body) async {
    logDebug('Matching SMS from sender: $sender');

    try {
      // Get active templates that match the sender
      final templates = await _smsTemplateDao.getActiveTemplatesBySender(
        sender,
      );

      if (templates.isEmpty) {
        logDebug('No active templates found for sender: $sender');
        return null;
      }

      logInfo('Found ${templates.length} template(s) for sender: $sender');

      // Try to parse SMS with templates
      final match = SmsParsingService.findMatchingTemplate(body, templates);

      if (match == null) {
        logDebug('SMS does not match any template for sender: $sender');
        return null;
      }

      final parsedData = match['parsed_data'] as ParsedSmsData;
      final confidence = match['confidence'] as double? ?? 0.5;
      final template = match['template'] as db.SmsTemplate?;

      // Validate parsed data
      if (parsedData.storeName == null || parsedData.amount == null) {
        logWarning(
          'Parsed SMS data missing required fields: storeName=${parsedData.storeName}, amount=${parsedData.amount}',
        );
        return null;
      }

      logInfo(
        'Successfully matched SMS: store=${parsedData.storeName}, amount=${parsedData.amount}, confidence=$confidence',
      );

      return SmsMatchResult(
        parsedData: parsedData,
        confidence: confidence,
        template: template,
      );
    } catch (e, stackTrace) {
      logError(
        'Failed to match SMS',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }
}
