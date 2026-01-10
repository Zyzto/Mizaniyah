import 'package:drift/drift.dart';
import '../app_database.dart';
import '../models/sms_templates.dart';
import 'package:flutter_logging_service/flutter_logging_service.dart';
import 'base_dao_mixin.dart';

part 'sms_template_dao.g.dart';

@DriftAccessor(tables: [SmsTemplates])
class SmsTemplateDao extends DatabaseAccessor<AppDatabase>
    with _$SmsTemplateDaoMixin, Loggable, BaseDaoMixin {
  SmsTemplateDao(super.db);

  Future<List<SmsTemplate>> getAllTemplates() async {
    return executeWithErrorHandling<List<SmsTemplate>>(
      operationName: 'getAllTemplates',
      operation: () async {
        final result = await select(db.smsTemplates).get();
        logInfo('getAllTemplates() returned ${result.length} templates');
        return result;
      },
      onError: () => <SmsTemplate>[],
    );
  }

  Stream<List<SmsTemplate>> watchAllTemplates() {
    logDebug('watchAllTemplates() called');
    return select(db.smsTemplates).watch();
  }

  /// Get active templates that match a sender (SMS sender address)
  /// Templates without senderPattern match all senders
  /// Templates with senderPattern only match if pattern matches the sender
  Future<List<SmsTemplate>> getActiveTemplatesBySender(String sender) async {
    return executeWithErrorHandling<List<SmsTemplate>>(
      operationName: 'getActiveTemplatesBySender',
      operation: () async {
        // Get all active templates (we'll filter by sender pattern in memory)
        // This is acceptable since we typically have few templates
        final allActive = await (select(db.smsTemplates)
              ..where((t) => t.isActive.equals(true))
              ..orderBy([(t) => OrderingTerm.desc(t.priority)]))
            .get();

        // Filter templates that match the sender
        final filtered = allActive.where((t) {
          // Template without sender pattern matches all senders
          if (t.senderPattern == null || t.senderPattern!.isEmpty) {
            return true;
          }
          // Template with sender pattern must match
          try {
            final templatePattern = RegExp(
              t.senderPattern!,
              caseSensitive: false,
            );
            return templatePattern.hasMatch(sender);
          } catch (e) {
            logWarning('Invalid sender pattern in template ${t.id}: ${t.senderPattern}');
            return false; // Invalid pattern, skip this template
          }
        }).toList();

        logInfo(
          'getActiveTemplatesBySender() returned ${filtered.length} templates for sender: $sender',
        );
        return filtered;
      },
      onError: () => <SmsTemplate>[],
    );
  }

  Future<List<SmsTemplate>> getActiveTemplates() async {
    return executeWithErrorHandling<List<SmsTemplate>>(
      operationName: 'getActiveTemplates',
      operation: () async {
        final result =
            await (select(db.smsTemplates)
                  ..where((t) => t.isActive.equals(true))
                  ..orderBy([(t) => OrderingTerm.desc(t.priority)]))
                .get();
        logInfo('getActiveTemplates() returned ${result.length} templates');
        return result;
      },
      onError: () => <SmsTemplate>[],
    );
  }

  Future<SmsTemplate?> getTemplateById(int id) async {
    return executeWithErrorHandling<SmsTemplate?>(
      operationName: 'getTemplateById',
      operation: () async {
        final result = await (select(
          db.smsTemplates,
        )..where((t) => t.id.equals(id))).getSingleOrNull();
        logDebug(
          'getTemplateById(id=$id) returned ${result != null ? "template" : "null"}',
        );
        return result;
      },
      onError: () => null,
    );
  }

  Future<int> insertTemplate(SmsTemplatesCompanion template) async {
    return executeWithErrorHandling<int>(
      operationName: 'insertTemplate',
      operation: () async {
        // Validate data before insertion
        final pattern = template.pattern.value;
        validateNonEmptyString(pattern, 'Pattern');

        final id = await into(db.smsTemplates).insert(template);
        logInfo('insertTemplate() inserted template with id=$id');
        return id;
      },
    );
  }

  Future<bool> updateTemplate(SmsTemplatesCompanion template) async {
    final id = template.id.value;
    return executeWithErrorHandling<bool>(
      operationName: 'updateTemplate',
      operation: () async {
        // Validate data before update
        if (template.pattern.present) {
          validateNonEmptyString(template.pattern.value, 'Pattern');
        }

        final result = await update(db.smsTemplates).replace(template);
        logInfo('updateTemplate(id=$id) updated successfully');
        return result;
      },
    );
  }

  Future<int> deleteTemplate(int id) async {
    return executeWithErrorHandling<int>(
      operationName: 'deleteTemplate',
      operation: () async {
        final result = await (delete(
          db.smsTemplates,
        )..where((t) => t.id.equals(id))).go();
        logInfo('deleteTemplate(id=$id) deleted $result rows');
        return result;
      },
    );
  }
}
