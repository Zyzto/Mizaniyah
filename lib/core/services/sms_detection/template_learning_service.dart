import 'dart:convert';
import 'package:flutter_logging_service/flutter_logging_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mizaniyah/core/database/daos/sms_template_dao.dart';

/// Represents a user correction to parsed SMS data
class UserCorrection {
  final String smsBody;
  final String smsSender;
  final Map<String, dynamic> originalParsedData;
  final Map<String, dynamic> correctedData;
  final int? templateId;
  final DateTime correctedAt;

  UserCorrection({
    required this.smsBody,
    required this.smsSender,
    required this.originalParsedData,
    required this.correctedData,
    this.templateId,
    required this.correctedAt,
  });

  Map<String, dynamic> toJson() => {
    'sms_body': smsBody,
    'sms_sender': smsSender,
    'original_parsed_data': originalParsedData,
    'corrected_data': correctedData,
    'template_id': templateId,
    'corrected_at': correctedAt.toIso8601String(),
  };

  factory UserCorrection.fromJson(Map<String, dynamic> json) => UserCorrection(
    smsBody: json['sms_body'] as String,
    smsSender: json['sms_sender'] as String,
    originalParsedData: json['original_parsed_data'] as Map<String, dynamic>,
    correctedData: json['corrected_data'] as Map<String, dynamic>,
    templateId: json['template_id'] as int?,
    correctedAt: DateTime.parse(json['corrected_at'] as String),
  );
}

/// Service for learning from user corrections to improve templates
class TemplateLearningService with Loggable {
  final SmsTemplateDao _smsTemplateDao;
  final SharedPreferences _prefs;
  static const String _correctionsKey = 'template_learning_corrections';
  static const int _minCorrectionsForSuggestion = 3;

  TemplateLearningService(this._smsTemplateDao, this._prefs);

  /// Record a user correction
  Future<void> recordCorrection({
    required String smsBody,
    required String smsSender,
    required Map<String, dynamic> originalParsedData,
    required Map<String, dynamic> correctedData,
    int? templateId,
  }) async {
    try {
      final correction = UserCorrection(
        smsBody: smsBody,
        smsSender: smsSender,
        originalParsedData: originalParsedData,
        correctedData: correctedData,
        templateId: templateId,
        correctedAt: DateTime.now(),
      );

      final corrections = await _getAllCorrections();
      corrections.add(correction);

      // Keep only last 100 corrections
      if (corrections.length > 100) {
        corrections.removeRange(0, corrections.length - 100);
      }

      await _saveCorrections(corrections);
      logInfo('Recorded user correction for template learning');

      // Check if we have enough corrections to suggest improvements
      if (templateId != null) {
        final templateCorrections = corrections
            .where((c) => c.templateId == templateId)
            .toList();
        if (templateCorrections.length >= _minCorrectionsForSuggestion) {
          await _analyzeCorrectionsForTemplate(templateId, templateCorrections);
        }
      }
    } catch (e, stackTrace) {
      logError('Failed to record correction', error: e, stackTrace: stackTrace);
    }
  }

  /// Analyze corrections for a template and suggest improvements
  Future<void> _analyzeCorrectionsForTemplate(
    int templateId,
    List<UserCorrection> corrections,
  ) async {
    try {
      final template = await _smsTemplateDao.getTemplateById(templateId);
      if (template == null) {
        return;
      }

      // Analyze common correction patterns
      final patternChanges = <String, int>{};
      final extractionRuleChanges = <String, int>{};

      for (final correction in corrections) {
        // Compare original vs corrected data
        final original = correction.originalParsedData;
        final corrected = correction.correctedData;

        // Check for store name changes
        final originalStore = original['store_name'] as String?;
        final correctedStore = corrected['store_name'] as String?;
        if (originalStore != correctedStore && correctedStore != null) {
          // Try to find pattern that would match corrected store name
          final pattern = _extractPatternFromCorrection(
            correction.smsBody,
            correctedStore,
          );
          if (pattern != null) {
            patternChanges[pattern] = (patternChanges[pattern] ?? 0) + 1;
          }
        }

        // Check for amount changes
        final originalAmount = original['amount'] as num?;
        final correctedAmount = corrected['amount'] as num?;
        if (originalAmount != correctedAmount && correctedAmount != null) {
          // Amount extraction might need improvement
          extractionRuleChanges['amount'] =
              (extractionRuleChanges['amount'] ?? 0) + 1;
        }
      }

      // Log suggestions (could be shown to user later)
      if (patternChanges.isNotEmpty || extractionRuleChanges.isNotEmpty) {
        logInfo(
          'Template learning suggestions for template $templateId: '
          'patternChanges=$patternChanges, extractionRuleChanges=$extractionRuleChanges',
        );
      }
    } catch (e, stackTrace) {
      logError(
        'Failed to analyze corrections',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Extract a pattern from correction (simple heuristic)
  String? _extractPatternFromCorrection(String smsBody, String correctedValue) {
    // Simple approach: find the corrected value in SMS and extract surrounding context
    final index = smsBody.toLowerCase().indexOf(correctedValue.toLowerCase());
    if (index < 0) {
      return null;
    }

    // Extract a few words around the match
    final start = (index - 20).clamp(0, smsBody.length);
    final end = (index + correctedValue.length + 20).clamp(0, smsBody.length);
    final context = smsBody.substring(start, end);

    // Create a simple pattern (this is a basic implementation)
    return context.replaceAll(RegExp(r'\d+'), r'\d+');
  }

  /// Get all corrections
  Future<List<UserCorrection>> _getAllCorrections() async {
    try {
      final json = _prefs.getString(_correctionsKey);
      if (json == null || json.isEmpty) {
        return [];
      }
      final list = jsonDecode(json) as List;
      return list
          .map((e) => UserCorrection.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      logWarning('Failed to get corrections: $e');
      return [];
    }
  }

  /// Save corrections
  Future<void> _saveCorrections(List<UserCorrection> corrections) async {
    final json = jsonEncode(corrections.map((c) => c.toJson()).toList());
    await _prefs.setString(_correctionsKey, json);
  }

  /// Get learning suggestions for a template
  Future<List<String>> getSuggestionsForTemplate(int templateId) async {
    try {
      final corrections = await _getAllCorrections();
      final templateCorrections = corrections
          .where((c) => c.templateId == templateId)
          .toList();

      if (templateCorrections.length < _minCorrectionsForSuggestion) {
        return [];
      }

      final suggestions = <String>[];

      // Analyze common issues
      int storeNameMismatches = 0;
      int amountMismatches = 0;

      for (final correction in templateCorrections) {
        final original = correction.originalParsedData;
        final corrected = correction.correctedData;

        if (original['store_name'] != corrected['store_name']) {
          storeNameMismatches++;
        }
        if (original['amount'] != corrected['amount']) {
          amountMismatches++;
        }
      }

      if (storeNameMismatches >= _minCorrectionsForSuggestion) {
        suggestions.add(
          'Store name extraction may need improvement. '
          '$storeNameMismatches corrections suggest different store names.',
        );
      }

      if (amountMismatches >= _minCorrectionsForSuggestion) {
        suggestions.add(
          'Amount extraction may need improvement. '
          '$amountMismatches corrections suggest different amounts.',
        );
      }

      return suggestions;
    } catch (e, stackTrace) {
      logError('Failed to get suggestions', error: e, stackTrace: stackTrace);
      return [];
    }
  }

  /// Clear all corrections
  Future<void> clearCorrections() async {
    await _prefs.remove(_correctionsKey);
    logInfo('Cleared all template learning corrections');
  }
}
