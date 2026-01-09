import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../transactions/providers/transaction_providers.dart';
import '../../banks/providers/bank_providers.dart';
import '../../budgets/providers/budget_providers.dart';
import '../widgets/account_card.dart';
import '../widgets/budget_card.dart';
import '../../banks/pages/bank_form_page.dart' as bank_form;
import '../../budgets/pages/budget_form_page.dart';
import 'account_form_page.dart';

class AccountsPage extends ConsumerStatefulWidget {
  const AccountsPage({super.key});

  @override
  ConsumerState<AccountsPage> createState() => _AccountsPageState();
}

class _AccountsPageState extends ConsumerState<AccountsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Accounts & Budget'),
        automaticallyImplyLeading: false,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(
              icon: Icon(Icons.account_balance_wallet_outlined),
              text: 'Accounts',
            ),
            Tab(icon: Icon(Icons.account_balance_outlined), text: 'Budgets'),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'add_account') {
                _navigateToAddAccount();
              } else if (value == 'add_bank') {
                _navigateToAddBank();
              } else if (value == 'add_budget') {
                _navigateToAddBudget();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'add_account',
                child: Row(
                  children: [
                    Icon(Icons.credit_card),
                    SizedBox(width: 8),
                    Text('Add Account'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'add_bank',
                child: Row(
                  children: [
                    Icon(Icons.account_balance),
                    SizedBox(width: 8),
                    Text('Add Bank'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'add_budget',
                child: Row(
                  children: [
                    Icon(Icons.account_balance_wallet),
                    SizedBox(width: 8),
                    Text('Add Budget'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildAccountsTab(), _buildBudgetsTab()],
      ),
    );
  }

  Widget _buildAccountsTab() {
    final cardsAsync = ref.watch(allCardsProvider);
    final transactionsAsync = ref.watch(transactionsProvider);
    final banksAsync = ref.watch(banksProvider);

    return cardsAsync.when(
      data: (cards) {
        if (cards.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.account_balance_wallet_outlined,
                  size: 64,
                  color: Theme.of(context).colorScheme.outline,
                ),
                const SizedBox(height: 16),
                Text(
                  'No accounts yet',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Add your first account to get started',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          );
        }

        return transactionsAsync.when(
          data: (transactions) {
            return banksAsync.when(
              data: (banks) {
                final bankMap = {for (var bank in banks) bank.id: bank};

                return ListView.builder(
                  itemCount: cards.length,
                  itemBuilder: (context, index) {
                    final card = cards[index];
                    final bank = bankMap[card.bankId];
                    final cardTransactions = transactions
                        .where((t) => t.cardId == card.id)
                        .toList();
                    final totalSpent = cardTransactions.fold<double>(
                      0.0,
                      (sum, t) => sum + t.amount,
                    );

                    return AccountCard(
                      card: card,
                      bank: bank,
                      transactionCount: cardTransactions.length,
                      totalSpent: totalSpent,
                      onTap: () {
                        // Navigate to edit account
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => AccountFormPage(card: card),
                          ),
                        );
                      },
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) =>
                  const Center(child: Text('Error loading banks')),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) =>
              Center(child: Text('Error loading transactions: $error')),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
    );
  }

  Widget _buildBudgetsTab() {
    final budgetsAsync = ref.watch(activeBudgetsProvider);

    return budgetsAsync.when(
      data: (budgets) {
        if (budgets.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.account_balance_outlined,
                  size: 64,
                  color: Theme.of(context).colorScheme.outline,
                ),
                const SizedBox(height: 16),
                Text(
                  'No budgets yet',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Create a budget to track your spending',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: budgets.length,
          itemBuilder: (context, index) {
            final budget = budgets[index];
            return BudgetCard(
              budget: budget,
              onTap: () {
                // Navigate to edit budget
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => BudgetFormPage(budget: budget),
                  ),
                );
              },
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
    );
  }

  void _navigateToAddAccount() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const AccountFormPage()));
  }

  void _navigateToAddBank() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const bank_form.BankFormPage()),
    );
  }

  void _navigateToAddBudget() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const BudgetFormPage()));
  }
}
