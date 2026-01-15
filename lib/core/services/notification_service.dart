import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_logging_service/flutter_logging_service.dart';
import 'package:drift/drift.dart' as drift;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/daos/notification_history_dao.dart';
import '../database/app_database.dart';
import '../constants/app_constants.dart';
import 'notification_service/quiet_hours_service.dart';
import 'notification_service/queued_notification.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin? _notifications = kIsWeb
      ? null
      : FlutterLocalNotificationsPlugin();

  static bool _initialized = false;
  static GoRouter? _router;
  static QuietHoursService? _quietHoursService;
  static const String _queuedNotificationsKey = 'queued_notifications';

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

  static void setQuietHoursService(QuietHoursService service) {
    _quietHoursService = service;
  }

  static void _onNotificationTapped(NotificationResponse response) {
    Log.info(
      'Notification tapped: ${response.payload}, action: ${response.actionId}',
    );

    final payload = response.payload;
    final actionId = response.actionId;

    // Handle notification actions
    if (actionId != null) {
      _handleNotificationAction(actionId, payload);
      return;
    }

    // Handle notification tap (no action)
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
          if (id != null && _notificationHistoryDao != null) {
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

  /// Handle notification action (Approve, Reject, Edit)
  static void _handleNotificationAction(String actionId, String? payload) {
    if (payload == null || payload.isEmpty) {
      Log.warning('Notification action $actionId has no payload');
      return;
    }

    try {
      // Parse confirmation ID from payload
      if (!payload.startsWith(
        NotificationConstants.payloadSmsConfirmationPrefix,
      )) {
        Log.warning('Invalid notification payload: $payload');
        return;
      }

      final idStr = payload.substring(
        NotificationConstants.payloadSmsConfirmationPrefix.length,
      );
      final confirmationId = int.tryParse(idStr);

      if (confirmationId == null) {
        Log.warning('Invalid confirmation ID in payload: $idStr');
        return;
      }

      switch (actionId) {
        case 'approve':
          Log.info('Approve action triggered for confirmation $confirmationId');
          // Navigate to pending confirmations page - user can approve there
          if (_router != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              try {
                _router!.go('/accounts'); // Navigate to SMS notifications page
                Log.info('Navigated to approve confirmation $confirmationId');
              } catch (e, stackTrace) {
                Log.error(
                  'Failed to navigate for approve action',
                  error: e,
                  stackTrace: stackTrace,
                );
              }
            });
          }
          break;

        case 'reject':
          Log.info('Reject action triggered for confirmation $confirmationId');
          // TODO: Implement direct rejection via service
          // For now, navigate to page where user can reject
          if (_router != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              try {
                _router!.go('/accounts');
                Log.info('Navigated to reject confirmation $confirmationId');
              } catch (e, stackTrace) {
                Log.error(
                  'Failed to navigate for reject action',
                  error: e,
                  stackTrace: stackTrace,
                );
              }
            });
          }
          break;

        case 'edit':
          Log.info('Edit action triggered for confirmation $confirmationId');
          // Navigate to edit confirmation
          if (_router != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              try {
                _router!.go('/accounts');
                Log.info('Navigated to edit confirmation $confirmationId');
              } catch (e, stackTrace) {
                Log.error(
                  'Failed to navigate for edit action',
                  error: e,
                  stackTrace: stackTrace,
                );
              }
            });
          }
          break;

        default:
          Log.warning('Unknown notification action: $actionId');
      }
    } catch (e, stackTrace) {
      Log.error(
        'Failed to handle notification action: $actionId',
        error: e,
        stackTrace: stackTrace,
      );
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
      // Check if we're in quiet hours
      if (_quietHoursService != null &&
          _quietHoursService!.isQuietHours(DateTime.now())) {
        // Queue notification instead of showing it
        await _queueNotification(confirmationId, storeName, amount, currency);
        Log.info(
          'Notification queued during quiet hours for id=$confirmationId',
        );
        return;
      }

      // Show notification immediately with rich content
      final androidDetails = AndroidNotificationDetails(
        AppConstants.notificationChannelSmsTransactions,
        AppConstants.notificationChannelSmsTransactionsName,
        channelDescription: 'Notifications for detected SMS transactions',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        enableVibration: true,
        playSound: true,
        // Rich notification with big text style
        styleInformation: BigTextStyleInformation(
          '$storeName\nAmount: ${amount.toStringAsFixed(2)} $currency',
          contentTitle: 'Transaction Detected',
          summaryText: 'Tap to review',
        ),
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

  /// Queue a notification for later (during quiet hours)
  static Future<void> _queueNotification(
    int confirmationId,
    String storeName,
    double amount,
    String currency,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final queued = QueuedNotification(
        confirmationId: confirmationId,
        storeName: storeName,
        amount: amount,
        currency: currency,
        queuedAt: DateTime.now(),
      );

      // Get existing queued notifications
      final existingJson = prefs.getString(_queuedNotificationsKey);
      final queuedList = existingJson != null
          ? (jsonDecode(existingJson) as List)
                .map(
                  (e) => QueuedNotification.fromJson(e as Map<String, dynamic>),
                )
                .toList()
          : <QueuedNotification>[];

      // Add new notification
      queuedList.add(queued);

      // Save back
      final jsonList = queuedList.map((q) => q.toJson()).toList();
      await prefs.setString(_queuedNotificationsKey, jsonEncode(jsonList));
    } catch (e, stackTrace) {
      Log.error(
        'Failed to queue notification',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Process queued notifications (call when quiet hours end)
  static Future<void> processQueuedNotifications() async {
    if (kIsWeb || _notifications == null || !_initialized) {
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final queuedJson = prefs.getString(_queuedNotificationsKey);
      if (queuedJson == null || queuedJson.isEmpty) {
        return; // No queued notifications
      }

      final queuedList = (jsonDecode(queuedJson) as List)
          .map((e) => QueuedNotification.fromJson(e as Map<String, dynamic>))
          .toList();

      if (queuedList.isEmpty) {
        return;
      }

      // Clear queued notifications
      await prefs.remove(_queuedNotificationsKey);

      // Show summary notification if multiple, or individual if one
      if (queuedList.length == 1) {
        final queued = queuedList.first;
        await showSmsConfirmationNotification(
          queued.confirmationId,
          queued.storeName,
          queued.amount,
          queued.currency,
        );
      } else {
        // Show summary notification
        final totalAmount = queuedList.fold<double>(
          0.0,
          (sum, q) => sum + q.amount,
        );
        final currency = queuedList.first.currency; // Assume same currency

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

        await _notifications!.show(
          999999, // Special ID for summary
          '${queuedList.length} Transactions Detected',
          'Total: ${totalAmount.toStringAsFixed(2)} $currency',
          details,
        );

        Log.info(
          'Summary notification shown for ${queuedList.length} queued transactions',
        );
      }
    } catch (e, stackTrace) {
      Log.error(
        'Failed to process queued notifications',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }
}
