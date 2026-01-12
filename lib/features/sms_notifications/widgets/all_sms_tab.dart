import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:another_telephony/telephony.dart';
import 'package:easy_localization/easy_localization.dart';
import '../providers/sms_providers.dart';
import '../../../core/services/sms_parsing_service.dart';
import '../../../core/navigation/route_paths.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/loading_skeleton.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/debouncer.dart';

/// All SMS tab - integrated SMS reader with parsing status
/// Uses reactive providers for smooth loading and background parsing
class AllSmsTab extends ConsumerStatefulWidget {
  const AllSmsTab({super.key});

  @override
  ConsumerState<AllSmsTab> createState() => _AllSmsTabState();
}

class _AllSmsTabState extends ConsumerState<AllSmsTab>
    with AutomaticKeepAliveClientMixin {
  String _searchQuery = '';
  String _debouncedSearchQuery = '';
  bool _showMatchedOnly = false;
  bool _showUnmatchedOnly = false;
  bool _isSearchExpanded = false;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  late final Debouncer _searchDebouncer;

  @override
  bool get wantKeepAlive => true;

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

  List<SmsWithStatus> _getFilteredSms(List<SmsWithStatus> smsList) {
    var filtered = smsList;

    // Filter by match status
    if (_showMatchedOnly) {
      filtered = filtered.where((item) => item.isMatched).toList();
    } else if (_showUnmatchedOnly) {
      filtered = filtered.where((item) => !item.isMatched && !item.isParsing).toList();
    }

    // Filter by search query (use debounced query)
    if (_debouncedSearchQuery.isNotEmpty) {
      final query = _debouncedSearchQuery.toLowerCase();
      filtered = filtered.where((item) {
        final address = item.sms.address?.toLowerCase() ?? '';
        final body = item.sms.body?.toLowerCase() ?? '';
        return address.contains(query) || body.contains(query);
      }).toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    final smsAsync = ref.watch(smsListProvider);

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

    return smsAsync.when(
      data: (smsList) {
        final filteredSms = _getFilteredSms(smsList);
        final matchedCount = smsList.where((item) => item.isMatched).length;
        final unmatchedCount = smsList.length - matchedCount;
        final parsingCount = smsList.where((item) => item.isParsing).length;

        return Column(
          children: [
            // Search and filter bar
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                border: Border(
                  bottom: BorderSide(
                    color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
                  ),
                ),
              ),
              child: Column(
                children: [
                  // Search row
                  Row(
                    children: [
                      // Search field - expandable button
                      _isSearchExpanded
                          ? Expanded(
                              child: TextField(
                                controller: _searchController,
                                focusNode: _searchFocusNode,
                                decoration: InputDecoration(
                                  hintText: 'search_sms_hint'.tr(),
                                  prefixIcon: const Icon(Icons.search),
                                  suffixIcon: _searchQuery.isNotEmpty
                                      ? IconButton(
                                          icon: const Icon(Icons.clear),
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
                                          icon: const Icon(Icons.close),
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
                                  fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
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
                              ),
                            )
                          : IconButton(
                              icon: const Icon(Icons.search),
                              tooltip: 'search_sms_hint'.tr(),
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
                                backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                      if (!_isSearchExpanded) ...[
                        const SizedBox(width: 6),
                        Flexible(
                          fit: FlexFit.loose,
                          child: FilterChip(
                            label: Text('matched_only'.tr()),
                            selected: _showMatchedOnly,
                            onSelected: (value) {
                              HapticFeedback.lightImpact();
                              setState(() {
                                _showMatchedOnly = value;
                                if (value) _showUnmatchedOnly = false;
                              });
                            },
                            selectedColor: Theme.of(context).colorScheme.primaryContainer,
                            checkmarkColor: Theme.of(context).colorScheme.onPrimaryContainer,
                            labelStyle: TextStyle(
                              color: _showMatchedOnly
                                  ? Theme.of(context).colorScheme.onPrimaryContainer
                                  : Theme.of(context).colorScheme.onSurface,
                              fontWeight: _showMatchedOnly ? FontWeight.w600 : FontWeight.normal,
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          fit: FlexFit.loose,
                          child: FilterChip(
                            label: Text('unmatched_only'.tr()),
                            selected: _showUnmatchedOnly,
                            onSelected: (value) {
                              HapticFeedback.lightImpact();
                              setState(() {
                                _showUnmatchedOnly = value;
                                if (value) _showMatchedOnly = false;
                              });
                            },
                            selectedColor: Theme.of(context).colorScheme.errorContainer,
                            checkmarkColor: Theme.of(context).colorScheme.onErrorContainer,
                            labelStyle: TextStyle(
                              color: _showUnmatchedOnly
                                  ? Theme.of(context).colorScheme.onErrorContainer
                                  : Theme.of(context).colorScheme.onSurface,
                              fontWeight: _showUnmatchedOnly ? FontWeight.w600 : FontWeight.normal,
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      ],
                    ],
                  ),
                  // Filter chips row (shown when search is expanded)
                  AnimatedSize(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    child: _isSearchExpanded
                        ? Column(
                            children: [
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  FilterChip(
                                    label: Text('matched_only'.tr()),
                                    selected: _showMatchedOnly,
                                    onSelected: (value) {
                                      HapticFeedback.lightImpact();
                                      setState(() {
                                        _showMatchedOnly = value;
                                        if (value) _showUnmatchedOnly = false;
                                      });
                                    },
                                    selectedColor: Theme.of(context).colorScheme.primaryContainer,
                                    checkmarkColor: Theme.of(context).colorScheme.onPrimaryContainer,
                                    labelStyle: TextStyle(
                                      color: _showMatchedOnly
                                          ? Theme.of(context).colorScheme.onPrimaryContainer
                                          : Theme.of(context).colorScheme.onSurface,
                                      fontWeight: _showMatchedOnly ? FontWeight.w600 : FontWeight.normal,
                                    ),
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  const SizedBox(width: 8),
                                  FilterChip(
                                    label: Text('unmatched_only'.tr()),
                                    selected: _showUnmatchedOnly,
                                    onSelected: (value) {
                                      HapticFeedback.lightImpact();
                                      setState(() {
                                        _showUnmatchedOnly = value;
                                        if (value) _showMatchedOnly = false;
                                      });
                                    },
                                    selectedColor: Theme.of(context).colorScheme.errorContainer,
                                    checkmarkColor: Theme.of(context).colorScheme.onErrorContainer,
                                    labelStyle: TextStyle(
                                      color: _showUnmatchedOnly
                                          ? Theme.of(context).colorScheme.onErrorContainer
                                          : Theme.of(context).colorScheme.onSurface,
                                      fontWeight: _showUnmatchedOnly ? FontWeight.w600 : FontWeight.normal,
                                    ),
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                ],
                              ),
                            ],
                          )
                        : const SizedBox.shrink(),
                  ),
                  const SizedBox(height: 12),
                  // Stats row - wrapped to prevent overflow
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      _buildStatChip(
                        context,
                        'total_sms'.tr(args: [smsList.length.toString()]),
                        Theme.of(context).colorScheme.onSurface,
                      ),
                      _buildStatChip(
                        context,
                        'matched_count'.tr(args: [matchedCount.toString()]),
                        Theme.of(context).colorScheme.primary,
                        icon: Icons.check_circle_outline,
                      ),
                      _buildStatChip(
                        context,
                        'unmatched_count'.tr(args: [unmatchedCount.toString()]),
                        Theme.of(context).colorScheme.error,
                        icon: Icons.cancel_outlined,
                      ),
                      if (parsingCount > 0)
                        _buildStatChip(
                          context,
                          'parsing_count'.tr(args: [parsingCount.toString()]),
                          Theme.of(context).colorScheme.secondary,
                          icon: Icons.hourglass_empty,
                        ),
                    ],
                  ),
                ],
              ),
            ),
            // SMS List
            Expanded(
              child: filteredSms.isEmpty
                  ? EmptyState(
                      icon: Icons.sms_outlined,
                      title: _getEmptyStateTitle(),
                      subtitle: _getEmptyStateSubtitle(),
                    )
                  : RefreshIndicator(
                      onRefresh: () async {
                        await ref.read(smsListProvider.notifier).refresh();
                      },
                      child: ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: filteredSms.length,
                        itemBuilder: (context, index) {
                          final smsWithStatus = filteredSms[index];
                          return _SmsListItemWithStatus(
                            smsWithStatus: smsWithStatus,
                            onTap: () {
                              HapticFeedback.lightImpact();
                              _showSmsDetails(smsWithStatus);
                            },
                            onCreateTemplate: () {
                              HapticFeedback.lightImpact();
                              _createTemplateFromSms(smsWithStatus.sms);
                            },
                          );
                        },
                      ),
                    ),
            ),
          ],
        );
      },
      loading: () => Column(
        children: [
          // Search and filter bar skeleton
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
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 100,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 120,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Stats skeleton
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    Container(
                      width: 80,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    Container(
                      width: 80,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    Container(
                      width: 80,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // List skeleton
          Expanded(
            child: SkeletonList(itemCount: 5, itemHeight: 140),
          ),
        ],
      ),
      error: (error, stack) => ErrorState(
        title: 'error_loading_sms'.tr(),
        message: error.toString(),
        onRetry: () => ref.read(smsListProvider.notifier).refresh(),
      ),
    );
  }

  String _getEmptyStateTitle() {
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
  }

  String? _getEmptyStateSubtitle() {
    if (_debouncedSearchQuery.isNotEmpty || _showMatchedOnly || _showUnmatchedOnly) {
      return null;
    }
    return 'no_sms_messages_description'.tr();
  }

  Widget _buildStatChip(
    BuildContext context,
    String text,
    Color color, {
    IconData? icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
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
}

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
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: colorScheme.outline.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
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
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: smsWithStatus.isMatched
                          ? colorScheme.primaryContainer
                          : smsWithStatus.isParsing
                              ? colorScheme.surfaceContainerHighest
                              : colorScheme.surfaceContainerHighest,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      smsWithStatus.isParsing
                          ? Icons.hourglass_empty
                          : smsWithStatus.isMatched
                              ? Icons.check_circle
                              : Icons.sms_outlined,
                      size: 20,
                      color: smsWithStatus.isMatched
                          ? colorScheme.onPrimaryContainer
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
                style: theme.textTheme.bodyMedium?.copyWith(
                  height: 1.4,
                ),
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
                        if (parsedData.storeName != null) const SizedBox(height: 8),
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
                        if (parsedData.amount != null) const SizedBox(height: 8),
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
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: onCreateTemplate,
                    icon: const Icon(Icons.add_circle_outline, size: 18),
                    label: Text('create_template'.tr()),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
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
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w500,
            ),
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
                        style: theme.textTheme.bodyLarge?.copyWith(
                          height: 1.5,
                        ),
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
                              if (parsedData.storeName != null) const SizedBox(height: 12),
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
                              if (parsedData.amount != null) const SizedBox(height: 12),
                              _buildParsedDetailRow(
                                context,
                                'card'.tr(),
                                '****${parsedData.cardLast4Digits}',
                              ),
                            ],
                            if (confidence != null) ...[
                              if (parsedData.cardLast4Digits != null) const SizedBox(height: 12),
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
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
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
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
