import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mizaniyah/core/database/app_database.dart' as db;
import 'package:flutter_logging_service/flutter_logging_service.dart';
import '../../../core/database/providers/dao_providers.dart';

/// Stream provider for all SMS templates - reactive and persisted
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

/// Stream provider for pending SMS confirmations - reactive and persisted
final pendingSmsConfirmationsProvider =
    StreamProvider<List<db.PendingSmsConfirmation>>((ref) async* {
  ref.keepAlive();
  final dao = ref.watch(pendingSmsConfirmationDaoProvider);
  try {
    await for (final confirmations in dao.watchNonExpiredConfirmations()) {
      yield confirmations;
    }
  } catch (e, stackTrace) {
    Log.error(
      'Error in pendingSmsConfirmationsProvider stream',
      error: e,
      stackTrace: stackTrace,
    );
    yield []; // Yield empty list on error to prevent crashes
  }
});

/// Derived provider for active SMS templates only - computed from stream
final activeSmsTemplatesProvider = Provider<AsyncValue<List<db.SmsTemplate>>>((ref) {
  ref.keepAlive();
  final templatesAsync = ref.watch(smsTemplatesProvider);
  return templatesAsync.whenData(
    (templates) => templates.where((t) => t.isActive).toList(),
  );
});

/// Provider for a single SMS template by ID - kept alive to avoid refetching
final smsTemplateProvider =
    FutureProvider.family<db.SmsTemplate?, int>((ref, id) async {
  ref.keepAlive();
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
