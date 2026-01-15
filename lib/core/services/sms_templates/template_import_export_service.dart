import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:flutter_logging_service/flutter_logging_service.dart';
import 'package:mizaniyah/core/database/app_database.dart' as db;
import 'package:mizaniyah/core/database/daos/sms_template_dao.dart';
import 'package:mizaniyah/core/services/sms_parsing_service.dart';

/// Template export format
class TemplateExport {
  final String version;
  final DateTime exportedAt;
  final List<Map<String, dynamic>> templates;

  TemplateExport({
    required this.version,
    required this.exportedAt,
    required this.templates,
  });

  Map<String, dynamic> toJson() => {
    'version': version,
    'exported_at': exportedAt.toIso8601String(),
    'templates': templates,
  };

  factory TemplateExport.fromJson(Map<String, dynamic> json) => TemplateExport(
    version: json['version'] as String,
    exportedAt: DateTime.parse(json['exported_at'] as String),
    templates: (json['templates'] as List)
        .map((e) => e as Map<String, dynamic>)
        .toList(),
  );
}

/// Service for importing and exporting SMS templates
class TemplateImportExportService with Loggable {
  final SmsTemplateDao _smsTemplateDao;
  static const String _exportVersion = '1.0';

  TemplateImportExportService(this._smsTemplateDao);

  /// Export all templates to JSON
  Future<String> exportTemplates({bool activeOnly = false}) async {
    try {
      final templates = activeOnly
          ? await _smsTemplateDao.getActiveTemplates()
          : await _smsTemplateDao.getAllTemplates();

      final templatesJson = templates
          .map(
            (template) => {
              'sender_pattern': template.senderPattern,
              'pattern': template.pattern,
              'extraction_rules': template.extractionRules,
              'priority': template.priority,
              'is_active': template.isActive,
            },
          )
          .toList();

      final export = TemplateExport(
        version: _exportVersion,
        exportedAt: DateTime.now(),
        templates: templatesJson,
      );

      final json = jsonEncode(export.toJson());
      logInfo('Exported ${templates.length} templates');
      return json;
    } catch (e, stackTrace) {
      logError('Failed to export templates', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Import templates from JSON
  /// Returns (imported count, skipped count, errors)
  Future<({int imported, int skipped, List<String> errors})> importTemplates(
    String jsonString, {
    bool validateBeforeImport = true,
    bool overwriteExisting = false,
  }) async {
    final errors = <String>[];
    int imported = 0;
    int skipped = 0;

    try {
      final export = TemplateExport.fromJson(
        jsonDecode(jsonString) as Map<String, dynamic>,
      );

      if (export.version != _exportVersion) {
        errors.add('Unsupported export version: ${export.version}');
        return (imported: 0, skipped: 0, errors: errors);
      }

      // Get existing templates to check for duplicates
      final existingTemplates = await _smsTemplateDao.getAllTemplates();
      final existingKeys = existingTemplates
          .map((t) => '${t.senderPattern}|${t.pattern}')
          .toSet();

      for (final templateJson in export.templates) {
        try {
          final senderPattern = templateJson['sender_pattern'] as String?;
          final pattern = templateJson['pattern'] as String?;
          final extractionRules = templateJson['extraction_rules'] as String?;
          final priority = templateJson['priority'] as int? ?? 0;
          final isActive = templateJson['is_active'] as bool? ?? true;

          if (senderPattern == null ||
              pattern == null ||
              extractionRules == null) {
            errors.add('Template missing required fields: $templateJson');
            skipped++;
            continue;
          }

          // Validate template if requested
          if (validateBeforeImport) {
            final validationErrors = SmsParsingService.validateTemplate(
              pattern,
              extractionRules,
            );
            if (validationErrors.isNotEmpty) {
              errors.add(
                'Template validation failed: ${validationErrors.join(", ")}',
              );
              skipped++;
              continue;
            }
          }

          // Check for duplicates
          final key = '$senderPattern|$pattern';
          if (existingKeys.contains(key) && !overwriteExisting) {
            logInfo('Skipping duplicate template: $key');
            skipped++;
            continue;
          }

          // Create or update template
          if (overwriteExisting && existingKeys.contains(key)) {
            // Find and update existing template
            final existing = existingTemplates.firstWhere(
              (t) => '${t.senderPattern}|${t.pattern}' == key,
            );
            await _smsTemplateDao.updateTemplate(
              db.SmsTemplatesCompanion(
                id: Value(existing.id),
                senderPattern: Value(senderPattern),
                pattern: Value(pattern),
                extractionRules: Value(extractionRules),
                priority: Value(priority),
                isActive: Value(isActive),
              ),
            );
            logInfo('Updated existing template: $key');
          } else {
            // Insert new template
            await _smsTemplateDao.insertTemplate(
              db.SmsTemplatesCompanion.insert(
                senderPattern: Value(senderPattern),
                pattern: pattern,
                extractionRules: extractionRules,
                priority: Value(priority),
                isActive: Value(isActive),
              ),
            );
            existingKeys.add(key);
            logInfo('Imported new template: $key');
          }

          imported++;
        } catch (e, stackTrace) {
          logError(
            'Failed to import template: $templateJson',
            error: e,
            stackTrace: stackTrace,
          );
          errors.add('Failed to import template: $e');
          skipped++;
        }
      }

      logInfo(
        'Import completed: imported=$imported, skipped=$skipped, errors=${errors.length}',
      );
      return (imported: imported, skipped: skipped, errors: errors);
    } catch (e, stackTrace) {
      logError('Failed to import templates', error: e, stackTrace: stackTrace);
      errors.add('Failed to parse import file: $e');
      return (imported: imported, skipped: skipped, errors: errors);
    }
  }

  /// Validate import file without importing
  Future<List<String>> validateImportFile(String jsonString) async {
    final errors = <String>[];

    try {
      final export = TemplateExport.fromJson(
        jsonDecode(jsonString) as Map<String, dynamic>,
      );

      if (export.version != _exportVersion) {
        errors.add('Unsupported export version: ${export.version}');
        return errors;
      }

      for (final templateJson in export.templates) {
        final pattern = templateJson['pattern'] as String?;
        final extractionRules = templateJson['extraction_rules'] as String?;

        if (pattern == null || extractionRules == null) {
          errors.add('Template missing required fields: $templateJson');
          continue;
        }

        final validationErrors = SmsParsingService.validateTemplate(
          pattern,
          extractionRules,
        );
        errors.addAll(validationErrors);
      }
    } catch (e) {
      errors.add('Failed to parse import file: $e');
    }

    return errors;
  }
}
