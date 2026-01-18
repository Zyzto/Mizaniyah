import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_logging_service/flutter_logging_service.dart';
import 'package:mizaniyah/core/database/app_database.dart' as db;

/// Parsed SMS data structure
class ParsedSmsData {
  final String? storeName;
  final double? amount;
  final String? currency;
  final String? cardLast4Digits;
  final DateTime? transactionDate; // Extracted transaction date from SMS
  final String? smsSender; // Original SMS sender for duplicate detection
  final String? smsBody; // Original SMS body for duplicate detection

  ParsedSmsData({
    this.storeName,
    this.amount,
    this.currency,
    this.cardLast4Digits,
    this.transactionDate,
    this.smsSender,
    this.smsBody,
  });

  Map<String, dynamic> toJson() => {
    'store_name': storeName,
    'amount': amount,
    'currency': currency,
    'card_last4': cardLast4Digits,
    'transaction_date': transactionDate?.toIso8601String(),
    'sms_sender': smsSender,
    'sms_body': smsBody,
  };

  factory ParsedSmsData.fromJson(Map<String, dynamic> json) => ParsedSmsData(
    storeName: json['store_name'] as String?,
    amount: json['amount'] as double?,
    currency: json['currency'] as String?,
    cardLast4Digits: json['card_last4'] as String?,
    transactionDate: json['transaction_date'] != null
        ? DateTime.tryParse(json['transaction_date'] as String)
        : null,
    smsSender: json['sms_sender'] as String?,
    smsBody: json['sms_body'] as String?,
  );

  /// Generate hash for duplicate detection
  /// Uses sender + body + transaction date (or current date if not available)
  String generateSmsHash() {
    final dateStr =
        transactionDate?.toIso8601String().split('T')[0] ??
        DateTime.now().toIso8601String().split('T')[0];
    final hashInput = '${smsSender ?? ''}|${smsBody ?? ''}|$dateStr';
    final bytes = utf8.encode(hashInput);
    final hash = sha256.convert(bytes);
    return hash.toString();
  }
}

/// SMS Parsing Service
/// Matches SMS against templates and extracts transaction data
class SmsParsingService with Loggable {
  /// Extract a field value using extraction rule
  /// Supports:
  /// - Capture groups: {"group": 1} - uses capture group from main pattern
  /// - Regex patterns: {"pattern": "regex"} - uses separate regex pattern
  /// - Fixed values: "value" - returns the string directly
  static String? _extractField(
    String smsBody,
    dynamic rule,
    RegExpMatch? mainMatch,
  ) {
    if (rule == null) return null;

    // Fixed string value
    if (rule is String) {
      return rule;
    }

    // Object with extraction method
    if (rule is Map<String, dynamic>) {
      // Prefer field-specific pattern over capture group (more flexible)
      // Field-specific patterns allow fields to appear in any order
      if (rule.containsKey('pattern')) {
        final patternStr = rule['pattern'] as String?;
        if (patternStr != null) {
          try {
            final pattern = RegExp(
              patternStr,
              caseSensitive: false,
              multiLine: true,
              dotAll: true,
            );
            final match = pattern.firstMatch(smsBody);
            if (match != null && match.groupCount >= 1) {
              final extracted = match.group(1)?.trim();
              if (extracted != null && extracted.isNotEmpty) {
                return extracted;
              }
            }
          } catch (e) {
            Log.warning(
              'Invalid regex pattern in extraction rule: $patternStr',
            );
          }
        }
      }

      // Fallback to capture group from main pattern
      if (rule.containsKey('group') && mainMatch != null) {
        final groupIndex = rule['group'];
        if (groupIndex is int &&
            groupIndex > 0 &&
            groupIndex <= mainMatch.groupCount) {
          return mainMatch.group(groupIndex)?.trim();
        }
      }
    }

    // Legacy support: direct regex pattern string
    if (rule is String && rule.isNotEmpty) {
      try {
        final pattern = RegExp(
          rule,
          caseSensitive: false,
          multiLine: true,
          dotAll: true,
        );
        final match = pattern.firstMatch(smsBody);
        if (match != null && match.groupCount >= 1) {
          return match.group(1)?.trim();
        }
      } catch (e) {
        Log.warning('Invalid regex pattern: $rule');
      }
    }

    return null;
  }

  /// Parse date string in various formats
  /// Supports: "Jan 15", "15/01/2024", "2024-01-15", "15 Jan 2024", etc.
  static DateTime? _parseDate(String dateStr) {
    if (dateStr.isEmpty) return null;

    try {
      // Try ISO format first
      final isoDate = DateTime.tryParse(dateStr);
      if (isoDate != null) {
        // Validate: don't allow future dates, and reasonable range (last 5 years to today)
        final now = DateTime.now();
        final fiveYearsAgo = DateTime(now.year - 5, 1, 1);
        if (isoDate.isAfter(now)) {
          Log.warning('Parsed date is in the future: $dateStr');
          return null;
        }
        if (isoDate.isBefore(fiveYearsAgo)) {
          Log.warning('Parsed date is too old: $dateStr');
          return null;
        }
        return isoDate;
      }

      // Try common formats
      final cleaned = dateStr.trim();

      // Format: "DD/MM/YYYY" or "DD-MM-YYYY"
      final slashPattern = RegExp(r'(\d{1,2})[/-](\d{1,2})[/-](\d{2,4})');
      final slashMatch = slashPattern.firstMatch(cleaned);
      if (slashMatch != null) {
        final day = int.parse(slashMatch.group(1)!);
        final month = int.parse(slashMatch.group(2)!);
        final yearStr = slashMatch.group(3)!;
        final year = yearStr.length == 2
            ? 2000 +
                  int.parse(yearStr) // Assume 20XX for 2-digit years
            : int.parse(yearStr);

        if (month >= 1 && month <= 12 && day >= 1 && day <= 31) {
          final date = DateTime(year, month, day);
          final now = DateTime.now();
          if (!date.isAfter(now) &&
              date.isAfter(DateTime(now.year - 5, 1, 1))) {
            return date;
          }
        }
      }

      // Format: "MMM DD" or "DD MMM" (assume current year)
      final monthNames = {
        'jan': 1,
        'feb': 2,
        'mar': 3,
        'apr': 4,
        'may': 5,
        'jun': 6,
        'jul': 7,
        'aug': 8,
        'sep': 9,
        'oct': 10,
        'nov': 11,
        'dec': 12,
      };

      final monthPattern = RegExp(
        r'(jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)\s+(\d{1,2})',
        caseSensitive: false,
      );
      final monthMatch = monthPattern.firstMatch(cleaned);
      if (monthMatch != null) {
        final monthName = monthMatch.group(1)!.toLowerCase();
        final day = int.parse(monthMatch.group(2)!);
        final month = monthNames[monthName];
        if (month != null && day >= 1 && day <= 31) {
          final now = DateTime.now();
          var year = now.year;
          // If month is in the future, assume last year
          if (month > now.month || (month == now.month && day > now.day)) {
            year = now.year - 1;
          }
          final date = DateTime(year, month, day);
          if (!date.isAfter(now) &&
              date.isAfter(DateTime(now.year - 5, 1, 1))) {
            return date;
          }
        }
      }

      // Try reverse: "DD MMM"
      final reversePattern = RegExp(
        r'(\d{1,2})\s+(jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)',
        caseSensitive: false,
      );
      final reverseMatch = reversePattern.firstMatch(cleaned);
      if (reverseMatch != null) {
        final day = int.parse(reverseMatch.group(1)!);
        final monthName = reverseMatch.group(2)!.toLowerCase();
        final month = monthNames[monthName];
        if (month != null && day >= 1 && day <= 31) {
          final now = DateTime.now();
          var year = now.year;
          if (month > now.month || (month == now.month && day > now.day)) {
            year = now.year - 1;
          }
          final date = DateTime(year, month, day);
          if (!date.isAfter(now) &&
              date.isAfter(DateTime(now.year - 5, 1, 1))) {
            return date;
          }
        }
      }

      Log.debug('Could not parse date string: $dateStr');
      return null;
    } catch (e) {
      Log.warning('Error parsing date: $dateStr, error: $e');
      return null;
    }
  }

  /// Parse SMS using pattern and extraction rules
  /// Returns ParsedSmsData if successful, null otherwise
  /// [smsDate] - Optional SMS timestamp to use as fallback for transaction date
  static ParsedSmsData? parseSmsWithRules(
    String smsBody,
    String pattern,
    String extractionRulesJson, {
    DateTime? smsDate,
  }) {
    try {
      // Check if SMS matches the template pattern
      // Use multiLine and dotAll flags to handle multi-line SMS messages correctly
      final patternRegex = RegExp(
        pattern,
        caseSensitive: false,
        multiLine: true,
        dotAll: true,
      );
      final mainMatch = patternRegex.firstMatch(smsBody);
      if (mainMatch == null) {
        Log.debug('SMS does not match template pattern: $pattern');
        return null;
      }

      // Parse extraction rules from JSON
      final extractionRules =
          jsonDecode(extractionRulesJson) as Map<String, dynamic>;

      // Extract store name
      String? storeName;
      if (extractionRules.containsKey('store_name')) {
        storeName = _extractField(
          smsBody,
          extractionRules['store_name'],
          mainMatch,
        );
      }

      // Extract amount
      double? amount;
      if (extractionRules.containsKey('amount')) {
        final amountStr = _extractField(
          smsBody,
          extractionRules['amount'],
          mainMatch,
        );
        if (amountStr != null) {
          // Remove commas and parse
          final cleanedAmount = amountStr.replaceAll(',', '').trim();
          amount = double.tryParse(cleanedAmount);
        }
      }

      // Extract currency (can be fixed value, capture group, or pattern)
      String? currency;
      if (extractionRules.containsKey('currency')) {
        currency = _extractField(
          smsBody,
          extractionRules['currency'],
          mainMatch,
        );
      }

      // Extract card last 4 digits (supports both 'card_last4' and 'card_pattern' for backward compatibility)
      String? cardLast4Digits;
      if (extractionRules.containsKey('card_last4')) {
        cardLast4Digits = _extractField(
          smsBody,
          extractionRules['card_last4'],
          mainMatch,
        );
      } else if (extractionRules.containsKey('card_pattern')) {
        // Legacy support
        cardLast4Digits = _extractField(
          smsBody,
          extractionRules['card_pattern'],
          mainMatch,
        );
      }

      // Extract transaction date (supports various date formats)
      DateTime? transactionDate;
      if (extractionRules.containsKey('transaction_date') ||
          extractionRules.containsKey('date')) {
        final dateRule =
            extractionRules['transaction_date'] ?? extractionRules['date'];
        final dateStr = _extractField(smsBody, dateRule, mainMatch);
        if (dateStr != null) {
          transactionDate = _parseDate(dateStr);
        }
      }

      // Use SMS date as fallback if enabled and no date was extracted
      if (transactionDate == null && smsDate != null) {
        final useSmsDateFallback =
            extractionRules['use_sms_date_fallback'] == true;
        if (useSmsDateFallback) {
          transactionDate = smsDate;
          Log.debug('Using SMS date as fallback: $smsDate');
        }
      }

      // Validate that we extracted at least amount and store name
      if (amount == null || storeName == null || storeName.isEmpty) {
        Log.warning(
          'Failed to extract required fields: amount=$amount, storeName=$storeName',
        );
        return null;
      }

      return ParsedSmsData(
        storeName: storeName,
        amount: amount,
        currency: currency ?? 'USD', // Default currency
        cardLast4Digits: cardLast4Digits,
        transactionDate: transactionDate,
      );
    } catch (e, stackTrace) {
      Log.error(
        'Failed to parse SMS with pattern',
        error: e,
        stackTrace: stackTrace,
      );
      // Try graceful degradation - return null to let caller handle
      return null;
    }
  }

  /// Parse SMS using a template
  /// Returns ParsedSmsData if successful, null otherwise
  /// [smsDate] - Optional SMS timestamp to use as fallback for transaction date
  static ParsedSmsData? parseSms(
    String smsBody,
    db.SmsTemplate template, {
    DateTime? smsDate,
  }) {
    return parseSmsWithRules(
      smsBody,
      template.pattern,
      template.extractionRules,
      smsDate: smsDate,
    );
  }

  /// Calculate confidence score for a pattern match
  /// Returns a score from 0.0 to 1.0 based on pattern match quality
  static double _calculateConfidence(
    String smsBody,
    String pattern,
    ParsedSmsData parsedData,
  ) {
    double confidence = 0.5; // Base confidence

    try {
      final patternRegex = RegExp(
        pattern,
        caseSensitive: false,
        multiLine: true,
        dotAll: true,
      );
      final match = patternRegex.firstMatch(smsBody);

      if (match != null) {
        // Higher confidence if pattern matches a significant portion of the SMS
        final matchLength = match.end - match.start;
        final smsLength = smsBody.length;
        if (smsLength > 0) {
          final matchRatio = matchLength / smsLength;
          confidence += matchRatio * 0.2; // Up to 0.2 points for match coverage
        }

        // Higher confidence if we have more capture groups (more structured data)
        if (match.groupCount > 0) {
          confidence += (match.groupCount / 10.0).clamp(
            0.0,
            0.15,
          ); // Up to 0.15 points
        }
      }

      // Higher confidence if all fields are extracted successfully
      int extractedFields = 0;
      if (parsedData.storeName != null && parsedData.storeName!.isNotEmpty) {
        extractedFields++;
      }
      if (parsedData.amount != null && parsedData.amount! > 0) {
        extractedFields++;
      }
      if (parsedData.currency != null && parsedData.currency!.isNotEmpty) {
        extractedFields++;
      }
      if (parsedData.cardLast4Digits != null &&
          parsedData.cardLast4Digits!.isNotEmpty) {
        extractedFields++;
      }

      confidence +=
          (extractedFields / 4.0) *
          0.15; // Up to 0.15 points for complete extraction

      // Higher confidence if amount is reasonable (not 0, not negative, not extremely large)
      if (parsedData.amount != null) {
        if (parsedData.amount! > 0 && parsedData.amount! < 1000000) {
          confidence += 0.1; // Bonus for reasonable amount
        } else {
          confidence -= 0.1; // Penalty for unreasonable amount
        }
      }

      // Higher confidence if store name looks valid (not too short, not just numbers)
      if (parsedData.storeName != null) {
        final storeName = parsedData.storeName!;
        if (storeName.length >= 2 && !RegExp(r'^\d+$').hasMatch(storeName)) {
          confidence += 0.1; // Bonus for valid store name
        } else {
          confidence -= 0.1; // Penalty for invalid store name
        }
      }
    } catch (e) {
      Log.warning('Error calculating confidence: $e');
    }

    return confidence.clamp(0.0, 1.0);
  }

  /// Find matching template for SMS from a list of templates
  /// Returns the first matching template, parsed data, and confidence score, or null
  /// [smsDate] - Optional SMS timestamp to use as fallback for transaction date
  static Map<String, dynamic>? findMatchingTemplate(
    String smsBody,
    List<db.SmsTemplate> templates, {
    DateTime? smsDate,
  }) {
    // Sort templates by priority (higher priority first)
    final sortedTemplates = List<db.SmsTemplate>.from(templates)
      ..sort((a, b) => b.priority.compareTo(a.priority));

    double bestConfidence = 0.0;
    Map<String, dynamic>? bestMatch;

    for (final template in sortedTemplates) {
      final parsed = parseSms(smsBody, template, smsDate: smsDate);
      if (parsed != null) {
        final confidence = _calculateConfidence(
          smsBody,
          template.pattern,
          parsed,
        );

        // If this is a high-confidence match (>= 0.7), use it immediately
        if (confidence >= 0.7) {
          return {
            'template': template,
            'parsed_data': parsed,
            'confidence': confidence,
          };
        }

        // Otherwise, keep track of the best match
        if (confidence > bestConfidence) {
          bestConfidence = confidence;
          bestMatch = {
            'template': template,
            'parsed_data': parsed,
            'confidence': confidence,
          };
        }
      }
    }

    return bestMatch;
  }

  /// Validate a template's pattern and extraction rules
  /// Returns a list of validation errors, empty if valid
  static List<String> validateTemplate(
    String pattern,
    String extractionRulesJson,
  ) {
    final errors = <String>[];

    // Validate pattern is valid regex
    try {
      RegExp(
        pattern,
        caseSensitive: false,
        multiLine: true,
        dotAll: true,
      );
    } catch (e) {
      errors.add('Invalid pattern regex: $e');
      return errors; // Can't continue validation if pattern is invalid
    }

    // Validate extraction rules JSON
    Map<String, dynamic> extractionRules;
    try {
      extractionRules = jsonDecode(extractionRulesJson) as Map<String, dynamic>;
    } catch (e) {
      errors.add('Invalid extraction rules JSON: $e');
      return errors; // Can't continue validation if JSON is invalid
    }

    // Check main pattern for capture groups
    final patternRegex = RegExp(
      pattern,
      caseSensitive: false,
      multiLine: true,
      dotAll: true,
    );
    // Try to get group count by matching with a very permissive test string
    // Use a long string with various characters to increase chance of match
    final testString = 'test 123 ABC def 456.78 USD card 1234';
    final testMatch = patternRegex.firstMatch(testString);
    int maxGroups = 0;
    if (testMatch != null) {
      maxGroups = testMatch.groupCount;
    } else {
      // Fallback: approximate by counting unescaped opening parentheses
      // This is not perfect but gives a reasonable estimate
      final patternStr = patternRegex.pattern;
      int count = 0;
      bool escaped = false;
      for (int i = 0; i < patternStr.length; i++) {
        if (escaped) {
          escaped = false;
          continue;
        }
        if (patternStr[i] == '\\') {
          escaped = true;
          continue;
        }
        if (patternStr[i] == '(' &&
            (i + 1 >= patternStr.length || patternStr[i + 1] != '?')) {
          count++;
        }
      }
      maxGroups = count;
    }

    // Validate extraction rules
    for (final entry in extractionRules.entries) {
      final fieldName = entry.key;
      final rule = entry.value;

      if (rule == null) continue;

      // Check if using capture group
      if (rule is Map<String, dynamic> && rule.containsKey('group')) {
        final groupIndex = rule['group'];
        if (groupIndex is! int || groupIndex < 1) {
          errors.add(
            'Invalid group index for $fieldName: must be a positive integer',
          );
        } else if (groupIndex > maxGroups) {
          errors.add(
            'Group index $groupIndex for $fieldName exceeds available capture groups in pattern (max: $maxGroups)',
          );
        }
      }

      // Check if using pattern
      if (rule is Map<String, dynamic> && rule.containsKey('pattern')) {
        final patternStr = rule['pattern'] as String?;
        if (patternStr != null) {
          try {
            RegExp(
              patternStr,
              caseSensitive: false,
              multiLine: true,
              dotAll: true,
            );
          } catch (e) {
            errors.add('Invalid regex pattern for $fieldName: $e');
          }
        }
      }
    }

    // Check that required fields are specified
    if (!extractionRules.containsKey('store_name')) {
      errors.add('Missing required field: store_name');
    }
    if (!extractionRules.containsKey('amount')) {
      errors.add('Missing required field: amount');
    }

    return errors;
  }

  /// Test parsing an SMS with a pattern and extraction rules
  /// Returns parsed data if successful, null otherwise
  static ParsedSmsData? testPattern(
    String smsBody,
    String pattern,
    String extractionRulesJson,
  ) {
    return parseSmsWithRules(smsBody, pattern, extractionRulesJson);
  }
}
