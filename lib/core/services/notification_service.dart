import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_logging_service/flutter_logging_service.dart';
import 'package:drift/drift.dart' as drift;
import '../database/daos/notification_history_dao.dart';
import '../database/app_database.dart';
import '../constants/app_constants.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin? _notifications = kIsWeb
      ? null
      : FlutterLocalNotificationsPlugin();

  static bool _initialized = false;
  static GoRouter? _router;

  static Future<void> init() async {
    // This app is Android-only (iOS on hold)
    if (kIsWeb) {
      _initialized = true;
      Log.warning(
        'NotificationService: This app is mobile-only, web platform not supported',
      );
      return;
    }

    try {
      const androidSettings = AndroidInitializationSettings(
        '@mipmap/ic_launcher',
      );
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _notifications!.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      // Create Android notification channel
      if (!kIsWeb) {
        final androidPlugin = _notifications!
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
        if (androidPlugin != null) {
          try {
            final androidChannel = const AndroidNotificationChannel(
              AppConstants.notificationChannelSmsTransactions,
              AppConstants.notificationChannelSmsTransactionsName,
              description: 'Notifications for detected SMS transactions',
              importance: Importance.high,
              enableVibration: true,
              enableLights: true,
              playSound: true,
              showBadge: true,
            );
            await androidPlugin.createNotificationChannel(androidChannel);
            Log.info('Android notification channel created');
          } catch (e, stackTrace) {
            Log.warning(
              'Failed to create Android notification channel',
              error: e,
              stackTrace: stackTrace,
            );
          }
        }
      }

      _initialized = true;
      Log.info('NotificationService initialized');
    } catch (e, stackTrace) {
      Log.error(
        'Failed to initialize NotificationService',
        error: e,
        stackTrace: stackTrace,
      );
      _initialized = false;
    }
  }

  static NotificationHistoryDao? _notificationHistoryDao;

  static void setNotificationHistoryDao(NotificationHistoryDao dao) {
    _notificationHistoryDao = dao;
  }

  static void _onNotificationTapped(NotificationResponse response) {
    Log.info('Notification tapped: ${response.payload}');

    final payload = response.payload;
    if (payload != null && payload.isNotEmpty) {
      try {
        // Parse payload: "sms_confirmation:{id}"
        if (payload.startsWith(
          NotificationConstants.payloadSmsConfirmationPrefix,
        )) {
          final idStr = payload.substring(
            NotificationConstants.payloadSmsConfirmationPrefix.length,
          );
          final id = int.tryParse(idStr);

          // Mark notification as tapped in history
          // TODO: After running build_runner, implement notification lookup by confirmationId
          if (id != null && _notificationHistoryDao != null) {
            // Find notification by confirmationId and mark as tapped
            // This requires querying by confirmationId first, then marking as tapped
            // Implementation will be added after build_runner generates the code
            Log.debug(
              'Notification tap tracking ready (requires build_runner)',
            );
          }

          if (id != null && _router != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              try {
                _router!.go('/accounts'); // Navigate to SMS notifications page
                Log.info(
                  'Navigated to SMS notifications from notification tap',
                );
              } catch (e, stackTrace) {
                Log.error(
                  'Failed to navigate using GoRouter',
                  error: e,
                  stackTrace: stackTrace,
                );
              }
            });
          }
        }
      } catch (e, stackTrace) {
        Log.error(
          'Failed to handle notification tap',
          error: e,
          stackTrace: stackTrace,
        );
      }
    }
  }

  static void setRouter(GoRouter router) {
    _router = router;
  }

  static Future<void> requestPermissions() async {
    if (kIsWeb || _notifications == null) {
      return;
    }

    try {
      final androidPlugin = _notifications!
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      if (androidPlugin != null) {
        await androidPlugin.requestNotificationsPermission();
      }

      final iosPlugin = _notifications!
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      if (iosPlugin != null) {
        await iosPlugin.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
      }
    } catch (e, stackTrace) {
      Log.error(
        'Failed to request notification permissions',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  static Future<void> showSmsConfirmationNotification(
    int confirmationId,
    String storeName,
    double amount,
    String currency,
  ) async {
    if (kIsWeb || _notifications == null || !_initialized) {
      return;
    }

    try {
      final androidDetails = const AndroidNotificationDetails(
        AppConstants.notificationChannelSmsTransactions,
        AppConstants.notificationChannelSmsTransactionsName,
        channelDescription: 'Notifications for detected SMS transactions',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        enableVibration: true,
        playSound: true,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      final title = 'Transaction Detected';
      final body = '$storeName: ${amount.toStringAsFixed(2)} $currency';
      final payload =
          '${NotificationConstants.payloadSmsConfirmationPrefix}$confirmationId';

      await _notifications!.show(
        confirmationId,
        title,
        body,
        details,
        payload: payload,
      );

      // Track notification in history
      if (_notificationHistoryDao != null) {
        try {
          await _notificationHistoryDao!.insertNotification(
            NotificationHistoryCompanion.insert(
              confirmationId: drift.Value(confirmationId),
              notificationType: NotificationConstants.typeSmsConfirmation,
              title: title,
              body: body,
              payload: drift.Value(payload),
            ),
          );
        } catch (e) {
          Log.warning('Failed to track notification in history: $e');
        }
      }

      Log.info('SMS confirmation notification shown for id=$confirmationId');
    } catch (e, stackTrace) {
      Log.error(
        'Failed to show SMS confirmation notification',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }
}
