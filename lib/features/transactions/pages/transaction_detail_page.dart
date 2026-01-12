import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../categories/providers/category_providers.dart';
import '../../accounts/providers/card_providers.dart';
import '../../../core/database/app_database.dart' as db;
import '../../../core/database/providers/dao_providers.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/category_translations.dart';
import '../../../core/widgets/error_snackbar.dart';

class TransactionDetailPage extends ConsumerWidget {
  final db.Transaction transaction;

  const TransactionDetailPage({super.key, required this.transaction});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');

    return Scaffold(
      appBar: AppBar(
        title: Text('transaction_details'.tr()),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'edit'.tr(),
            onPressed: () {
              HapticFeedback.lightImpact();
              context.push('/transactions/${transaction.id}/edit');
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            tooltip: 'delete'.tr(),
            onPressed: () {
              HapticFeedback.mediumImpact();
              _deleteTransaction(context, ref);
            },
            color: colorScheme.error,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.storeName,
                    style: theme.textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    CurrencyFormatter.format(
                      transaction.amount,
                      transaction.currencyCode,
                    ),
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildDetailRow(
            context,
            'date'.tr(),
            dateFormat.format(transaction.date),
          ),
          if (transaction.cardId != null)
            _buildCardDetail(context, ref, transaction.cardId!),
          if (transaction.categoryId != null)
            _buildCategoryDetail(context, ref, transaction.categoryId!),
          _buildDetailRow(
            context,
            'source'.tr(),
            transaction.source == 'sms' ? 'sms'.tr() : 'manual'.tr(),
          ),
          if (transaction.notes != null && transaction.notes!.isNotEmpty)
            _buildDetailRow(
              context,
              'notes_optional'.tr(),
              transaction.notes!,
            ),
        ],
      ),
    );
  }

  Widget _buildCardDetail(BuildContext context, WidgetRef ref, int cardId) {
    final cardsAsync = ref.watch(allCardsProvider);
    return cardsAsync.when(
      data: (cards) {
        final card = cards.firstWhere(
          (c) => c.id == cardId,
          orElse: () => throw StateError('Card not found'),
        );
        return _buildDetailRow(
          context,
          'card'.tr(),
          '${card.cardName} (****${card.last4Digits})',
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }

  Widget _buildCategoryDetail(BuildContext context, WidgetRef ref, int categoryId) {
    final categoryAsync = ref.watch(categoryProvider(categoryId));
    return categoryAsync.when(
      data: (category) {
        if (category == null) return const SizedBox.shrink();
        return _buildDetailRow(
          context,
          'category'.tr(),
          CategoryTranslations.getTranslatedName(category),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyLarge,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteTransaction(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('delete_transaction'.tr()),
        content: Text('delete_transaction_confirmation'.tr()),
        actions: [
          TextButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.of(context).pop(false);
            },
            child: Text('cancel'.tr()),
          ),
          TextButton(
            onPressed: () {
              HapticFeedback.mediumImpact();
              Navigator.of(context).pop(true);
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text('delete'.tr()),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final dao = ref.read(transactionDaoProvider);
        await dao.deleteTransaction(transaction.id);
        if (context.mounted) {
          HapticFeedback.heavyImpact();
          ErrorSnackbar.showSuccess(context, 'transaction_deleted'.tr());
          context.pop();
        }
      } catch (e) {
        if (context.mounted) {
          HapticFeedback.heavyImpact();
          ErrorSnackbar.show(
            context,
            'transaction_delete_failed'.tr(args: [e.toString()]),
          );
        }
      }
    }
  }
}
