import 'package:drift/drift.dart';
import '../app_database.dart';
import '../models/notification_history.dart';
import 'package:flutter_logging_service/flutter_logging_service.dart';
import 'base_dao_mixin.dart';

part 'notification_history_dao.g.dart';

@DriftAccessor(tables: [NotificationHistory])
class NotificationHistoryDao extends DatabaseAccessor<AppDatabase>
    with _$NotificationHistoryDaoMixin, Loggable, BaseDaoMixin {
  NotificationHistoryDao(super.db);

  Future<List<NotificationHistoryData>> getAllNotifications() async {
    return executeWithErrorHandling<List<NotificationHistoryData>>(
      operationName: 'getAllNotifications',
      operation: () async {
        final result = await (select(notificationHistory)
              ..orderBy([(n) => OrderingTerm.desc(n.createdAt)]))
            .get();
        logInfo(
          'getAllNotifications() returned ${result.length} notifications',
        );
        return result;
      },
      onError: () => <NotificationHistoryData>[],
    );
  }

  Stream<List<NotificationHistoryData>> watchAllNotifications() {
    logDebug('watchAllNotifications() called');
    return (select(notificationHistory)
          ..orderBy([(n) => OrderingTerm.desc(n.createdAt)]))
        .watch();
  }

  Future<List<NotificationHistoryData>> getNotificationsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    return executeWithErrorHandling<List<NotificationHistoryData>>(
      operationName: 'getNotificationsByDateRange',
      operation: () async {
        final result = await (select(notificationHistory)
              ..where((n) => n.createdAt.isBetweenValues(startDate, endDate))
              ..orderBy([(n) => OrderingTerm.desc(n.createdAt)]))
            .get();
        logInfo(
          'getNotificationsByDateRange() returned ${result.length} notifications',
        );
        return result;
      },
      onError: () => <NotificationHistoryData>[],
    );
  }

  Future<List<NotificationHistoryData>> getNotificationsByType(
    String notificationType,
  ) async {
    return executeWithErrorHandling<List<NotificationHistoryData>>(
      operationName: 'getNotificationsByType',
      operation: () async {
        final result = await (select(notificationHistory)
              ..where((n) => n.notificationType.equals(notificationType))
              ..orderBy([(n) => OrderingTerm.desc(n.createdAt)]))
            .get();
        logInfo(
          'getNotificationsByType() returned ${result.length} notifications',
        );
        return result;
      },
      onError: () => <NotificationHistoryData>[],
    );
  }

  Future<NotificationHistoryData?> getNotificationById(int id) async {
    return executeWithErrorHandling<NotificationHistoryData?>(
      operationName: 'getNotificationById',
      operation: () async {
        final result = await (select(notificationHistory)
              ..where((n) => n.id.equals(id)))
            .getSingleOrNull();
        logDebug(
          'getNotificationById(id=$id) returned ${result != null ? "notification" : "null"}',
        );
        return result;
      },
      onError: () => null,
    );
  }

  Future<int> insertNotification(
    NotificationHistoryCompanion notification,
  ) async {
    return executeWithErrorHandling<int>(
      operationName: 'insertNotification',
      operation: () async {
        final id = await into(notificationHistory).insert(notification);
        logInfo('insertNotification() inserted notification with id=$id');
        return id;
      },
    );
  }

  Future<bool> updateNotification(
    NotificationHistoryCompanion notification,
  ) async {
    final id = notification.id.value;
    return executeWithErrorHandling<bool>(
      operationName: 'updateNotification',
      operation: () async {
        final result = await update(notificationHistory).replace(notification);
        logInfo('updateNotification(id=$id) updated successfully');
        return result;
      },
    );
  }

  Future<bool> markAsTapped(int id) async {
    return executeWithErrorHandling<bool>(
      operationName: 'markAsTapped',
      operation: () async {
        final result = await (update(notificationHistory)
              ..where((n) => n.id.equals(id)))
            .write(
          NotificationHistoryCompanion(wasTapped: const Value(true)),
        );
        logInfo('markAsTapped(id=$id) updated successfully');
        return result > 0;
      },
      onError: () => false,
    );
  }

  Future<bool> markAsDismissed(int id) async {
    return executeWithErrorHandling<bool>(
      operationName: 'markAsDismissed',
      operation: () async {
        final result = await (update(notificationHistory)
              ..where((n) => n.id.equals(id)))
            .write(
          NotificationHistoryCompanion(wasDismissed: const Value(true)),
        );
        logInfo('markAsDismissed(id=$id) updated successfully');
        return result > 0;
      },
      onError: () => false,
    );
  }

  Future<int> deleteNotification(int id) async {
    return executeWithErrorHandling<int>(
      operationName: 'deleteNotification',
      operation: () async {
        final result = await (delete(notificationHistory)
              ..where((n) => n.id.equals(id)))
            .go();
        logInfo('deleteNotification(id=$id) deleted $result rows');
        return result;
      },
    );
  }

  Future<int> deleteOldNotifications(DateTime beforeDate) async {
    return executeWithErrorHandling<int>(
      operationName: 'deleteOldNotifications',
      operation: () async {
        final result = await (delete(notificationHistory)
              ..where((n) => n.createdAt.isSmallerThanValue(beforeDate)))
            .go();
        logInfo(
          'deleteOldNotifications() deleted $result notifications before $beforeDate',
        );
        return result;
      },
      onError: () => 0,
    );
  }

  Future<int> getUnreadCount() async {
    return executeWithErrorHandling<int>(
      operationName: 'getUnreadCount',
      operation: () async {
        final query = selectOnly(notificationHistory)
          ..addColumns([notificationHistory.id.count()])
          ..where(notificationHistory.wasTapped.equals(false));
        final result = await query.getSingle();
        final count = result.read(notificationHistory.id.count()) ?? 0;
        logDebug('getUnreadCount() returned $count');
        return count;
      },
      onError: () => 0,
    );
  }
}
