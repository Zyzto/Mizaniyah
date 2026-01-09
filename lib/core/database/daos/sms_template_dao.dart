import 'package:drift/drift.dart';
import '../app_database.dart';
import '../models/sms_templates.dart';
import 'package:flutter_logging_service/flutter_logging_service.dart';

part 'sms_template_dao.g.dart';

@DriftAccessor(tables: [SmsTemplates])
class SmsTemplateDao extends DatabaseAccessor<AppDatabase>
    with _$SmsTemplateDaoMixin, Loggable {
  SmsTemplateDao(super.db);

  Future<List<SmsTemplate>> getAllTemplates() async {
    logDebug('getAllTemplates() called');
    try {
      final result = await select(db.smsTemplates).get();
      logInfo('getAllTemplates() returned ${result.length} templates');
      return result;
    } catch (e, stackTrace) {
      logError('getAllTemplates() failed', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<List<SmsTemplate>> getTemplatesByBankId(int bankId) async {
    logDebug('getTemplatesByBankId(bankId=$bankId) called');
    try {
      final result =
          await (select(db.smsTemplates)
                ..where((t) => t.bankId.equals(bankId))
                ..where((t) => t.isActive.equals(true))
                ..orderBy([(t) => OrderingTerm.desc(t.priority)]))
              .get();
      logInfo('getTemplatesByBankId() returned ${result.length} templates');
      return result;
    } catch (e, stackTrace) {
      logError(
        'getTemplatesByBankId() failed',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<List<SmsTemplate>> getActiveTemplates() async {
    logDebug('getActiveTemplates() called');
    try {
      final result =
          await (select(db.smsTemplates)
                ..where((t) => t.isActive.equals(true))
                ..orderBy([(t) => OrderingTerm.desc(t.priority)]))
              .get();
      logInfo('getActiveTemplates() returned ${result.length} templates');
      return result;
    } catch (e, stackTrace) {
      logError('getActiveTemplates() failed', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<SmsTemplate?> getTemplateById(int id) async {
    logDebug('getTemplateById(id=$id) called');
    try {
      final result = await (select(
        db.smsTemplates,
      )..where((t) => t.id.equals(id))).getSingleOrNull();
      logDebug(
        'getTemplateById(id=$id) returned ${result != null ? "template" : "null"}',
      );
      return result;
    } catch (e, stackTrace) {
      logError(
        'getTemplateById(id=$id) failed',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<int> insertTemplate(SmsTemplatesCompanion template) async {
    logDebug('insertTemplate(bankId=${template.bankId.value}) called');
    try {
      final id = await into(db.smsTemplates).insert(template);
      logInfo('insertTemplate() inserted template with id=$id');
      return id;
    } catch (e, stackTrace) {
      logError('insertTemplate() failed', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<bool> updateTemplate(SmsTemplatesCompanion template) async {
    final id = template.id.value;
    logDebug('updateTemplate(id=$id) called');
    try {
      final result = await update(db.smsTemplates).replace(template);
      logInfo('updateTemplate(id=$id) updated successfully');
      return result;
    } catch (e, stackTrace) {
      logError(
        'updateTemplate(id=$id) failed',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<int> deleteTemplate(int id) async {
    logDebug('deleteTemplate(id=$id) called');
    try {
      final result = await (delete(
        db.smsTemplates,
      )..where((t) => t.id.equals(id))).go();
      logInfo('deleteTemplate(id=$id) deleted $result rows');
      return result;
    } catch (e, stackTrace) {
      logError(
        'deleteTemplate(id=$id) failed',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }
}
