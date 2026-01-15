import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:workmanager/workmanager.dart';
import 'package:flutter_logging_service/flutter_logging_service.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:mizaniyah/core/services/notification_service.dart';
import 'package:mizaniyah/core/services/sms_detection_service.dart';
import 'package:mizaniyah/core/services/workmanager_dispatcher.dart';
import 'package:mizaniyah/core/database/daos/sms_template_dao.dart';
import 'package:mizaniyah/core/database/daos/card_dao.dart';
import 'package:mizaniyah/core/database/daos/pending_sms_confirmation_dao.dart';
import 'package:mizaniyah/core/database/daos/transaction_dao.dart';
import 'package:mizaniyah/core/database/daos/category_dao.dart';
import 'package:mizaniyah/core/database/daos/notification_history_dao.dart';
import 'package:mizaniyah/core/services/category_seeder.dart';
import 'package:mizaniyah/features/settings/providers/settings_framework_providers.dart';
import 'package:flutter_settings_framework/flutter_settings_framework.dart';
import 'package:mizaniyah/core/database/providers/database_provider.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize localization
  await EasyLocalization.ensureInitialized();

  // Set initial locale from saved preferences (if available)
  // The locale will be updated from settings in the App widget

  // Set up error handlers FIRST
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    LoggingService.severe(
      'Flutter framework error: ${details.exception}',
      component: 'CrashHandler',
      error: details.exception,
      stackTrace: details.stack,
    );
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    LoggingService.severe(
      'Uncaught async error: $error',
      component: 'CrashHandler',
      error: error,
      stackTrace: stack,
    );
    return true;
  };

  // Initialize logging service
  try {
    await LoggingService.init(
      const LoggingConfig(
        appName: 'Mizaniyah',
        logFileName: 'mizaniyah.log',
        crashLogFileName: 'mizaniyah_crashes.log',
      ),
    );
  } catch (e) {
    // Continue even if logging fails
  }

  // Initialize database (will be created when first accessed)
  Log.debug('Database will be initialized on first access');

  // Initialize notifications
  try {
    await NotificationService.init();
    await NotificationService.requestPermissions();
    Log.debug('NotificationService initialized successfully');
  } catch (e, stackTrace) {
    Log.error(
      'Failed to initialize NotificationService',
      error: e,
      stackTrace: stackTrace,
    );
  }

  // Initialize WorkManager for background tasks
  // This app is Android-only (iOS on hold)
  if (!kIsWeb) {
    try {
      await Workmanager().initialize(callbackDispatcher);
      Log.debug('WorkManager initialized successfully');

      // Register periodic task for cleaning up expired confirmations
      await Workmanager().registerPeriodicTask(
        'cleanup_expired_confirmations',
        'cleanup_expired_confirmations',
        frequency: const Duration(hours: 1),
      );
    } catch (e, stackTrace) {
      Log.error(
        'Failed to initialize WorkManager',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  // Initialize settings framework
  SettingsProviders? settingsProviders;
  try {
    settingsProviders = await initializeMizaniyahSettings();
    Log.debug('Settings framework initialized successfully');
  } catch (e, stackTrace) {
    Log.error(
      'Failed to initialize settings framework',
      error: e,
      stackTrace: stackTrace,
    );
  }

  // Initialize SMS detection service and seed categories (after database is ready)
  // This will be done after the app starts to ensure database is initialized
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    try {
      final database = getDatabase();
      final smsTemplateDao = SmsTemplateDao(database);
      final cardDao = CardDao(database);
      final pendingSmsDao = PendingSmsConfirmationDao(database);
      final transactionDao = TransactionDao(database);
      final categoryDao = CategoryDao(database);
      final notificationHistoryDao = NotificationHistoryDao(database);

      // Set notification history DAO in notification service
      NotificationService.setNotificationHistoryDao(notificationHistoryDao);
      Log.debug('Notification history DAO set');

      // Seed predefined categories
      final categorySeeder = CategorySeeder(categoryDao);
      await categorySeeder.seedPredefinedCategories();
      Log.debug('Predefined categories seeded');

      // Initialize SMS detection service (listening will be controlled by settings provider)
      // Default to not starting - the provider will start it if enabled
      await SmsDetectionService.instance.init(
        smsTemplateDao,
        pendingSmsDao,
        transactionDao: transactionDao,
        cardDao: cardDao,
        categoryDao: categoryDao,
        shouldStartListening: false, // Will be controlled by settings provider
      );
      Log.debug(
        'SMS detection service initialized (listening controlled by settings)',
      );
    } catch (e, stackTrace) {
      Log.error(
        'Failed to initialize services',
        error: e,
        stackTrace: stackTrace,
      );
    }
  });

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('ar')],
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      child: ProviderScope(
        overrides: [
          if (settingsProviders != null) ...[
            mizaniyahSettingsControllerProvider.overrideWithValue(
              settingsProviders.controller,
            ),
            mizaniyahSettingsSearchIndexProvider.overrideWithValue(
              settingsProviders.searchIndex,
            ),
            mizaniyahSettingsProvider.overrideWithValue(settingsProviders),
          ],
        ],
        child: const App(),
      ),
    ),
  );
}
