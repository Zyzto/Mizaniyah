import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/transaction_providers.dart';
import '../../categories/providers/category_providers.dart';
import '../../banks/providers/bank_providers.dart';
import '../../../core/database/app_database.dart' as db;
import 'transaction_form_page.dart';
import '../../../core/widgets/error_snackbar.dart';

class TransactionDetailPage extends ConsumerWidget {
  final db.Transaction transaction;

  const TransactionDetailPage({super.key, required this.transaction});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');
    final currencyFormat = NumberFormat.currency(symbol: '');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) =>
                      TransactionFormPage(transaction: transaction),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _deleteTransaction(context, ref),
            color: Colors.red,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.storeName,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${currencyFormat.format(transaction.amount)} ${transaction.currencyCode}',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildDetailRow(context, 'Date', dateFormat.format(transaction.date)),
          if (transaction.cardId != null)
            FutureBuilder<List<db.Card>>(
              future: ref.read(allCardsProvider.future),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  final card = snapshot.data!.firstWhere(
                    (c) => c.id == transaction.cardId,
                    orElse: () => throw StateError('Card not found'),
                  );
                  return _buildDetailRow(
                    context,
                    'Card',
                    '${card.cardName} (****${card.last4Digits})',
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          if (transaction.categoryId != null)
            FutureBuilder<db.Category?>(
              future: ref.read(
                categoryProvider(transaction.categoryId!).future,
              ),
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data != null) {
                  final category = snapshot.data!;
                  return _buildDetailRow(context, 'Category', category.name);
                }
                return const SizedBox.shrink();
              },
            ),
          _buildDetailRow(context, 'Source', transaction.source),
          if (transaction.notes != null && transaction.notes!.isNotEmpty)
            _buildDetailRow(context, 'Notes', transaction.notes!),
        ],
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: Theme.of(context).textTheme.bodyLarge),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteTransaction(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Transaction'),
        content: const Text(
          'Are you sure you want to delete this transaction?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final repository = ref.read(transactionRepositoryProvider);
        await repository.deleteTransaction(transaction.id);
        if (context.mounted) {
          ErrorSnackbar.showSuccess(context, 'Transaction deleted');
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (context.mounted) {
          ErrorSnackbar.show(context, 'Failed to delete transaction: $e');
        }
      }
    }
  }
}
