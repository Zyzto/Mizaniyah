import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mizaniyah/core/database/app_database.dart' as db;
import 'package:mizaniyah/features/pending_sms/pending_sms_repository.dart';
import 'package:mizaniyah/features/banks/providers/bank_providers.dart';
import 'package:mizaniyah/features/transactions/transaction_repository.dart';
import 'package:mizaniyah/features/banks/bank_repository.dart';
import 'package:drift/drift.dart' as drift;
import 'dart:convert';

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
    final pendingSmsRepository = PendingSmsRepository(database);

    return FutureBuilder<List<db.PendingSmsConfirmation>>(
      future: pendingSmsRepository.getNonExpiredConfirmations(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final confirmations = snapshot.data ?? [];

        if (confirmations.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.check_circle_outline,
                  size: 64,
                  color: Theme.of(context).colorScheme.outline,
                ),
                const SizedBox(height: 16),
                Text(
                  'No pending confirmations',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'All SMS transactions have been processed',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
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
    try {
      final database = ref.read(databaseProvider);
      final transactionRepository = TransactionRepository(database);
      final bankRepository = BankRepository(database);
      final pendingSmsRepository = PendingSmsRepository(database);

      // Parse the parsed data
      final parsedDataJson =
          jsonDecode(confirmation.parsedData) as Map<String, dynamic>;
      final storeName = parsedDataJson['store_name'] as String?;
      final amount = parsedDataJson['amount'] as double?;
      final currency = parsedDataJson['currency'] as String? ?? 'USD';
      final cardLast4 = parsedDataJson['card_last4'] as String?;

      if (storeName == null || amount == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invalid confirmation data')),
          );
        }
        return;
      }

      // Find card by last 4 digits if available
      int? cardId;
      if (cardLast4 != null && cardLast4.length == 4) {
        final card = await bankRepository.getCardByLast4Digits(cardLast4);
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
        notes: drift.Value('Approved from SMS confirmation'),
      );

      await transactionRepository.createTransaction(transaction);

      // Delete the pending confirmation
      await pendingSmsRepository.deleteConfirmation(confirmation.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transaction created successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _rejectConfirmation(
    db.PendingSmsConfirmation confirmation,
  ) async {
    try {
      final database = ref.read(databaseProvider);
      final pendingSmsRepository = PendingSmsRepository(database);
      await pendingSmsRepository.deleteConfirmation(confirmation.id);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Confirmation rejected')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
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
    final parsedDataJson =
        jsonDecode(confirmation.parsedData) as Map<String, dynamic>;
    final storeName = parsedDataJson['store_name'] as String? ?? 'Unknown';
    final amount = parsedDataJson['amount'] as double? ?? 0.0;
    final currency = parsedDataJson['currency'] as String? ?? 'USD';
    final confidence = parsedDataJson['confidence'] as double?;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        title: Text(storeName),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${amount.toStringAsFixed(2)} $currency'),
            if (confidence != null)
              Text(
                'Confidence: ${(confidence * 100).toStringAsFixed(0)}%',
                style: Theme.of(context).textTheme.bodySmall,
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextButton(onPressed: onReject, child: const Text('Reject')),
            const SizedBox(width: 8),
            FilledButton(onPressed: onApprove, child: const Text('Approve')),
          ],
        ),
      ),
    );
  }
}
