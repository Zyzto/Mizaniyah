import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import '../providers/account_providers.dart';
import '../providers/card_providers.dart';
import '../widgets/account_item.dart';
import '../widgets/account_card.dart';
import '../widgets/sms_patterns_tab.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/loading_skeleton.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/navigation/route_paths.dart';

class AccountsPage extends ConsumerStatefulWidget {
  final TabController tabController;

  const AccountsPage({
    super.key,
    required this.tabController,
  });

  @override
  ConsumerState<AccountsPage> createState() => _AccountsPageState();
}

class _AccountsPageState extends ConsumerState<AccountsPage> {

  @override
  Widget build(BuildContext context) {
    return TabBarView(
      controller: widget.tabController,
      children: [
        _buildAccountsTab(),
        const SmsPatternsTab(),
      ],
    );
  }

  Widget _buildAccountsTab() {
    final accountsAsync = ref.watch(accountsProvider);
    final cardsWithoutAccountAsync = ref.watch(cardsByAccountProvider(null));

    return accountsAsync.when(
      data: (accounts) {
        return cardsWithoutAccountAsync.when(
          data: (cardsWithoutAccount) {
            final hasAccounts = accounts.isNotEmpty;
            final hasCardsWithoutAccount = cardsWithoutAccount.isNotEmpty;
            final isEmpty = !hasAccounts && !hasCardsWithoutAccount;

            return Stack(
              children: [
                if (isEmpty)
                  EmptyState(
                    icon: Icons.account_balance_wallet_outlined,
                    title: 'no_accounts'.tr(),
                    subtitle: 'add_first_account'.tr(),
                    actionLabel: 'add_account'.tr(),
                    onAction: _navigateToAddAccount,
                  )
                else
                  ListView(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    children: [
                      // Accounts with cards
                      ...accounts.map((account) => AccountItem(
                            account: account,
                            onAccountTap: () {
                              HapticFeedback.lightImpact();
                              context.push('/accounts/${account.id}/edit');
                            },
                            onAddCard: () {
                              HapticFeedback.lightImpact();
                              context.push('/accounts/${account.id}/card/add');
                            },
                          )),
                      // Cards without account
                      if (hasCardsWithoutAccount) ...[
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                          child: Text(
                            'cards_without_account'.tr(),
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ),
                        ...cardsWithoutAccount.map((card) {
                          final cardStatsAsync = ref.watch(cardStatisticsProvider(card.id));
                          return cardStatsAsync.when(
                            data: (stats) => AccountCard(
                              card: card,
                              transactionCount: stats.count,
                              totalSpent: stats.total,
                              onTap: () {
                                HapticFeedback.lightImpact();
                                context.push('/accounts/card/${card.id}/edit');
                              },
                            ),
                            loading: () => const CardSkeleton(),
                            error: (error, stack) => ErrorState(
                              title: 'error_loading_card_stats'.tr(),
                              message: error.toString(),
                              onRetry: () => ref.invalidate(cardStatisticsProvider(card.id)),
                            ),
                          );
                        }),
                      ],
                    ],
                  ),
                if (!isEmpty)
                  Positioned(
                    bottom: 100, // Position above floating nav bar
                    right: 16,
                    child: SafeArea(
                      child: FloatingActionButton(
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          _navigateToAddAccount();
                        },
                        tooltip: 'add_account'.tr(),
                        child: const Icon(Icons.add),
                      ),
                    ),
                  ),
              ],
            );
          },
          loading: () => const SkeletonList(itemCount: 3, itemHeight: 120),
          error: (error, stack) => ErrorState(
            title: 'error_loading_cards'.tr(),
            message: error.toString(),
            onRetry: () => ref.invalidate(cardsByAccountProvider(null)),
          ),
        );
      },
      loading: () => const SkeletonList(itemCount: 3, itemHeight: 120),
      error: (error, stack) => ErrorState(
        title: 'error_loading_accounts'.tr(),
        message: error.toString(),
        onRetry: () => ref.invalidate(accountsProvider),
      ),
    );
  }

  void _navigateToAddAccount() {
    context.push(RoutePaths.accountsAdd);
  }
}
