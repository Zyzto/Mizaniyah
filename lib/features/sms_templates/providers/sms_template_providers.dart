import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mizaniyah/core/database/app_database.dart' as db;
import 'package:flutter_logging_service/flutter_logging_service.dart';
import '../../../core/database/providers/dao_providers.dart';

final smsTemplatesProvider = StreamProvider<List<db.SmsTemplate>>((ref) async* {
  ref.keepAlive();
  final dao = ref.watch(smsTemplateDaoProvider);
  try {
    await for (final templates in dao.watchAllTemplates()) {
      yield templates;
    }
  } catch (e, stackTrace) {
    Log.error(
      'Error in smsTemplatesProvider stream',
      error: e,
      stackTrace: stackTrace,
    );
    yield []; // Yield empty list on error to prevent crashes
  }
});

final activeSmsTemplatesProvider =
    FutureProvider<List<db.SmsTemplate>>((ref) async {
  final dao = ref.watch(smsTemplateDaoProvider);
  try {
    return await dao.getActiveTemplates();
  } catch (e, stackTrace) {
    Log.error(
      'Error in activeSmsTemplatesProvider',
      error: e,
      stackTrace: stackTrace,
    );
    return [];
  }
});

final smsTemplateProvider =
    FutureProvider.family<db.SmsTemplate?, int>((ref, id) async {
  final dao = ref.watch(smsTemplateDaoProvider);
  try {
    return await dao.getTemplateById(id);
  } catch (e, stackTrace) {
    Log.error(
      'Error in smsTemplateProvider for id=$id',
      error: e,
      stackTrace: stackTrace,
    );
    return null;
  }
});
