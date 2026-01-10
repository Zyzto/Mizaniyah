import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:mizaniyah/core/database/app_database.dart' as db;
import 'package:mizaniyah/core/database/daos/pending_sms_confirmation_dao.dart';
import 'package:mizaniyah/core/database/daos/transaction_dao.dart';
import 'package:mizaniyah/core/database/daos/card_dao.dart';
import 'package:mizaniyah/core/database/providers/database_provider.dart';
import 'package:mizaniyah/core/utils/currency_formatter.dart';
import 'package:drift/drift.dart' as drift;
import 'dart:convert';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/loading_skeleton.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/error_snackbar.dart';

class PendingConfirmationsTab extends ConsumerStatefulWidget {
  const PendingConfirmationsTab({super.key});

  @override
  ConsumerState<PendingConfirmationsTab> createState() =>
      _PendingConfirmationsTabState();
}

class _PendingConfirmationsTabState
    extends ConsumerState<PendingConfirmationsTab> {
  @override
  Widget build(BuildContext context) {
    final database = ref.watch(databaseProvider);
    final pendingSmsDao = PendingSmsConfirmationDao(database);

    return FutureBuilder<List<db.PendingSmsConfirmation>>(
      future: pendingSmsDao.getNonExpiredConfirmations(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SkeletonList(itemCount: 3, itemHeight: 120);
        }

        if (snapshot.hasError) {
          return ErrorState(
            title: 'error_loading_confirmations'.tr(),
            message: snapshot.error.toString(),
            onRetry: () {
              setState(() {});
            },
          );
        }

        final confirmations = snapshot.data ?? [];

        if (confirmations.isEmpty) {
          return EmptyState(
            icon: Icons.check_circle_outline,
            title: 'no_pending'.tr(),
            subtitle: 'all_processed'.tr(),
          );
        }

        return ListView.builder(
          itemCount: confirmations.length,
          itemBuilder: (context, index) {
            final confirmation = confirmations[index];
            return _PendingConfirmationCard(
              confirmation: confirmation,
              onApprove: () => _approveConfirmation(confirmation),
              onReject: () => _rejectConfirmation(confirmation),
            );
          },
        );
      },
    );
  }

  Future<void> _approveConfirmation(
    db.PendingSmsConfirmation confirmation,
  ) async {
    HapticFeedback.mediumImpact();
    try {
      final database = ref.read(databaseProvider);
      final transactionDao = TransactionDao(database);
      final cardDao = CardDao(database);
      final pendingSmsDao = PendingSmsConfirmationDao(database);

      // Parse the parsed data
      final parsedDataJson =
          jsonDecode(confirmation.parsedData) as Map<String, dynamic>;
      final storeName = parsedDataJson['store_name'] as String?;
      final amount = parsedDataJson['amount'] as double?;
      final currency = parsedDataJson['currency'] as String? ?? 'USD';
      final cardLast4 = parsedDataJson['card_last4'] as String?;

      if (storeName == null || amount == null) {
        if (!mounted || !context.mounted) return;
        HapticFeedback.heavyImpact();
        ErrorSnackbar.show(
          context,
          'invalid_confirmation_data'.tr(),
        );
        return;
      }

      // Find card by last 4 digits if available
      int? cardId;
      if (cardLast4 != null && cardLast4.length == 4) {
        final card = await cardDao.getCardByLast4Digits(cardLast4);
        cardId = card?.id;
      }

      // Create transaction
      final transaction = db.TransactionsCompanion(
        amount: drift.Value(amount),
        currencyCode: drift.Value(currency),
        storeName: drift.Value(storeName),
        cardId: drift.Value(cardId),
        categoryId: const drift.Value.absent(),
        date: drift.Value(DateTime.now()),
        source: const drift.Value('sms'),
        notes: drift.Value('approved_from_sms'.tr()),
      );

      await transactionDao.insertTransaction(transaction);

      // Delete the pending confirmation
      await pendingSmsDao.deleteConfirmation(confirmation.id);

      if (!mounted || !context.mounted) return;
      HapticFeedback.heavyImpact();
      ErrorSnackbar.showSuccess(
        context,
        'transaction_created'.tr(),
      );
      setState(() {}); // Refresh the list
    } catch (e) {
      if (!mounted || !context.mounted) return;
      HapticFeedback.heavyImpact();
      ErrorSnackbar.show(
        context,
        'approve_confirmation_failed'.tr(args: [e.toString()]),
      );
    }
  }

  Future<void> _rejectConfirmation(
    db.PendingSmsConfirmation confirmation,
  ) async {
    HapticFeedback.mediumImpact();
    try {
      final database = ref.read(databaseProvider);
      final pendingSmsDao = PendingSmsConfirmationDao(database);
      await pendingSmsDao.deleteConfirmation(confirmation.id);

      if (!mounted || !context.mounted) return;
      HapticFeedback.lightImpact();
      ErrorSnackbar.showSuccess(context, 'confirmation_rejected'.tr());
      setState(() {}); // Refresh the list
    } catch (e) {
      if (!mounted || !context.mounted) return;
      HapticFeedback.heavyImpact();
      ErrorSnackbar.show(
        context,
        'reject_confirmation_failed'.tr(args: [e.toString()]),
      );
    }
  }
}

class _PendingConfirmationCard extends StatelessWidget {
  final db.PendingSmsConfirmation confirmation;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _PendingConfirmationCard({
    required this.confirmation,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final parsedDataJson =
        jsonDecode(confirmation.parsedData) as Map<String, dynamic>;
    final storeName = parsedDataJson['store_name'] as String? ?? 'unknown'.tr();
    final amount = parsedDataJson['amount'] as double? ?? 0.0;
    final currency = parsedDataJson['currency'] as String? ?? 'USD';
    final confidence = parsedDataJson['confidence'] as double?;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              storeName,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              CurrencyFormatter.format(amount, currency),
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            if (confidence != null) ...[
              const SizedBox(height: 8),
              Text(
                'confidence_label'.tr(args: [
                  (confidence * 100).toStringAsFixed(0),
                ]),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    onReject();
                  },
                  child: Text('reject'.tr()),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    onApprove();
                  },
                  child: Text('approve'.tr()),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
