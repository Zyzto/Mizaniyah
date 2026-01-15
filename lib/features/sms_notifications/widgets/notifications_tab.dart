import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/database/providers/dao_providers.dart';
import '../../../core/database/app_database.dart' hide Card;
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/loading_skeleton.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/navigation/route_paths.dart';

/// Provider for notification history stream
final notificationHistoryProvider =
    StreamProvider<List<NotificationHistoryData>>((ref) async* {
      ref.keepAlive();
      final dao = ref.watch(notificationHistoryDaoProvider);
      try {
        await for (final notifications in dao.watchAllNotifications()) {
          yield notifications;
        }
      } catch (e) {
        // Error handling is done by the DAO
        yield [];
      }
    });

/// Notifications history tab
class NotificationsTab extends ConsumerStatefulWidget {
  const NotificationsTab({super.key});

  @override
  ConsumerState<NotificationsTab> createState() => _NotificationsTabState();
}

class _NotificationsTabState extends ConsumerState<NotificationsTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  String _selectedFilter = 'all'; // 'all', 'sms_confirmation', 'unread'
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    final notificationsAsync = ref.watch(notificationHistoryProvider);

    return Column(
      children: [
        // Filter bar
        _buildFilterBar(),
        // Notifications list
        Expanded(
          child: notificationsAsync.when(
            data: (notifications) {
              final filtered = _filterNotifications(notifications);

              if (filtered.isEmpty) {
                return EmptyState(
                  icon: Icons.notifications_none_outlined,
                  title: 'no_notifications'.tr(),
                  subtitle: _selectedFilter == 'unread'
                      ? 'no_unread_notifications'.tr()
                      : 'notification_history_empty'.tr(),
                );
              }

              return ListView.builder(
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final notification = filtered[index];
                  return _NotificationCard(
                    notification: notification,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      _handleNotificationTap(notification);
                    },
                    onDismiss: () {
                      HapticFeedback.mediumImpact();
                      _dismissNotification(notification);
                    },
                  );
                },
              );
            },
            loading: () => const SkeletonList(itemCount: 5, itemHeight: 100),
            error: (error, stack) => ErrorState(
              title: 'error_loading_notifications'.tr(),
              message: error.toString(),
              onRetry: () => ref.invalidate(notificationHistoryProvider),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: SegmentedButton<String>(
              segments: [
                ButtonSegment(value: 'all', label: Text('all'.tr())),
                ButtonSegment(
                  value: 'sms_confirmation',
                  label: Text('sms'.tr()),
                ),
                ButtonSegment(value: 'unread', label: Text('unread'.tr())),
              ],
              selected: {_selectedFilter},
              onSelectionChanged: (Set<String> newSelection) {
                setState(() {
                  _selectedFilter = newSelection.first;
                });
              },
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.filter_list),
            tooltip: 'filter_by_date'.tr(),
            onPressed: () {
              HapticFeedback.lightImpact();
              _showDateRangePicker();
            },
          ),
          if (_startDate != null || _endDate != null)
            IconButton(
              icon: const Icon(Icons.clear),
              tooltip: 'clear_filter'.tr(),
              onPressed: () {
                HapticFeedback.lightImpact();
                setState(() {
                  _startDate = null;
                  _endDate = null;
                });
              },
            ),
        ],
      ),
    );
  }

  List<NotificationHistoryData> _filterNotifications(
    List<NotificationHistoryData> notifications,
  ) {
    var filtered = notifications;

    // Filter by type
    if (_selectedFilter == 'sms_confirmation') {
      filtered = filtered
          .where((n) => n.notificationType == 'sms_confirmation')
          .toList();
    } else if (_selectedFilter == 'unread') {
      filtered = filtered.where((n) => !n.wasTapped).toList();
    }

    // Filter by date range
    if (_startDate != null || _endDate != null) {
      filtered = filtered.where((n) {
        final createdAt = n.createdAt;
        if (_startDate != null && createdAt.isBefore(_startDate!)) {
          return false;
        }
        if (_endDate != null && createdAt.isAfter(_endDate!)) {
          return false;
        }
        return true;
      }).toList();
    }

    return filtered;
  }

  void _showDateRangePicker() async {
    final now = DateTime.now();
    final firstDate = now.subtract(const Duration(days: 365));
    final lastDate = now;

    final picked = await showDateRangePicker(
      context: context,
      firstDate: firstDate,
      lastDate: lastDate,
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  void _handleNotificationTap(NotificationHistoryData notification) async {
    // Store navigation paths before async operation
    final shouldNavigateToAccounts =
        notification.notificationType == 'sms_confirmation' &&
        notification.confirmationId != null;
    final transactionId = notification.transactionId;

    // Mark as tapped
    final dao = ref.read(notificationHistoryDaoProvider);
    await dao.markAsTapped(notification.id);

    // Navigate based on notification type
    if (!mounted) return;

    if (shouldNavigateToAccounts) {
      // Navigate to accounts page (SMS notifications tab)
      context.go(RoutePaths.accounts);
    } else if (transactionId != null) {
      // Navigate to transaction detail
      context.push(RoutePaths.transactionDetail(transactionId));
    }
  }

  void _dismissNotification(NotificationHistoryData notification) async {
    final dao = ref.read(notificationHistoryDaoProvider);
    await dao.markAsDismissed(notification.id);
  }
}

class _NotificationCard extends StatelessWidget {
  final NotificationHistoryData notification;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const _NotificationCard({
    required this.notification,
    required this.onTap,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final dateFormat = DateFormat('MMM dd, yyyy HH:mm');
    final isUnread = !notification.wasTapped;

    return Dismissible(
      key: Key('notification_${notification.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: AlignmentDirectional.centerEnd,
        padding: const EdgeInsetsDirectional.only(end: 20),
        color: colorScheme.error,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => onDismiss(),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        color: isUnread
            ? colorScheme.primaryContainer.withValues(alpha: 0.3)
            : null,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isUnread
                        ? colorScheme.primary
                        : colorScheme.surfaceContainerHighest,
                  ),
                  child: Icon(
                    _getNotificationIcon(notification.notificationType),
                    color: isUnread
                        ? colorScheme.onPrimary
                        : colorScheme.onSurfaceVariant,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: isUnread
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                          if (isUnread)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: colorScheme.primary,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notification.body,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        dateFormat.format(notification.createdAt),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (notification.wasTapped)
                  Icon(
                    Icons.check_circle,
                    color: colorScheme.primary,
                    size: 20,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getNotificationIcon(String notificationType) {
    switch (notificationType) {
      case 'sms_confirmation':
        return Icons.sms;
      case 'transaction_created':
        return Icons.receipt;
      default:
        return Icons.notifications;
    }
  }
}
