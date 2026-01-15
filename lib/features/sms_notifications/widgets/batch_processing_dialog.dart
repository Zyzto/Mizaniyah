import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:mizaniyah/core/services/sms_detection/sms_batch_processor.dart';
import 'package:mizaniyah/core/services/sms_reader_service.dart';
import 'package:mizaniyah/core/services/sms_detection/sms_matcher.dart';
import 'package:mizaniyah/core/services/sms_detection/sms_confirmation_handler.dart';
import 'package:mizaniyah/core/services/sms_detection/sms_transaction_creator.dart';
import 'package:mizaniyah/core/database/providers/dao_providers.dart';
import 'package:mizaniyah/core/widgets/enhanced_date_picker_field.dart';

/// Dialog for batch processing historical SMS messages
class BatchProcessingDialog extends ConsumerStatefulWidget {
  const BatchProcessingDialog({super.key});

  @override
  ConsumerState<BatchProcessingDialog> createState() =>
      _BatchProcessingDialogState();
}

class _BatchProcessingDialogState extends ConsumerState<BatchProcessingDialog> {
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  bool _autoCreate = false;
  double _confidenceThreshold = 0.7;

  bool _isProcessing = false;
  int _processed = 0;
  int _total = 0;
  int _matched = 0;
  int _created = 0;
  bool _isCompleted = false;
  String? _error;

  StreamSubscription<({int processed, int total, int matched, int created})>?
  _subscription;

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> _startProcessing() async {
    setState(() {
      _isProcessing = true;
      _processed = 0;
      _total = 0;
      _matched = 0;
      _created = 0;
      _isCompleted = false;
      _error = null;
    });

    try {
      final smsTemplateDao = ref.read(smsTemplateDaoProvider);
      final transactionDao = ref.read(transactionDaoProvider);
      final cardDao = ref.read(cardDaoProvider);
      final pendingSmsConfirmationDao = ref.read(
        pendingSmsConfirmationDaoProvider,
      );

      // Create batch processor with required dependencies
      final smsMatcher = SmsMatcher(smsTemplateDao);
      final confirmationHandler = SmsConfirmationHandler(
        pendingSmsConfirmationDao,
      );

      SmsTransactionCreator? transactionCreator;
      if (_autoCreate) {
        transactionCreator = SmsTransactionCreator(transactionDao, cardDao);
      }

      final batchProcessor = SmsBatchProcessor(
        smsReaderService: SmsReaderService.instance,
        smsMatcher: smsMatcher,
        transactionCreator: transactionCreator,
        confirmationHandler: confirmationHandler,
      );

      final stream = batchProcessor.processDateRange(
        startDate: _startDate,
        endDate: _endDate,
        smsTemplateDao: smsTemplateDao,
        autoCreate: _autoCreate,
        confidenceThreshold: _confidenceThreshold,
      );

      _subscription = stream.listen(
        (progress) {
          if (mounted) {
            setState(() {
              _processed = progress.processed;
              _total = progress.total;
              _matched = progress.matched;
              _created = progress.created;
            });
          }
        },
        onError: (error) {
          if (mounted) {
            setState(() {
              _error = error.toString();
              _isProcessing = false;
            });
          }
        },
        onDone: () {
          if (mounted) {
            setState(() {
              _isProcessing = false;
              _isCompleted = true;
            });
          }
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isProcessing = false;
        });
      }
    }
  }

  void _cancel() {
    _subscription?.cancel();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Title
              Row(
                children: [
                  Icon(Icons.batch_prediction, color: colorScheme.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'batch_process_sms'.tr(),
                      style: theme.textTheme.titleLarge,
                    ),
                  ),
                  if (!_isProcessing)
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                ],
              ),
              const SizedBox(height: 16),

              if (!_isProcessing && !_isCompleted) ...[
                // Date range selection
                Text(
                  'select_date_range'.tr(),
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: 12),

                // Start date
                EnhancedDatePickerField(
                  labelText: 'start_date'.tr(),
                  initialDate: _startDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                  onDateSelected: (date) {
                    setState(() {
                      _startDate = date;
                      if (_endDate.isBefore(_startDate)) {
                        _endDate = _startDate;
                      }
                    });
                  },
                ),
                const SizedBox(height: 12),

                // End date
                EnhancedDatePickerField(
                  labelText: 'end_date'.tr(),
                  initialDate: _endDate,
                  firstDate: _startDate,
                  lastDate: DateTime.now(),
                  onDateSelected: (date) {
                    setState(() {
                      _endDate = date;
                    });
                  },
                ),
                const SizedBox(height: 16),

                // Auto-create toggle
                SwitchListTile(
                  title: Text('auto_create_transactions'.tr()),
                  subtitle: Text(
                    'auto_create_description'.tr(),
                    style: theme.textTheme.bodySmall,
                  ),
                  value: _autoCreate,
                  onChanged: (value) {
                    setState(() {
                      _autoCreate = value;
                    });
                  },
                ),

                if (_autoCreate) ...[
                  const SizedBox(height: 8),
                  // Confidence threshold slider
                  Text(
                    '${'confidence_threshold'.tr()}: ${(_confidenceThreshold * 100).toStringAsFixed(0)}%',
                    style: theme.textTheme.bodyMedium,
                  ),
                  Slider(
                    value: _confidenceThreshold,
                    min: 0.5,
                    max: 1.0,
                    divisions: 10,
                    label:
                        '${(_confidenceThreshold * 100).toStringAsFixed(0)}%',
                    onChanged: (value) {
                      setState(() {
                        _confidenceThreshold = value;
                      });
                    },
                  ),
                ],

                const Spacer(),

                // Info text
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: colorScheme.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _autoCreate
                              ? 'batch_info_auto_create'.tr()
                              : 'batch_info_pending'.tr(),
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Action buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text('cancel'.tr()),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      onPressed: _startProcessing,
                      icon: const Icon(Icons.play_arrow),
                      label: Text('start_processing'.tr()),
                    ),
                  ],
                ),
              ] else if (_isProcessing) ...[
                // Processing indicator
                const SizedBox(height: 24),
                LinearProgressIndicator(
                  value: _total > 0 ? _processed / _total : null,
                ),
                const SizedBox(height: 16),
                Text(
                  'processing_sms'.tr(args: ['$_processed', '$_total']),
                  style: theme.textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // Stats
                _buildStatRow(
                  context,
                  Icons.check_circle_outline,
                  'matched'.tr(),
                  '$_matched',
                  colorScheme.primary,
                ),
                const SizedBox(height: 8),
                _buildStatRow(
                  context,
                  Icons.add_circle_outline,
                  'created'.tr(),
                  '$_created',
                  colorScheme.tertiary,
                ),

                const Spacer(),

                // Cancel button
                Center(
                  child: TextButton(
                    onPressed: _cancel,
                    child: Text('cancel'.tr()),
                  ),
                ),
              ] else if (_isCompleted) ...[
                // Completed
                const SizedBox(height: 24),
                Icon(Icons.check_circle, color: colorScheme.primary, size: 64),
                const SizedBox(height: 16),
                Text(
                  'batch_completed'.tr(),
                  style: theme.textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // Final stats
                _buildStatRow(
                  context,
                  Icons.sms_outlined,
                  'total_processed'.tr(),
                  '$_processed',
                  colorScheme.onSurface,
                ),
                const SizedBox(height: 8),
                _buildStatRow(
                  context,
                  Icons.check_circle_outline,
                  'matched'.tr(),
                  '$_matched',
                  colorScheme.primary,
                ),
                const SizedBox(height: 8),
                _buildStatRow(
                  context,
                  Icons.add_circle_outline,
                  _autoCreate
                      ? 'transactions_created'.tr()
                      : 'pending_created'.tr(),
                  '$_created',
                  colorScheme.tertiary,
                ),

                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _error!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onErrorContainer,
                      ),
                    ),
                  ),
                ],

                const Spacer(),

                // Done button
                Center(
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: Text('done'.tr()),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Text(label, style: theme.textTheme.bodyMedium),
        const Spacer(),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
