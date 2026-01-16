import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:another_telephony/telephony.dart';
import 'package:easy_localization/easy_localization.dart';
import '../providers/sms_providers.dart';
import '../../../core/services/sms_parsing_service.dart';
import '../../../core/database/providers/dao_providers.dart';
import '../../../core/database/app_database.dart' hide Card;
import '../../../core/navigation/route_paths.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/loading_skeleton.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/debouncer.dart';

/// Unified item type for SMS and notifications
enum UnifiedItemType { sms, notification }

/// Unified item representing either SMS or notification
class UnifiedItem {
  final UnifiedItemType type;
  final SmsWithStatus? smsWithStatus;
  final NotificationHistoryData? notification;
  final DateTime sortDate; // For chronological sorting

  UnifiedItem({
    required this.type,
    this.smsWithStatus,
    this.notification,
    required this.sortDate,
  });
}

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

/// Unified SMS and Notifications tab
/// Combines AllSmsTab and NotificationsTab functionality
class SmsAndNotificationsTab extends ConsumerStatefulWidget {
  const SmsAndNotificationsTab({super.key});

  @override
  ConsumerState<SmsAndNotificationsTab> createState() =>
      _SmsAndNotificationsTabState();
}

class _SmsAndNotificationsTabState extends ConsumerState<SmsAndNotificationsTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  // Search state
  String _searchQuery = '';
  String _debouncedSearchQuery = '';
  bool _isSearchExpanded = false;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  late final Debouncer _searchDebouncer;

  // SMS filters
  bool _showMatchedOnly = false;
  bool _showUnmatchedOnly = false;

  // Notification filters
  String _selectedFilter = 'all'; // 'all', 'sms_confirmation', 'unread'
  DateTime? _startDate;
  DateTime? _endDate;

  // View toggle: 'all', 'sms', or 'notifications'
  String _viewMode = 'all'; // 'all', 'sms', or 'notifications'

  // Scroll and pagination
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _searchDebouncer = Debouncer(delay: const Duration(milliseconds: 500));
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _searchDebouncer.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      ref.read(smsListProvider.notifier).loadMore();
    }
  }

  List<UnifiedItem> _getUnifiedItems(
    List<SmsWithStatus> smsList,
    List<NotificationHistoryData> notifications,
  ) {
    final items = <UnifiedItem>[];

    // Add SMS items
    for (final smsWithStatus in smsList) {
      final date = smsWithStatus.sms.date != null
          ? DateTime.fromMillisecondsSinceEpoch(smsWithStatus.sms.date!)
          : DateTime.now();
      items.add(
        UnifiedItem(
          type: UnifiedItemType.sms,
          smsWithStatus: smsWithStatus,
          sortDate: date,
        ),
      );
    }

    // Add notification items
    for (final notification in notifications) {
      items.add(
        UnifiedItem(
          type: UnifiedItemType.notification,
          notification: notification,
          sortDate: notification.createdAt,
        ),
      );
    }

    // Sort by date descending (newest first)
    items.sort((a, b) => b.sortDate.compareTo(a.sortDate));

    return items;
  }

  List<UnifiedItem> _getFilteredItems(
    List<SmsWithStatus> smsList,
    List<NotificationHistoryData> notifications,
  ) {
    // Filter SMS
    var filteredSms = smsList;

    // Filter by match status
    if (_showMatchedOnly) {
      filteredSms = filteredSms.where((item) => item.isMatched).toList();
    } else if (_showUnmatchedOnly) {
      filteredSms = filteredSms
          .where((item) => !item.isMatched && !item.isParsing)
          .toList();
    }

    // Filter by search query (use debounced query)
    if (_debouncedSearchQuery.isNotEmpty) {
      final query = _debouncedSearchQuery.toLowerCase();
      filteredSms = filteredSms.where((item) {
        final address = item.sms.address?.toLowerCase() ?? '';
        final body = item.sms.body?.toLowerCase() ?? '';
        return address.contains(query) || body.contains(query);
      }).toList();
    }

    // Filter SMS by date range (if in all mode and date range is set)
    if ((_viewMode == 'all' || _viewMode == 'sms') &&
        (_startDate != null || _endDate != null)) {
      filteredSms = filteredSms.where((item) {
        final smsDate = item.sms.date != null
            ? DateTime.fromMillisecondsSinceEpoch(item.sms.date!)
            : DateTime.now();
        if (_startDate != null && smsDate.isBefore(_startDate!)) {
          return false;
        }
        if (_endDate != null && smsDate.isAfter(_endDate!)) {
          return false;
        }
        return true;
      }).toList();
    }

    // Filter notifications
    var filteredNotifications = notifications;

    // Filter by type
    if (_selectedFilter == 'sms_confirmation') {
      filteredNotifications = filteredNotifications
          .where((n) => n.notificationType == 'sms_confirmation')
          .toList();
    } else if (_selectedFilter == 'unread') {
      filteredNotifications = filteredNotifications
          .where((n) => !n.wasTapped)
          .toList();
    }

    // Filter by date range
    if (_startDate != null || _endDate != null) {
      filteredNotifications = filteredNotifications.where((n) {
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

    // Return items based on view mode
    if (_viewMode == 'sms') {
      return _getUnifiedItems(filteredSms, []);
    } else if (_viewMode == 'notifications') {
      return _getUnifiedItems([], filteredNotifications);
    } else {
      // 'all' mode - show both
      return _getUnifiedItems(filteredSms, filteredNotifications);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

    final smsAsync = ref.watch(smsListProvider);
    final notificationsAsync = ref.watch(notificationHistoryProvider);
    final isIOS = !kIsWeb && Platform.isIOS;

    // Auto-expand search if there's a query
    if (_searchQuery.isNotEmpty && !_isSearchExpanded) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _isSearchExpanded = true;
          });
        }
      });
    }

    // Debounce search query
    if (_searchQuery != _debouncedSearchQuery) {
      _searchDebouncer.call(() {
        if (mounted) {
          setState(() {
            _debouncedSearchQuery = _searchQuery;
          });
        }
      });
    }

    // Get loading states
    final smsNotifier = ref.read(smsListProvider.notifier);
    final isLoading = smsNotifier.isLoading;
    final isLoadingMore = smsNotifier.isLoadingMore;
    final isParsing = smsNotifier.isParsing;

    return smsAsync.when(
      data: (smsList) {
        return notificationsAsync.when(
          data: (notifications) {
            final filteredItems = _getFilteredItems(smsList, notifications);
            final matchedCount = smsList.where((item) => item.isMatched).length;
            final unmatchedCount = smsList.length - matchedCount;
            final parsingCount = smsList.where((item) => item.isParsing).length;
            // Check if there are actually items being parsed (more accurate than just the flag)
            final hasParsingItems = parsingCount > 0;

            return Column(
              children: [
                // View mode toggle
                _buildViewModeToggle(context, isIOS),
                // Compact filter bar with active filters and stats
                _buildCompactFilterBar(
                  context,
                  isIOS,
                  smsList.length,
                  matchedCount,
                  unmatchedCount,
                  parsingCount,
                  notifications.length,
                  isLoading: isLoading || isParsing,
                ),
                // Unified list
                Expanded(
                  child: filteredItems.isEmpty && !isLoading
                      ? _buildEmptyState(context)
                      : RefreshIndicator(
                          onRefresh: () async {
                            await ref.read(smsListProvider.notifier).refresh();
                            ref.invalidate(notificationHistoryProvider);
                          },
                          child: Stack(
                            children: [
                              ListView.separated(
                                controller: _scrollController,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                itemCount:
                                    filteredItems.length +
                                    (isLoadingMore ? 1 : 0),
                                separatorBuilder: (context, index) =>
                                    const SizedBox(height: 8),
                                itemBuilder: (context, index) {
                                  // Show loading indicator at the end when loading more
                                  if (index == filteredItems.length &&
                                      isLoadingMore) {
                                    return const Padding(
                                      padding: EdgeInsets.all(16),
                                      child: Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                    );
                                  }

                                  final item = filteredItems[index];
                                  return _UnifiedListItem(
                                    item: item,
                                    onSmsTap: () {
                                      HapticFeedback.lightImpact();
                                      _showSmsDetails(item.smsWithStatus!);
                                    },
                                    onCreateTemplate: () {
                                      HapticFeedback.lightImpact();
                                      _createTemplateFromSms(
                                        item.smsWithStatus!.sms,
                                      );
                                    },
                                    onNotificationTap: () {
                                      HapticFeedback.lightImpact();
                                      _handleNotificationTap(
                                        item.notification!,
                                      );
                                    },
                                    onDismissNotification: () {
                                      HapticFeedback.mediumImpact();
                                      _dismissNotification(item.notification!);
                                    },
                                  );
                                },
                              ),
                              // Show parsing indicator overlay only if there are items actually being parsed
                              if (hasParsingItems && !isLoading)
                                PositionedDirectional(
                                  bottom: 16,
                                  end: 16,
                                  child: _buildParsingIndicator(context),
                                ),
                            ],
                          ),
                        ),
                ),
              ],
            );
          },
          loading: () => _buildLoadingState(context),
          error: (error, stack) => ErrorState(
            title: 'error_loading_notifications'.tr(),
            message: error.toString(),
            onRetry: () => ref.invalidate(notificationHistoryProvider),
          ),
        );
      },
      loading: () => _buildLoadingState(context),
      error: (error, stack) => ErrorState(
        title: 'error_loading_sms'.tr(),
        message: error.toString(),
        onRetry: () => ref.read(smsListProvider.notifier).refresh(),
      ),
    );
  }

  Widget _buildViewModeToggle(BuildContext context, bool isIOS) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final useCompactLabels =
        screenWidth < 400; // Use shorter labels on small screens

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: colorScheme.outline.withValues(alpha: 0.1)),
        ),
      ),
      child: SegmentedButton<String>(
        style: SegmentedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          minimumSize: const Size(0, 36),
        ),
        segments: [
          ButtonSegment(
            value: 'all',
            icon: const Icon(Icons.view_list_outlined, size: 18),
            label: Text(
              'all'.tr(),
              style: const TextStyle(fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
            tooltip: 'view_all_items'.tr(),
          ),
          if (!isIOS)
            ButtonSegment(
              value: 'sms',
              icon: const Icon(Icons.sms_outlined, size: 18),
              label: Text(
                useCompactLabels ? 'SMS' : 'all_sms'.tr(),
                style: const TextStyle(fontSize: 12),
                overflow: TextOverflow.ellipsis,
              ),
              tooltip: 'view_sms_only'.tr(),
            ),
          ButtonSegment(
            value: 'notifications',
            icon: const Icon(Icons.notifications_outlined, size: 18),
            label: Text(
              useCompactLabels ? 'Notif' : 'notifications'.tr(),
              style: const TextStyle(fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
            tooltip: 'view_notifications_only'.tr(),
          ),
        ],
        selected: {_viewMode},
        onSelectionChanged: (Set<String> newSelection) {
          HapticFeedback.lightImpact();
          setState(() {
            _viewMode = newSelection.first;
            // Clear filters that don't apply to the new view mode
            if (newSelection.first == 'notifications' && !isIOS) {
              _showMatchedOnly = false;
              _showUnmatchedOnly = false;
              _searchQuery = '';
              _debouncedSearchQuery = '';
              _searchController.clear();
            } else if (newSelection.first == 'sms') {
              _selectedFilter = 'all';
              _startDate = null;
              _endDate = null;
            }
          });
        },
      ),
    );
  }

  Widget _buildParsingIndicator(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'parsing_sms'.tr(),
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactFilterBar(
    BuildContext context,
    bool isIOS,
    int totalSms,
    int matchedCount,
    int unmatchedCount,
    int parsingCount,
    int notificationCount, {
    bool isLoading = false,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: colorScheme.outline.withValues(alpha: 0.1)),
        ),
      ),
      child: _isSearchExpanded
          ? TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              decoration: InputDecoration(
                hintText: _viewMode == 'notifications'
                    ? 'search_notifications_hint'.tr()
                    : 'search_sms_hint'.tr(),
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 20),
                        tooltip: 'clear_search'.tr(),
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          setState(() {
                            _searchQuery = '';
                            _debouncedSearchQuery = '';
                            _searchController.clear();
                          });
                          _searchDebouncer.cancel();
                        },
                      )
                    : IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        tooltip: 'close'.tr(),
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          setState(() {
                            _isSearchExpanded = false;
                            _searchQuery = '';
                            _debouncedSearchQuery = '';
                            _searchController.clear();
                          });
                          _searchFocusNode.unfocus();
                          _searchDebouncer.cancel();
                        },
                      ),
                filled: true,
                fillColor: colorScheme.surfaceContainerHighest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                isDense: true,
              ),
              textInputAction: TextInputAction.search,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              onSubmitted: (_) {
                _searchFocusNode.unfocus();
              },
            )
          : Row(
              children: [
                // Fixed buttons on start (left in LTR): Search and Date
                IconButton(
                  icon: const Icon(Icons.search, size: 20),
                  tooltip: _viewMode == 'notifications'
                      ? 'search_notifications_hint'.tr()
                      : 'search_sms_hint'.tr(),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    setState(() {
                      _isSearchExpanded = true;
                    });
                    Future.delayed(
                      const Duration(milliseconds: 100),
                      () => _searchFocusNode.requestFocus(),
                    );
                  },
                  style: IconButton.styleFrom(
                    backgroundColor: colorScheme.surfaceContainerHighest,
                    minimumSize: const Size(36, 36),
                    padding: EdgeInsets.zero,
                  ),
                ),
                const SizedBox(width: 8),
                // Date range button (if in notifications or all view)
                if (_viewMode == 'notifications' || _viewMode == 'all')
                  IconButton(
                    icon: Stack(
                      children: [
                        Icon(
                          Icons.date_range,
                          size: 20,
                          color: (_startDate != null || _endDate != null)
                              ? colorScheme.primary
                              : colorScheme.onSurface,
                        ),
                        if (_startDate != null || _endDate != null)
                          PositionedDirectional(
                            end: 0,
                            top: 0,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: colorScheme.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    ),
                    tooltip: 'filter_by_date'.tr(),
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      _showDateRangePicker();
                    },
                    style: IconButton.styleFrom(
                      backgroundColor: colorScheme.surfaceContainerHighest,
                      minimumSize: const Size(36, 36),
                      padding: EdgeInsets.zero,
                    ),
                  ),
                const SizedBox(width: 8),
                // Filter chips (scrollable) - shows both active and available filters
                Expanded(
                  child: SizedBox(
                    height: 32,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: _buildFilterChips(context, isIOS),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  bool _hasActiveFilters() {
    if (_viewMode == 'sms' || _viewMode == 'all') {
      if (_showMatchedOnly ||
          _showUnmatchedOnly ||
          _debouncedSearchQuery.isNotEmpty) {
        return true;
      }
    }
    if (_viewMode == 'notifications' || _viewMode == 'all') {
      if (_selectedFilter != 'all' || _startDate != null || _endDate != null) {
        return true;
      }
    }
    return false;
  }

  List<Widget> _buildFilterChips(BuildContext context, bool isIOS) {
    final chips = <Widget>[];
    final colorScheme = Theme.of(context).colorScheme;

    // SMS filters - show as toggleable chips
    if ((_viewMode == 'sms' || _viewMode == 'all') && !isIOS) {
      // Matched only filter
      chips.add(
        Padding(
          padding: const EdgeInsetsDirectional.only(end: 6),
          child: _showMatchedOnly
              ? InputChip(
                  label: Text('matched_only'.tr()),
                  avatar: Icon(
                    Icons.check_circle,
                    size: 16,
                    color: colorScheme.primary,
                  ),
                  onDeleted: () {
                    HapticFeedback.lightImpact();
                    setState(() => _showMatchedOnly = false);
                  },
                  deleteIcon: const Icon(Icons.close, size: 16),
                  backgroundColor: colorScheme.primaryContainer,
                  deleteIconColor: colorScheme.onPrimaryContainer,
                  labelStyle: TextStyle(
                    color: colorScheme.onPrimaryContainer,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                )
              : FilterChip(
                  label: Text('matched_only'.tr()),
                  avatar: Icon(
                    Icons.check_circle_outline,
                    size: 16,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  selected: false,
                  onSelected: (selected) {
                    HapticFeedback.lightImpact();
                    setState(() {
                      _showMatchedOnly = true;
                      _showUnmatchedOnly = false;
                    });
                  },
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
        ),
      );

      // Unmatched only filter
      chips.add(
        Padding(
          padding: const EdgeInsetsDirectional.only(end: 6),
          child: _showUnmatchedOnly
              ? InputChip(
                  label: Text('unmatched_only'.tr()),
                  avatar: Icon(
                    Icons.cancel,
                    size: 16,
                    color: colorScheme.error,
                  ),
                  onDeleted: () {
                    HapticFeedback.lightImpact();
                    setState(() => _showUnmatchedOnly = false);
                  },
                  deleteIcon: const Icon(Icons.close, size: 16),
                  backgroundColor: colorScheme.errorContainer,
                  deleteIconColor: colorScheme.onErrorContainer,
                  labelStyle: TextStyle(
                    color: colorScheme.onErrorContainer,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                )
              : FilterChip(
                  label: Text('unmatched_only'.tr()),
                  avatar: Icon(
                    Icons.cancel_outlined,
                    size: 16,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  selected: false,
                  onSelected: (selected) {
                    HapticFeedback.lightImpact();
                    setState(() {
                      _showUnmatchedOnly = true;
                      _showMatchedOnly = false;
                    });
                  },
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
        ),
      );
    }

    // Search query chip (only when active, applies to all modes)
    if (_debouncedSearchQuery.isNotEmpty) {
      chips.add(
        Padding(
          padding: const EdgeInsetsDirectional.only(end: 6),
          child: InputChip(
            label: Text(
              _debouncedSearchQuery.length > 20
                  ? '${_debouncedSearchQuery.substring(0, 20)}...'
                  : _debouncedSearchQuery,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            avatar: const Icon(Icons.search, size: 16),
            onDeleted: () {
              HapticFeedback.lightImpact();
              setState(() {
                _searchQuery = '';
                _debouncedSearchQuery = '';
                _searchController.clear();
              });
              _searchDebouncer.cancel();
            },
            deleteIcon: const Icon(Icons.close, size: 16),
            backgroundColor: colorScheme.surfaceContainerHighest,
            deleteIconColor: colorScheme.onSurfaceVariant,
            labelStyle: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
      );
    }

    // Notification filters - show as toggleable chips
    if (_viewMode == 'notifications' || _viewMode == 'all') {
      // Unread filter
      chips.add(
        Padding(
          padding: const EdgeInsetsDirectional.only(end: 6),
          child: _selectedFilter == 'unread'
              ? InputChip(
                  label: Text('unread'.tr()),
                  avatar: Icon(
                    Icons.mark_email_unread,
                    size: 16,
                    color: colorScheme.tertiary,
                  ),
                  onDeleted: () {
                    HapticFeedback.lightImpact();
                    setState(() => _selectedFilter = 'all');
                  },
                  deleteIcon: const Icon(Icons.close, size: 16),
                  backgroundColor: colorScheme.tertiaryContainer,
                  deleteIconColor: colorScheme.onTertiaryContainer,
                  labelStyle: TextStyle(
                    color: colorScheme.onTertiaryContainer,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                )
              : FilterChip(
                  label: Text('unread'.tr()),
                  avatar: Icon(
                    Icons.mark_email_unread_outlined,
                    size: 16,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  selected: false,
                  onSelected: (selected) {
                    HapticFeedback.lightImpact();
                    setState(() => _selectedFilter = 'unread');
                  },
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
        ),
      );
    }

    // Date range filter (applies to both SMS and notifications in all mode)
    if (_startDate != null || _endDate != null) {
      final dateRange = _startDate != null && _endDate != null
          ? '${DateFormat('MMM dd').format(_startDate!)} - ${DateFormat('MMM dd').format(_endDate!)}'
          : _startDate != null
          ? 'from_date'.tr(args: [DateFormat('MMM dd').format(_startDate!)])
          : 'until_date'.tr(args: [DateFormat('MMM dd').format(_endDate!)]);
      chips.add(
        Padding(
          padding: const EdgeInsetsDirectional.only(end: 6),
          child: InputChip(
            label: Text(dateRange),
            avatar: const Icon(Icons.date_range, size: 16),
            onDeleted: () {
              HapticFeedback.lightImpact();
              setState(() {
                _startDate = null;
                _endDate = null;
              });
            },
            deleteIcon: const Icon(Icons.close, size: 16),
            backgroundColor: colorScheme.secondaryContainer,
            deleteIconColor: colorScheme.onSecondaryContainer,
            labelStyle: TextStyle(
              color: colorScheme.onSecondaryContainer,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
      );
    }

    return chips;
  }

  Widget _buildLoadingState(BuildContext context) {
    return Column(
      children: [
        // Filter bar skeleton
        Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 100,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  Container(
                    width: 80,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  Container(
                    width: 80,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        // List skeleton
        const Expanded(child: SkeletonList(itemCount: 5, itemHeight: 140)),
      ],
    );
  }

  String _getEmptyStateTitle() {
    final hasFilters = _hasActiveFilters();

    if (_viewMode == 'sms') {
      if (_debouncedSearchQuery.isNotEmpty) {
        return 'no_sms_matching'.tr(args: [_debouncedSearchQuery]);
      }
      if (_showMatchedOnly) {
        return 'no_matched_sms'.tr();
      }
      if (_showUnmatchedOnly) {
        return 'no_unmatched_sms'.tr();
      }
      return 'no_sms_messages'.tr();
    } else if (_viewMode == 'notifications') {
      if (_selectedFilter == 'unread') {
        return 'no_unread_notifications'.tr();
      }
      if (hasFilters) {
        return 'no_notifications_matching_filters'.tr();
      }
      return 'no_notifications'.tr();
    } else {
      // 'all' mode
      if (hasFilters) {
        return 'no_items_found'.tr();
      }
      return 'no_sms_or_notifications'.tr();
    }
  }

  String? _getEmptyStateSubtitle() {
    final hasFilters = _hasActiveFilters();

    if (_viewMode == 'sms') {
      if (hasFilters) {
        return 'try_adjusting_filters'.tr();
      }
      return 'no_sms_messages_description'.tr();
    } else if (_viewMode == 'notifications') {
      if (hasFilters) {
        return 'try_adjusting_filters'.tr();
      }
      return 'notification_history_empty'.tr();
    } else {
      // 'all' mode
      if (hasFilters) {
        return 'try_adjusting_filters'.tr();
      }
      return 'no_sms_or_notifications_description'.tr();
    }
  }

  Widget _buildEmptyState(BuildContext context) {
    final hasFilters = _hasActiveFilters();

    return EmptyState(
      icon: _viewMode == 'sms'
          ? Icons.sms_outlined
          : _viewMode == 'notifications'
          ? Icons.notifications_none_outlined
          : Icons.inbox_outlined,
      title: _getEmptyStateTitle(),
      subtitle: _getEmptyStateSubtitle(),
      actionLabel: hasFilters ? 'clear_all_filters'.tr() : null,
      onAction: hasFilters
          ? () {
              HapticFeedback.lightImpact();
              setState(() {
                _showMatchedOnly = false;
                _showUnmatchedOnly = false;
                _selectedFilter = 'all';
                _startDate = null;
                _endDate = null;
                _searchQuery = '';
                _debouncedSearchQuery = '';
                _searchController.clear();
                _searchDebouncer.cancel();
              });
            }
          : null,
    );
  }

  void _showSmsDetails(SmsWithStatus smsWithStatus) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => _SmsDetailsSheet(smsWithStatus: smsWithStatus),
    );
  }

  void _createTemplateFromSms(SmsMessage sms) {
    final queryParams = <String, String>{};
    if (sms.body != null && sms.body!.isNotEmpty) {
      queryParams['initialSms'] = Uri.encodeComponent(sms.body!);
    }
    if (sms.address != null && sms.address!.isNotEmpty) {
      queryParams['initialSender'] = Uri.encodeComponent(sms.address!);
    }
    final queryString = queryParams.entries
        .map((e) => '${e.key}=${e.value}')
        .join('&');
    context.push(
      '${RoutePaths.smsTemplateForm}${queryString.isNotEmpty ? '?$queryString' : ''}',
    );
  }

  void _showDateRangePicker() async {
    final now = DateTime.now();
    final firstDate = now.subtract(
      const Duration(days: 365 * 2),
    ); // Allow 2 years back
    final lastDate = now.add(const Duration(days: 1)); // Allow today

    final picked = await showDateRangePicker(
      context: context,
      firstDate: firstDate,
      lastDate: lastDate,
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
      helpText: 'select_date_range'.tr(),
      cancelText: 'cancel'.tr(),
      confirmText: 'confirm'.tr(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(
            context,
          ).copyWith(colorScheme: Theme.of(context).colorScheme),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        // Normalize dates to start and end of day
        _startDate = DateTime(
          picked.start.year,
          picked.start.month,
          picked.start.day,
        );
        _endDate = DateTime(
          picked.end.year,
          picked.end.month,
          picked.end.day,
          23,
          59,
          59,
        );
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

/// Unified list item widget that renders SMS or Notification
class _UnifiedListItem extends StatelessWidget {
  final UnifiedItem item;
  final VoidCallback? onSmsTap;
  final VoidCallback? onCreateTemplate;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onDismissNotification;

  const _UnifiedListItem({
    required this.item,
    this.onSmsTap,
    this.onCreateTemplate,
    this.onNotificationTap,
    this.onDismissNotification,
  });

  @override
  Widget build(BuildContext context) {
    if (item.type == UnifiedItemType.sms && item.smsWithStatus != null) {
      return _SmsListItemWithStatus(
        smsWithStatus: item.smsWithStatus!,
        onTap: onSmsTap ?? () {},
        onCreateTemplate: onCreateTemplate ?? () {},
      );
    } else if (item.type == UnifiedItemType.notification &&
        item.notification != null) {
      return _NotificationCard(
        notification: item.notification!,
        onTap: onNotificationTap ?? () {},
        onDismiss: onDismissNotification ?? () {},
      );
    }
    return const SizedBox.shrink();
  }
}

/// SMS list item widget (reused from AllSmsTab)
class _SmsListItemWithStatus extends StatelessWidget {
  final SmsWithStatus smsWithStatus;
  final VoidCallback onTap;
  final VoidCallback onCreateTemplate;

  const _SmsListItemWithStatus({
    required this.smsWithStatus,
    required this.onTap,
    required this.onCreateTemplate,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final dateFormat = DateFormat('MMM dd, yyyy HH:mm');
    final date = smsWithStatus.sms.date != null
        ? DateTime.fromMillisecondsSinceEpoch(smsWithStatus.sms.date!)
        : DateTime.now();
    final bodyPreview =
        smsWithStatus.sms.body != null && smsWithStatus.sms.body!.length > 100
        ? '${smsWithStatus.sms.body!.substring(0, 100)}...'
        : smsWithStatus.sms.body ?? '';

    final matchResult = smsWithStatus.matchResult;
    final parsedData = matchResult != null
        ? matchResult['parsed_data'] as ParsedSmsData?
        : null;
    final confidence = matchResult != null
        ? (matchResult['confidence'] as double?) ?? 0.0
        : null;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: smsWithStatus.isMatched
              ? colorScheme.primary.withValues(alpha: 0.2)
              : colorScheme.outline.withValues(alpha: 0.1),
          width: smsWithStatus.isMatched ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status icon
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: smsWithStatus.isMatched
                          ? colorScheme.primaryContainer
                          : smsWithStatus.isParsing
                          ? colorScheme.secondaryContainer
                          : colorScheme.surfaceContainerHighest,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      smsWithStatus.isParsing
                          ? Icons.hourglass_empty
                          : smsWithStatus.isMatched
                          ? Icons.check_circle
                          : Icons.sms_outlined,
                      size: 22,
                      color: smsWithStatus.isMatched
                          ? colorScheme.onPrimaryContainer
                          : smsWithStatus.isParsing
                          ? colorScheme.onSecondaryContainer
                          : colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Sender and date
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          smsWithStatus.sms.address ?? 'unknown'.tr(),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          dateFormat.format(date),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Confidence badge
                  if (smsWithStatus.isMatched && confidence != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _getConfidenceColor(confidence, colorScheme),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${(confidence * 100).toStringAsFixed(0)}%',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              // Message preview
              Text(
                bodyPreview,
                style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              // Parsed data section
              if (parsedData != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (parsedData.storeName != null)
                        _buildParsedRow(
                          context,
                          Icons.store_outlined,
                          'store'.tr(),
                          parsedData.storeName!,
                        ),
                      if (parsedData.amount != null) ...[
                        if (parsedData.storeName != null)
                          const SizedBox(height: 8),
                        _buildParsedRow(
                          context,
                          Icons.attach_money,
                          'amount'.tr(),
                          CurrencyFormatter.format(
                            parsedData.amount!,
                            parsedData.currency ?? 'USD',
                          ),
                        ),
                      ],
                      if (parsedData.cardLast4Digits != null) ...[
                        if (parsedData.amount != null)
                          const SizedBox(height: 8),
                        _buildParsedRow(
                          context,
                          Icons.credit_card_outlined,
                          'card'.tr(),
                          '****${parsedData.cardLast4Digits}',
                        ),
                      ],
                    ],
                  ),
                ),
              ],
              // Action button
              if (!smsWithStatus.isMatched && !smsWithStatus.isParsing) ...[
                const SizedBox(height: 12),
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: FilledButton.tonalIcon(
                    onPressed: onCreateTemplate,
                    icon: const Icon(Icons.add_circle_outline, size: 18),
                    label: Text('create_template'.tr()),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildParsedRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Color _getConfidenceColor(double confidence, ColorScheme colorScheme) {
    if (confidence >= 0.7) {
      return colorScheme.primary;
    } else if (confidence >= 0.5) {
      return colorScheme.secondary;
    } else {
      return colorScheme.error;
    }
  }
}

/// Notification card widget (reused from NotificationsTab)
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
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        elevation: 0,
        color: isUnread
            ? colorScheme.primaryContainer.withValues(alpha: 0.2)
            : null,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isUnread
                ? colorScheme.primary.withValues(alpha: 0.2)
                : colorScheme.outline.withValues(alpha: 0.1),
            width: isUnread ? 1.5 : 1,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
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
                    size: 22,
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
                              width: 10,
                              height: 10,
                              margin: const EdgeInsetsDirectional.only(
                                start: 4,
                              ),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: colorScheme.primary,
                                border: Border.all(
                                  color: colorScheme.surface,
                                  width: 2,
                                ),
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
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check_circle,
                      color: colorScheme.onPrimaryContainer,
                      size: 18,
                    ),
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

/// SMS details sheet (reused from AllSmsTab)
class _SmsDetailsSheet extends StatelessWidget {
  final SmsWithStatus smsWithStatus;

  const _SmsDetailsSheet({required this.smsWithStatus});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('MMM dd, yyyy HH:mm');
    final date = smsWithStatus.sms.date != null
        ? DateTime.fromMillisecondsSinceEpoch(smsWithStatus.sms.date!)
        : DateTime.now();

    final matchResult = smsWithStatus.matchResult;
    final parsedData = matchResult != null
        ? matchResult['parsed_data'] as ParsedSmsData?
        : null;
    final confidence = matchResult != null
        ? (matchResult['confidence'] as double?) ?? 0.0
        : null;

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                border: Border(
                  bottom: BorderSide(
                    color: theme.colorScheme.outline.withValues(alpha: 0.2),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Text(
                    'sms_details'.tr(),
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: 'close'.tr(),
                  ),
                ],
              ),
            ),
            // Content
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailRow(
                      context,
                      'sender'.tr(),
                      smsWithStatus.sms.address ?? 'unknown'.tr(),
                    ),
                    _buildDetailRow(
                      context,
                      'date'.tr(),
                      dateFormat.format(date),
                    ),
                    const SizedBox(height: 8),
                    const Divider(),
                    const SizedBox(height: 16),
                    Text(
                      'message'.tr(),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: SelectableText(
                        smsWithStatus.sms.body ?? '',
                        style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
                      ),
                    ),
                    if (parsedData != null) ...[
                      const SizedBox(height: 24),
                      Text(
                        'parsed_data'.tr(),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (parsedData.storeName != null)
                              _buildParsedDetailRow(
                                context,
                                'store'.tr(),
                                parsedData.storeName!,
                              ),
                            if (parsedData.amount != null) ...[
                              if (parsedData.storeName != null)
                                const SizedBox(height: 12),
                              _buildParsedDetailRow(
                                context,
                                'amount'.tr(),
                                CurrencyFormatter.format(
                                  parsedData.amount!,
                                  parsedData.currency ?? 'USD',
                                ),
                              ),
                            ],
                            if (parsedData.cardLast4Digits != null) ...[
                              if (parsedData.amount != null)
                                const SizedBox(height: 12),
                              _buildParsedDetailRow(
                                context,
                                'card'.tr(),
                                '****${parsedData.cardLast4Digits}',
                              ),
                            ],
                            if (confidence != null) ...[
                              if (parsedData.cardLast4Digits != null)
                                const SizedBox(height: 12),
                              _buildParsedDetailRow(
                                context,
                                'confidence'.tr(),
                                '${(confidence * 100).toStringAsFixed(1)}%',
                              ),
                            ],
                          ],
                        ),
                      ),
                    ] else ...[
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.errorContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.warning_amber_rounded,
                              color: theme.colorScheme.onErrorContainer,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'no_template_match'.tr(),
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onErrorContainer,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }

  Widget _buildParsedDetailRow(
    BuildContext context,
    String label,
    String value,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }
}
