import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_logging_service/flutter_logging_service.dart';

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
            final androidChannel = AndroidNotificationChannel(
              'sms_transactions',
              'SMS Transactions',
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

  static void _onNotificationTapped(NotificationResponse response) {
    Log.info('Notification tapped: ${response.payload}');

    final payload = response.payload;
    if (payload != null && payload.isNotEmpty) {
      try {
        // Parse payload: "sms_confirmation:{id}"
        if (payload.startsWith('sms_confirmation:')) {
          final idStr = payload.substring('sms_confirmation:'.length);
          final id = int.tryParse(idStr);
          if (id != null && _router != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              try {
                _router!.go('/transactions/sms/$id');
                Log.info('Navigated to SMS confirmation from notification tap');
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
      final androidDetails = AndroidNotificationDetails(
        'sms_transactions',
        'SMS Transactions',
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

      await _notifications!.show(
        confirmationId,
        'Transaction Detected',
        '$storeName: ${amount.toStringAsFixed(2)} $currency',
        details,
        payload: 'sms_confirmation:$confirmationId',
      );

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
