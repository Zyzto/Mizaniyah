import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../features/accounts/pages/accounts_page.dart';
import '../../features/budgets/pages/budgets_page.dart';
import '../../core/widgets/floating_nav_bar.dart';
import '../../features/transactions/providers/transaction_providers.dart';
import 'route_paths.dart';
import 'app_bars/home_app_bar.dart';
import 'app_bars/accounts_app_bar.dart';
import 'app_bars/budget_app_bar.dart';

/// Main scaffold with bottom navigation bar
class MainScaffold extends ConsumerStatefulWidget {
  final int selectedIndex;
  final String location;
  final Widget child;

  const MainScaffold({
    super.key,
    required this.selectedIndex,
    required this.location,
    required this.child,
  });

  @override
  ConsumerState<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends ConsumerState<MainScaffold>
    with TickerProviderStateMixin {
  TabController? _accountsTabController;
  TabController? _budgetTabController;

  @override
  void initState() {
    super.initState();
    _updateTabControllers();
  }

  @override
  void didUpdateWidget(MainScaffold oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.location != widget.location) {
      _updateTabControllers();
    }
  }

  void _updateTabControllers() {
    // Dispose old controllers only if they're no longer needed
    // Use post-frame callback to ensure widgets have finished using them
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      // Dispose accounts controller if we're not on accounts route
      if (!widget.location.startsWith(RoutePaths.accounts) &&
          _accountsTabController != null) {
        try {
          _accountsTabController!.dispose();
        } catch (e) {
          // Controller might already be disposed, ignore
        }
        _accountsTabController = null;
      }

      // Dispose budget controller if we're not on budget route
      if (!widget.location.startsWith(RoutePaths.budget) &&
          _budgetTabController != null) {
        try {
          _budgetTabController!.dispose();
        } catch (e) {
          // Controller might already be disposed, ignore
        }
        _budgetTabController = null;
      }
    });

    // Create new controllers based on current route
    // Accounts: 2 tabs (Accounts, SMS Patterns)
    if (widget.location.startsWith(RoutePaths.accounts)) {
      if (_accountsTabController == null) {
        _accountsTabController = TabController(length: 2, vsync: this);
      }
    }
    // Budget: 2 tabs (Budgets, Categories)
    if (widget.location.startsWith(RoutePaths.budget)) {
      if (_budgetTabController == null) {
        _budgetTabController = TabController(length: 2, vsync: this);
      }
    }
  }

  @override
  void dispose() {
    _accountsTabController?.dispose();
    _budgetTabController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Ensure controllers exist for current route
    if (widget.location.startsWith(RoutePaths.accounts) &&
        _accountsTabController == null) {
      _accountsTabController = TabController(length: 2, vsync: this);
    }
    if (widget.location.startsWith(RoutePaths.budget) &&
        _budgetTabController == null) {
      _budgetTabController = TabController(length: 2, vsync: this);
    }

    // Watch transactions to determine if FAB should be shown
    final transactionsAsync = ref.watch(transactionsProvider);
    final hasTransactions = transactionsAsync.maybeWhen(
      data: (transactions) => transactions.isNotEmpty,
      orElse: () => false,
    );
    // Show FAB on home page (which shows transactions by default)
    final showFab = (widget.location.startsWith(RoutePaths.home) ||
            widget.location.startsWith(RoutePaths.transactions)) &&
        hasTransactions;

    return Scaffold(
      appBar: _buildAppBar(context, ref),
      body: Stack(
        children: [
          // Main content with bottom padding for floating nav bar
          Padding(
            padding: const EdgeInsets.only(bottom: 100),
            child: widget.location.startsWith(RoutePaths.accounts)
                ? AccountsPage(tabController: _accountsTabController!)
                : widget.location.startsWith(RoutePaths.budget)
                ? BudgetsPage(tabController: _budgetTabController!)
                : widget.child,
          ),
          // Floating navigation bar
          Positioned(
            left: 0,
            right: 0,
            bottom: 16,
            child: FloatingNavBar(
              selectedIndex: widget.selectedIndex,
              onDestinationSelected: (index) {
                switch (index) {
                  case 0:
                    context.go(RoutePaths.home);
                    break;
                  case 1:
                    context.go(RoutePaths.accounts);
                    break;
                  case 2:
                    context.go(RoutePaths.budget);
                    break;
                }
              },
              destinations: [
                FloatingNavDestination(
                  icon: Icons.home_outlined,
                  selectedIcon: Icons.home,
                  label: 'home'.tr(),
                ),
                FloatingNavDestination(
                  icon: Icons.account_balance_wallet_outlined,
                  selectedIcon: Icons.account_balance_wallet,
                  label: 'accounts'.tr(),
                ),
                FloatingNavDestination(
                  icon: Icons.account_balance_outlined,
                  selectedIcon: Icons.account_balance,
                  label: 'budget'.tr(),
                ),
              ],
            ),
          ),
          // Floating Action Button - positioned above nav bar
          // Only show when on transactions route and there are transactions
          if (showFab)
            Positioned(
              right: 16,
              bottom: 100,
              child: SafeArea(
                child: FloatingActionButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    context.push(RoutePaths.transactionsAdd);
                  },
                  tooltip: 'add_transaction'.tr(),
                  child: const Icon(Icons.add),
                ),
              ),
            ),
        ],
      ),
    );
  }

  PreferredSizeWidget? _buildAppBar(BuildContext context, WidgetRef ref) {
    if (widget.location.startsWith(RoutePaths.home) ||
        widget.location.startsWith(RoutePaths.transactions)) {
      return buildHomeAppBar(context, ref, location: widget.location);
    } else if (widget.location.startsWith(RoutePaths.accounts)) {
      return buildAccountsAppBar(context, ref, _accountsTabController, location: widget.location);
    } else if (widget.location.startsWith(RoutePaths.budget)) {
      return buildBudgetAppBar(context, ref, _budgetTabController, location: widget.location);
    }
    return null;
  }
}
