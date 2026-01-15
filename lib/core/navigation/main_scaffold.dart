import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../features/accounts/pages/accounts_page.dart';
import '../../features/budgets/pages/budgets_page.dart';
import '../../features/home/pages/home_page.dart';
import '../../core/widgets/floating_nav_bar.dart';
import '../../features/transactions/providers/transaction_providers.dart';
import '../../features/accounts/providers/account_providers.dart';
import '../../features/budgets/providers/budget_providers.dart';
import '../../features/categories/providers/category_providers.dart';
import '../../features/sms_templates/providers/sms_template_providers.dart';
import '../../core/services/provider_cache_warming_service.dart';
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
  
  // Keep track of the three main pages to maintain their state
  final _homePage = const HomePage();
  AccountsPage? _accountsPage;
  BudgetsPage? _budgetsPage;
  
  // Track current index for IndexedStack
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.selectedIndex;
    _initializePages();
    _updateTabControllers();
    // Warm up all providers early for better performance
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ProviderCacheWarmingService.warmUpProviders(ref);
        _prefetchAdjacentScreens(widget.selectedIndex);
      }
    });
  }
  
  /// Initialize all main pages early to start loading data
  void _initializePages() {
    // Always create controllers and pages for all three main tabs
    // This ensures data starts loading immediately
    _accountsTabController ??= TabController(length: 2, vsync: this);
    _budgetTabController ??= TabController(length: 2, vsync: this);
    _accountsPage ??= AccountsPage(tabController: _accountsTabController!);
    _budgetsPage ??= BudgetsPage(tabController: _budgetTabController!);
  }

  @override
  void didUpdateWidget(MainScaffold oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.location != widget.location) {
      _updateTabControllers();
    }
    if (oldWidget.selectedIndex != widget.selectedIndex) {
      _currentIndex = widget.selectedIndex;
      // Prefetch data for adjacent screens when switching tabs
      _prefetchAdjacentScreens(widget.selectedIndex);
    }
  }
  
  /// Prefetch data for adjacent screens to avoid skeleton flashing
  /// This ensures data starts loading before the user navigates to adjacent screens
  /// Uses a smarter approach: actually watch providers briefly to start streams,
  /// then let IndexedStack maintain the watch
  void _prefetchAdjacentScreens(int currentIndex) {
    if (!mounted) return;
    
    // Use a post-frame callback to avoid blocking the UI
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      
      // Prefetch providers for adjacent screens
      // For StreamProviders: ref.read() gets current state, but we need to ensure
      // the stream is actually started. The IndexedStack pages will maintain the watch.
      // For FutureProviders: ref.read() triggers the future if not already started
      switch (currentIndex) {
        case 0: // Home - prefetch Accounts and Budget
          // Trigger providers to start loading (if not already)
          // These will be watched by the IndexedStack pages, ensuring streams start
          ref.read(accountsProvider);
          ref.read(cardsByAccountProvider(null));
          ref.read(activeBudgetsProvider);
          ref.read(categoriesProvider);
          // Also prefetch SMS-related providers for Accounts tab
          ref.read(smsTemplatesProvider);
          ref.read(pendingSmsConfirmationsProvider);
          break;
        case 1: // Accounts - prefetch Home and Budget
          ref.read(transactionsProvider);
          ref.read(activeBudgetsProvider);
          ref.read(categoriesProvider);
          break;
        case 2: // Budget - prefetch Home and Accounts
          ref.read(transactionsProvider);
          ref.read(accountsProvider);
          ref.read(cardsByAccountProvider(null));
          // Also prefetch SMS-related providers for Accounts tab
          ref.read(smsTemplatesProvider);
          ref.read(pendingSmsConfirmationsProvider);
          break;
      }
    });
  }

  void _updateTabControllers() {
    // Controllers are now always created in initState
    // No need to dispose them as they're kept alive for IndexedStack
    // This ensures smooth navigation without rebuilding
  }

  @override
  void dispose() {
    _accountsTabController?.dispose();
    _budgetTabController?.dispose();
    super.dispose();
  }

  /// Check if navigation bar should be visible
  /// Only show on the 3 main pages: Home, Accounts, Budget
  bool _shouldShowNavBar() {
    final location = widget.location;
    // Only show nav bar on exact main page routes (not sub-routes)
    return location == RoutePaths.home ||
        location == RoutePaths.accounts ||
        location == RoutePaths.budget;
  }

  @override
  Widget build(BuildContext context) {
    // Ensure pages are initialized
    _initializePages();

    // Watch transactions to determine if FAB should be shown
    final transactionsAsync = ref.watch(transactionsProvider);
    final hasTransactions = transactionsAsync.maybeWhen(
      data: (transactions) => transactions.isNotEmpty,
      orElse: () => false,
    );
    // Show FAB on home page (which shows transactions by default)
    final showFab =
        (widget.location.startsWith(RoutePaths.home) ||
            widget.location.startsWith(RoutePaths.transactions)) &&
        hasTransactions;

    final showNavBar = _shouldShowNavBar();

    return Scaffold(
      appBar: _buildAppBar(context, ref),
      body: Stack(
        children: [
          // Main content with bottom padding for floating nav bar (only if nav bar is visible)
          Padding(
            padding: EdgeInsets.only(bottom: showNavBar ? 100 : 0),
            child: _buildMainContent(),
          ),
          // Floating navigation bar - only show on 3 main pages
          if (showNavBar)
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
            PositionedDirectional(
              end: 16,
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

  /// Build main content using IndexedStack to keep all pages alive
  /// This is the key optimization that prevents skeleton flashing:
  /// - All three main pages are kept alive in memory
  /// - Pages maintain their state and scroll position
  /// - Data providers are already loaded when switching tabs
  Widget _buildMainContent() {
    // For main navigation pages (home, accounts, budget), use IndexedStack
    // to keep all pages alive and avoid skeleton flashing
    final isMainPage = widget.location == RoutePaths.home ||
        widget.location == RoutePaths.accounts ||
        widget.location == RoutePaths.budget;
    
    if (isMainPage) {
      // Use IndexedStack to keep all three main pages alive
      // This prevents rebuilding and skeleton flashing when switching tabs
      // The pages are built once and maintained in memory
      return IndexedStack(
        index: _currentIndex,
        children: [
          // Home page (index 0) - shows transactions
          _homePage,
          // Accounts page (index 1) - shows accounts and SMS templates
          _accountsPage!,
          // Budget page (index 2) - shows budgets and categories
          _budgetsPage!,
        ],
      );
    }
    
    // For other routes (settings, statistics, form pages, etc.), use the child directly
    // This allows GoRouter to handle sub-routes normally without IndexedStack
    return widget.child;
  }

  PreferredSizeWidget? _buildAppBar(BuildContext context, WidgetRef ref) {
    if (widget.location.startsWith(RoutePaths.home) ||
        widget.location.startsWith(RoutePaths.transactions)) {
      return buildHomeAppBar(context, ref, location: widget.location);
    } else if (widget.location.startsWith(RoutePaths.accounts)) {
      return buildAccountsAppBar(
        context,
        ref,
        _accountsTabController,
        location: widget.location,
      );
    } else if (widget.location.startsWith(RoutePaths.budget)) {
      return buildBudgetAppBar(
        context,
        ref,
        _budgetTabController,
        location: widget.location,
      );
    }
    return null;
  }
}
