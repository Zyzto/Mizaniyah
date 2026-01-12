import 'dart:convert';
import 'package:flutter_logging_service/flutter_logging_service.dart';
import 'package:mizaniyah/core/database/app_database.dart' as db;

/// Parsed SMS data structure
class ParsedSmsData {
  final String? storeName;
  final double? amount;
  final String? currency;
  final String? cardLast4Digits;

  ParsedSmsData({
    this.storeName,
    this.amount,
    this.currency,
    this.cardLast4Digits,
  });

  Map<String, dynamic> toJson() => {
    'store_name': storeName,
    'amount': amount,
    'currency': currency,
    'card_last4': cardLast4Digits,
  };

  factory ParsedSmsData.fromJson(Map<String, dynamic> json) => ParsedSmsData(
    storeName: json['store_name'] as String?,
    amount: json['amount'] as double?,
    currency: json['currency'] as String?,
    cardLast4Digits: json['card_last4'] as String?,
  );
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
      // Use capture group from main pattern
      if (rule.containsKey('group') && mainMatch != null) {
        final groupIndex = rule['group'];
        if (groupIndex is int &&
            groupIndex > 0 &&
            groupIndex <= mainMatch.groupCount) {
          return mainMatch.group(groupIndex)?.trim();
        }
      }

      // Use separate regex pattern
      if (rule.containsKey('pattern')) {
        final patternStr = rule['pattern'] as String?;
        if (patternStr != null) {
          try {
            final pattern = RegExp(patternStr, caseSensitive: false);
            final match = pattern.firstMatch(smsBody);
            if (match != null && match.groupCount >= 1) {
              return match.group(1)?.trim();
            }
          } catch (e) {
            Log.warning(
              'Invalid regex pattern in extraction rule: $patternStr',
            );
          }
        }
      }
    }

    // Legacy support: direct regex pattern string
    if (rule is String && rule.isNotEmpty) {
      try {
        final pattern = RegExp(rule, caseSensitive: false);
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

  /// Parse SMS using pattern and extraction rules
  /// Returns ParsedSmsData if successful, null otherwise
  static ParsedSmsData? parseSmsWithRules(
    String smsBody,
    String pattern,
    String extractionRulesJson,
  ) {
    try {
      // Check if SMS matches the template pattern
      final patternRegex = RegExp(pattern, caseSensitive: false);
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
      );
    } catch (e, stackTrace) {
      Log.error(
        'Failed to parse SMS with pattern',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  /// Parse SMS using a template
  /// Returns ParsedSmsData if successful, null otherwise
  static ParsedSmsData? parseSms(String smsBody, db.SmsTemplate template) {
    return parseSmsWithRules(
      smsBody,
      template.pattern,
      template.extractionRules,
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
      final patternRegex = RegExp(pattern, caseSensitive: false);
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
  static Map<String, dynamic>? findMatchingTemplate(
    String smsBody,
    List<db.SmsTemplate> templates,
  ) {
    // Sort templates by priority (higher priority first)
    final sortedTemplates = List<db.SmsTemplate>.from(templates)
      ..sort((a, b) => b.priority.compareTo(a.priority));

    double bestConfidence = 0.0;
    Map<String, dynamic>? bestMatch;

    for (final template in sortedTemplates) {
      final parsed = parseSms(smsBody, template);
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
      RegExp(pattern, caseSensitive: false);
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
    final patternRegex = RegExp(pattern, caseSensitive: false);
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
            RegExp(patternStr, caseSensitive: false);
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
