import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/database/app_database.dart' as db;
import '../providers/account_providers.dart';
import '../providers/card_providers.dart';
import '../../../core/widgets/loading_skeleton.dart';
import 'card_item.dart';

class AccountItem extends ConsumerStatefulWidget {
  final db.Account account;
  final VoidCallback? onAccountTap;
  final VoidCallback? onAddCard;

  const AccountItem({
    super.key,
    required this.account,
    this.onAccountTap,
    this.onAddCard,
  });

  @override
  ConsumerState<AccountItem> createState() => _AccountItemState();
}

class _AccountItemState extends ConsumerState<AccountItem> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final cardsAsync = ref.watch(cardsByAccountStreamProvider(widget.account.id));
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.account_balance_wallet),
            title: Text(widget.account.name),
            subtitle: cardsAsync.when(
              data: (cards) => Text(
                cards.isEmpty
                    ? 'no_cards'.tr()
                    : 'cards_count'.tr(args: [cards.length.toString()]),
              ),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.add_card),
                  tooltip: 'add_card'.tr(),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    widget.onAddCard?.call();
                  },
                ),
                IconButton(
                  icon: Icon(_isExpanded ? Icons.expand_less : Icons.expand_more),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    setState(() {
                      _isExpanded = !_isExpanded;
                    });
                  },
                ),
              ],
            ),
            onTap: () {
              HapticFeedback.lightImpact();
              widget.onAccountTap?.call();
            },
          ),
          if (_isExpanded)
            cardsAsync.when(
              data: (cards) {
                if (cards.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: Center(
                      child: Text(
                        'no_cards_in_account'.tr(),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  );
                }
                return Column(
                  children: cards.map((card) {
                    final cardStatsAsync = ref.watch(cardStatisticsProvider(card.id));
                    return cardStatsAsync.when(
                      data: (stats) => CardItem(
                        card: card,
                        transactionCount: stats.count,
                        totalSpent: stats.total,
                        onTap: () {
                          HapticFeedback.lightImpact();
                          context.push('/accounts/card/${card.id}/edit');
                        },
                      ),
                      loading: () => const CardSkeleton(),
                      error: (error, stack) => const SizedBox.shrink(),
                    );
                  }).toList(),
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
              error: (error, stack) => Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'error_loading_cards'.tr(),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
