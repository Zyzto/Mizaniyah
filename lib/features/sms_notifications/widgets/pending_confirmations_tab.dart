import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:mizaniyah/core/database/app_database.dart' as db;
import 'package:mizaniyah/core/database/daos/transaction_dao.dart';
import 'package:mizaniyah/core/database/daos/card_dao.dart';
import 'package:mizaniyah/core/database/providers/database_provider.dart';
import 'package:mizaniyah/core/database/providers/dao_providers.dart';
import 'package:mizaniyah/core/utils/currency_formatter.dart';
import 'package:mizaniyah/core/services/providers/sms_detection_provider.dart';
import 'package:mizaniyah/features/sms_templates/providers/sms_template_providers.dart';
import 'package:drift/drift.dart' as drift;
import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/loading_skeleton.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/error_snackbar.dart';
import 'edit_confirmation_dialog.dart';
import 'batch_processing_dialog.dart';

class PendingConfirmationsTab extends ConsumerStatefulWidget {
  const PendingConfirmationsTab({super.key});

  @override
  ConsumerState<PendingConfirmationsTab> createState() =>
      _PendingConfirmationsTabState();
}

class _PendingConfirmationsTabState
    extends ConsumerState<PendingConfirmationsTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final Set<int> _selectedIds = {};
  bool _isSelectionMode = false;
  String _confidenceFilter = 'all'; // 'all', 'high', 'medium', 'low'

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    // Use StreamProvider for reactive updates without refetching on navigation
    final confirmationsAsync = ref.watch(pendingSmsConfirmationsProvider);
    // Watch SMS detection state for the status indicator
    final smsDetectionState = ref.watch(smsDetectionManagerProvider);

    return Stack(
      children: [
        confirmationsAsync.when(
          data: (confirmations) {
            if (confirmations.isEmpty) {
              return Column(
                children: [
                  // Detection status bar at the top
                  _buildDetectionStatusBar(context, smsDetectionState),
                  Expanded(
                    child: EmptyState(
                      icon: Icons.check_circle_outline,
                      title: 'no_pending'.tr(),
                      subtitle: 'all_processed'.tr(),
                    ),
                  ),
                ],
              );
            }

            // Filter by confidence
            final filtered = _filterByConfidence(confirmations);

            // Sort confirmations by confidence (high to low) or date (newest first)
            final sortedConfirmations =
                List<db.PendingSmsConfirmation>.from(filtered)..sort((a, b) {
                  try {
                    final aJson =
                        jsonDecode(a.parsedData) as Map<String, dynamic>;
                    final bJson =
                        jsonDecode(b.parsedData) as Map<String, dynamic>;
                    final aConf = aJson['confidence'] as double? ?? 0.0;
                    final bConf = bJson['confidence'] as double? ?? 0.0;
                    // Sort by confidence descending, then by date descending
                    final confCompare = bConf.compareTo(aConf);
                    if (confCompare != 0) return confCompare;
                    return b.createdAt.compareTo(a.createdAt);
                  } catch (e) {
                    return b.createdAt.compareTo(a.createdAt);
                  }
                });

            return Column(
              children: [
                // Detection status bar at the top
                _buildDetectionStatusBar(context, smsDetectionState),
                // Filter and sort controls
                _buildFilterBar(),
                if (_isSelectionMode) _buildSelectionBar(sortedConfirmations),
                Expanded(
                  child: ListView.builder(
                    itemCount: sortedConfirmations.length,
                    itemBuilder: (context, index) {
                      final confirmation = sortedConfirmations[index];
                      return _PendingConfirmationCard(
                        confirmation: confirmation,
                        isSelected: _selectedIds.contains(confirmation.id),
                        isSelectionMode: _isSelectionMode,
                        onApprove: () => _approveConfirmation(confirmation),
                        onReject: () => _rejectConfirmation(confirmation),
                        onEdit: () => _editConfirmation(confirmation),
                        onViewSms: () => _viewSms(confirmation),
                        onToggleSelection: () {
                          setState(() {
                            if (_selectedIds.contains(confirmation.id)) {
                              _selectedIds.remove(confirmation.id);
                            } else {
                              _selectedIds.add(confirmation.id);
                            }
                            if (_selectedIds.isEmpty) {
                              _isSelectionMode = false;
                            }
                          });
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
          loading: () => const SkeletonList(itemCount: 3, itemHeight: 160),
          error: (error, stack) => ErrorState(
            title: 'error_loading_confirmations'.tr(),
            message: error.toString(),
            onRetry: () => ref.invalidate(pendingSmsConfirmationsProvider),
          ),
        ),
        // Scan FAB - use PositionedDirectional for RTL support
        PositionedDirectional(
          bottom: 16,
          end: 16,
          child: FloatingActionButton.extended(
            heroTag: 'scan_sms_fab',
            onPressed: () => _openBatchProcessingDialog(context),
            icon: const Icon(Icons.document_scanner_outlined),
            label: Text('scan_sms'.tr()),
            tooltip: 'scan_historical_sms'.tr(),
          ),
        ),
      ],
    );
  }

  void _openBatchProcessingDialog(BuildContext context) {
    HapticFeedback.lightImpact();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const BatchProcessingDialog(),
    );
  }

  Widget _buildDetectionStatusBar(
    BuildContext context,
    SmsDetectionState state,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isActive = state.isEnabled && state.isListening;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isActive
            ? colorScheme.primaryContainer.withValues(alpha: 0.5)
            : colorScheme.surfaceContainerHighest,
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: Row(
        children: [
          // Status indicator dot
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive ? colorScheme.primary : colorScheme.outline,
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: colorScheme.primary.withValues(alpha: 0.4),
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
          ),
          const SizedBox(width: 10),
          // Status text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isActive
                      ? 'realtime_detection_active'.tr()
                      : 'realtime_detection_inactive'.tr(),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isActive
                        ? colorScheme.onPrimaryContainer
                        : colorScheme.onSurfaceVariant,
                  ),
                ),
                if (isActive)
                  Text(
                    'auto_create_threshold'.tr(
                      args: [
                        '${(state.confidenceThreshold * 100).toStringAsFixed(0)}%',
                      ],
                    ),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onPrimaryContainer.withValues(
                        alpha: 0.8,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // Toggle button
          IconButton(
            icon: Icon(
              isActive ? Icons.pause_circle_outline : Icons.play_circle_outline,
              color: isActive
                  ? colorScheme.onPrimaryContainer
                  : colorScheme.primary,
            ),
            tooltip: isActive
                ? 'disable_detection'.tr()
                : 'enable_detection'.tr(),
            onPressed: () {
              HapticFeedback.lightImpact();
              ref.read(smsDetectionManagerProvider.notifier).toggleDetection();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.filter_list,
            size: 18,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SegmentedButton<String>(
              style: SegmentedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                visualDensity: VisualDensity.compact,
              ),
              segments: [
                ButtonSegment(
                  value: 'all',
                  label: Text('all'.tr()),
                ),
                ButtonSegment(
                  value: 'high',
                  label: Text('high'.tr()),
                ),
                ButtonSegment(
                  value: 'medium',
                  label: Text('med'.tr()),
                ),
                ButtonSegment(
                  value: 'low',
                  label: Text('low'.tr()),
                ),
              ],
              selected: {_confidenceFilter},
              onSelectionChanged: (Set<String> selected) {
                HapticFeedback.lightImpact();
                setState(() {
                  _confidenceFilter = selected.first;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  List<db.PendingSmsConfirmation> _filterByConfidence(
    List<db.PendingSmsConfirmation> confirmations,
  ) {
    if (_confidenceFilter == 'all') {
      return confirmations;
    }

    return confirmations.where((confirmation) {
      try {
        final parsedDataJson =
            jsonDecode(confirmation.parsedData) as Map<String, dynamic>;
        final confidence = parsedDataJson['confidence'] as double? ?? 0.0;

        switch (_confidenceFilter) {
          case 'high':
            return confidence >= 0.7;
          case 'medium':
            return confidence >= 0.5 && confidence < 0.7;
          case 'low':
            return confidence < 0.5;
          default:
            return true;
        }
      } catch (e) {
        return true; // Include if we can't parse
      }
    }).toList();
  }

  Widget _buildSelectionBar(List<db.PendingSmsConfirmation> confirmations) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'selected_count'.tr(args: [_selectedIds.length.toString()]),
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 16),
            TextButton.icon(
              onPressed: _selectedIds.length == confirmations.length
                  ? () {
                      setState(() {
                        _selectedIds.clear();
                      });
                    }
                  : () {
                      setState(() {
                        _selectedIds.addAll(
                          confirmations.map((c) => c.id).toSet(),
                        );
                      });
                    },
              icon: Icon(
                _selectedIds.length == confirmations.length
                    ? Icons.deselect
                    : Icons.select_all,
              ),
              label: Text(
                _selectedIds.length == confirmations.length
                    ? 'deselect_all'.tr()
                    : 'select_all'.tr(),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton.icon(
              onPressed: _selectedIds.isEmpty ? null : () => _bulkApprove(),
              icon: const Icon(Icons.check),
              label: Text('approve_selected'.tr()),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                setState(() {
                  _isSelectionMode = false;
                  _selectedIds.clear();
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _bulkApprove() async {
    if (_selectedIds.isEmpty) return;

    HapticFeedback.mediumImpact();
    final pendingSmsDao = ref.read(pendingSmsConfirmationDaoProvider);
    final confirmations = await pendingSmsDao.getAllPendingConfirmations();
    final toApprove = confirmations
        .where((c) => _selectedIds.contains(c.id))
        .toList();

    int successCount = 0;
    for (final confirmation in toApprove) {
      try {
        await _approveConfirmation(confirmation, silent: true);
        successCount++;
      } catch (e) {
        // Continue with others
      }
    }

    setState(() {
      _selectedIds.clear();
      _isSelectionMode = false;
    });

    if (!mounted || !context.mounted) return;
    HapticFeedback.heavyImpact();
    ErrorSnackbar.showSuccess(
      context,
      'bulk_approved'.tr(args: [successCount.toString()]),
    );
  }

  Future<void> _approveConfirmation(
    db.PendingSmsConfirmation confirmation, {
    bool silent = false,
  }) async {
    if (!silent) HapticFeedback.mediumImpact();
    try {
      final database = ref.read(databaseProvider);
      final transactionDao = TransactionDao(database);
      final cardDao = CardDao(database);
      final pendingSmsDao = ref.read(pendingSmsConfirmationDaoProvider);

      // Parse the parsed data
      final parsedDataJson =
          jsonDecode(confirmation.parsedData) as Map<String, dynamic>;
      final storeName = parsedDataJson['store_name'] as String?;
      final amount = parsedDataJson['amount'] as double?;
      final currency = parsedDataJson['currency'] as String? ?? 'USD';
      final cardLast4 = parsedDataJson['card_last4'] as String?;
      final transactionDateStr = parsedDataJson['transaction_date'] as String?;
      final transactionDate = transactionDateStr != null
          ? DateTime.tryParse(transactionDateStr)
          : null;

      if (storeName == null || amount == null) {
        if (!mounted || !context.mounted) return;
        if (!silent) {
          HapticFeedback.heavyImpact();
          ErrorSnackbar.show(context, 'invalid_confirmation_data'.tr());
        }
        return;
      }

      // Find card by last 4 digits if available
      int? cardId;
      if (cardLast4 != null && cardLast4.length == 4) {
        final card = await cardDao.getCardByLast4Digits(cardLast4);
        cardId = card?.id;
      }

      // Use extracted transaction date or fallback to confirmation creation date
      final date = transactionDate ?? confirmation.createdAt;

      // Generate SMS hash for duplicate detection
      final smsHash =
          '${confirmation.smsSender}|${confirmation.smsBody}|${date.toIso8601String().split('T')[0]}';
      final hashBytes = utf8.encode(smsHash);
      final hash = sha256.convert(hashBytes).toString();

      // Check for duplicate
      final duplicate = await transactionDao.findDuplicateBySmsHash(hash);
      if (duplicate != null) {
        if (!mounted || !context.mounted) return;
        if (!silent) {
          HapticFeedback.heavyImpact();
          ErrorSnackbar.show(context, 'duplicate_transaction_detected'.tr());
        }
        // Delete confirmation since it's a duplicate
        await pendingSmsDao.deleteConfirmation(confirmation.id);
        return;
      }

      // Create transaction
      final transaction = db.TransactionsCompanion(
        amount: drift.Value(amount),
        currencyCode: drift.Value(currency),
        storeName: drift.Value(storeName),
        cardId: cardId != null
            ? drift.Value(cardId)
            : const drift.Value.absent(),
        categoryId:
            const drift.Value.absent(), // Category can be set via edit dialog
        date: drift.Value(date),
        source: const drift.Value('sms'),
        smsHash: drift.Value(hash),
        notes: drift.Value('approved_from_sms'.tr()),
      );

      await transactionDao.insertTransaction(transaction);

      // Delete the pending confirmation - stream will auto-update UI
      await pendingSmsDao.deleteConfirmation(confirmation.id);

      if (!mounted || !context.mounted) return;
      if (!silent) {
        HapticFeedback.heavyImpact();
        ErrorSnackbar.showSuccess(context, 'transaction_created'.tr());
        // No need for setState - stream provider auto-updates
      }
    } catch (e) {
      if (!mounted || !context.mounted) return;
      if (!silent) {
        HapticFeedback.heavyImpact();
        ErrorSnackbar.show(
          context,
          'approve_confirmation_failed'.tr(args: [e.toString()]),
        );
      } else {
        rethrow;
      }
    }
  }

  Future<void> _rejectConfirmation(
    db.PendingSmsConfirmation confirmation,
  ) async {
    HapticFeedback.mediumImpact();
    try {
      final pendingSmsDao = ref.read(pendingSmsConfirmationDaoProvider);
      // Delete confirmation - stream will auto-update UI
      await pendingSmsDao.deleteConfirmation(confirmation.id);

      if (!mounted || !context.mounted) return;
      HapticFeedback.lightImpact();
      ErrorSnackbar.showSuccess(context, 'confirmation_rejected'.tr());
      // No need for setState - stream provider auto-updates
    } catch (e) {
      if (!mounted || !context.mounted) return;
      HapticFeedback.heavyImpact();
      ErrorSnackbar.show(
        context,
        'reject_confirmation_failed'.tr(args: [e.toString()]),
      );
    }
  }

  void _editConfirmation(db.PendingSmsConfirmation confirmation) {
    HapticFeedback.lightImpact();
    showDialog(
      context: context,
      builder: (context) => EditConfirmationDialog(confirmation: confirmation),
    ).then((editedData) {
      if (editedData != null && mounted) {
        // Confirmation was updated, stream will auto-refresh
        HapticFeedback.lightImpact();
        ErrorSnackbar.showSuccess(context, 'confirmation_updated'.tr());
      }
    });
  }

  void _viewSms(db.PendingSmsConfirmation confirmation) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _SmsViewSheet(confirmation: confirmation),
    );
  }
}

class _PendingConfirmationCard extends StatefulWidget {
  final db.PendingSmsConfirmation confirmation;
  final bool isSelected;
  final bool isSelectionMode;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onEdit;
  final VoidCallback onViewSms;
  final VoidCallback onToggleSelection;

  const _PendingConfirmationCard({
    required this.confirmation,
    required this.isSelected,
    required this.isSelectionMode,
    required this.onApprove,
    required this.onReject,
    required this.onEdit,
    required this.onViewSms,
    required this.onToggleSelection,
  });

  @override
  State<_PendingConfirmationCard> createState() =>
      _PendingConfirmationCardState();
}

class _PendingConfirmationCardState extends State<_PendingConfirmationCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final parsedDataJson =
        jsonDecode(widget.confirmation.parsedData) as Map<String, dynamic>;
    final storeName = parsedDataJson['store_name'] as String? ?? 'unknown'.tr();
    final amount = parsedDataJson['amount'] as double? ?? 0.0;
    final currency = parsedDataJson['currency'] as String? ?? 'USD';
    final confidence = parsedDataJson['confidence'] as double?;
    final cardLast4 = parsedDataJson['card_last4'] as String?;

    final confidenceColor = _getConfidenceColor(confidence, colorScheme);
    final confidenceLevel = _getConfidenceLevel(confidence);

    return Dismissible(
      key: Key('confirmation_${widget.confirmation.id}'),
      direction: DismissDirection.horizontal,
      background: Container(
        alignment: AlignmentDirectional.centerStart,
        padding: const EdgeInsetsDirectional.only(start: 20),
        color: colorScheme.errorContainer,
        child: Row(
          children: [
            Icon(Icons.close, color: colorScheme.onErrorContainer),
            const SizedBox(width: 8),
            Text(
              'reject'.tr(),
              style: TextStyle(color: colorScheme.onErrorContainer),
            ),
          ],
        ),
      ),
      secondaryBackground: Container(
        alignment: AlignmentDirectional.centerEnd,
        padding: const EdgeInsetsDirectional.only(end: 20),
        color: colorScheme.primaryContainer,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              'approve'.tr(),
              style: TextStyle(color: colorScheme.onPrimaryContainer),
            ),
            const SizedBox(width: 8),
            Icon(Icons.check, color: colorScheme.onPrimaryContainer),
          ],
        ),
      ),
      onDismissed: (direction) {
        if (direction == DismissDirection.startToEnd) {
          widget.onReject();
        } else {
          widget.onApprove();
        }
      },
      confirmDismiss: (direction) async {
        HapticFeedback.mediumImpact();
        return true;
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        color: widget.isSelected
            ? colorScheme.primaryContainer.withValues(alpha: 0.3)
            : null,
        child: InkWell(
          onTap: widget.isSelectionMode
              ? widget.onToggleSelection
              : () {
                  setState(() {
                    _isExpanded = !_isExpanded;
                  });
                },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (widget.isSelectionMode)
                      Checkbox(
                        value: widget.isSelected,
                        onChanged: (_) => widget.onToggleSelection(),
                      ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            storeName,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            CurrencyFormatter.format(amount, currency),
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (confidence != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: confidenceColor,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            Text(
                              '${(confidence * 100).toStringAsFixed(0)}%',
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: colorScheme.onPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              confidenceLevel,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: colorScheme.onPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                if (cardLast4 != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.credit_card,
                        size: 16,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          'card_ending'.tr(args: [cardLast4]),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
                if (_isExpanded) ...[
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 8),
                  IntrinsicHeight(
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: widget.onViewSms,
                            icon: const Icon(Icons.sms),
                            label: Flexible(
                              child: Text(
                                'view_sms'.tr(),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: widget.onEdit,
                            icon: const Icon(Icons.edit),
                            label: Flexible(
                              child: Text(
                                'edit'.tr(),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (!widget.isSelectionMode) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    alignment: WrapAlignment.end,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      TextButton.icon(
                        onPressed: widget.onReject,
                        icon: const Icon(Icons.close),
                        label: Text('reject'.tr()),
                      ),
                      FilledButton.icon(
                        onPressed: widget.onApprove,
                        icon: const Icon(Icons.check),
                        label: Text('approve'.tr()),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getConfidenceColor(double? confidence, ColorScheme colorScheme) {
    if (confidence == null) return colorScheme.surfaceContainerHighest;
    if (confidence >= 0.7) return colorScheme.primary;
    if (confidence >= 0.5) return colorScheme.secondary;
    return colorScheme.error;
  }

  String _getConfidenceLevel(double? confidence) {
    if (confidence == null) return '';
    if (confidence >= 0.7) return 'high'.tr();
    if (confidence >= 0.5) return 'medium'.tr();
    return 'low'.tr();
  }
}

class _SmsViewSheet extends StatelessWidget {
  final db.PendingSmsConfirmation confirmation;

  const _SmsViewSheet({required this.confirmation});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('MMM dd, yyyy HH:mm');

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Column(
          children: [
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
                    'original_sms'.tr(),
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
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
                      confirmation.smsSender,
                    ),
                    _buildDetailRow(
                      context,
                      'date'.tr(),
                      dateFormat.format(confirmation.createdAt),
                    ),
                    const Divider(),
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
                        confirmation.smsBody,
                        style: theme.textTheme.bodyLarge,
                      ),
                    ),
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
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 80, maxWidth: 120),
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(value, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}
