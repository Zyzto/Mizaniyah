import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import '../providers/budget_providers.dart';
import '../../categories/providers/category_providers.dart';
import '../../categories/widgets/categories_tab.dart';
import '../widgets/budget_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/loading_skeleton.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/navigation/route_paths.dart';

class BudgetsPage extends ConsumerStatefulWidget {
  final TabController tabController;

  const BudgetsPage({super.key, required this.tabController});

  @override
  ConsumerState<BudgetsPage> createState() => _BudgetsPageState();
}

class _BudgetsPageState extends ConsumerState<BudgetsPage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    widget.tabController.addListener(_onTabChanged);
  }

  @override
  void dispose() {
    widget.tabController.removeListener(_onTabChanged);
    super.dispose();
  }

  void _onTabChanged() {
    setState(() {}); // Rebuild to update FAB visibility
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    final currentTabIndex = widget.tabController.index;

    return Stack(
      children: [
        TabBarView(
          controller: widget.tabController,
          children: [_buildBudgetsTab(), const CategoriesTab()],
        ),
        // FAB for budgets tab
        if (currentTabIndex == 0)
          ...(_buildBudgetsFab() != null ? [_buildBudgetsFab()!] : []),
        // FAB for categories tab
        if (currentTabIndex == 1)
          ...(_buildCategoriesFab() != null ? [_buildCategoriesFab()!] : []),
      ],
    );
  }

  Widget _buildBudgetsTab() {
    final budgetsAsync = ref.watch(activeBudgetsProvider);

    return budgetsAsync.when(
      data: (budgets) {
        if (budgets.isEmpty) {
          return EmptyState(
            icon: Icons.account_balance_outlined,
            title: 'no_budgets'.tr(),
            subtitle: 'create_budget'.tr(),
            actionLabel: 'add_budget'.tr(),
            onAction: _navigateToAddBudget,
          );
        }

        return ListView.builder(
          itemCount: budgets.length,
          itemBuilder: (context, index) {
            final budget = budgets[index];
            return BudgetCard(
              budget: budget,
              onTap: () {
                HapticFeedback.lightImpact();
                context.push(RoutePaths.budgetEdit(budget.id));
              },
            );
          },
        );
      },
      loading: () => const SkeletonList(itemCount: 3, itemHeight: 140),
      error: (error, stack) => ErrorState(
        title: 'error_loading_budgets'.tr(),
        message: error.toString(),
        onRetry: () => ref.invalidate(activeBudgetsProvider),
      ),
    );
  }

  Widget? _buildBudgetsFab() {
    final budgetsAsync = ref.watch(activeBudgetsProvider);

    return budgetsAsync.maybeWhen(
      data: (budgets) {
        if (budgets.isEmpty) return null; // Hide FAB when empty

        return PositionedDirectional(
          bottom: -8, // Position above floating nav bar
          end: 16,
          child: SafeArea(
            child: FloatingActionButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                _navigateToAddBudget();
              },
              tooltip: 'add_budget'.tr(),
              child: const Icon(Icons.add),
            ),
          ),
        );
      },
      orElse: () => null,
    );
  }

  Widget? _buildCategoriesFab() {
    final categoriesAsync = ref.watch(categoriesProvider);

    return categoriesAsync.maybeWhen(
      data: (categories) {
        if (categories.isEmpty) return null; // Hide FAB when empty

        return PositionedDirectional(
          bottom: -8, // Position above floating nav bar
          end: 16,
          child: SafeArea(
            child: FloatingActionButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                context.push(RoutePaths.categoriesAdd);
              },
              tooltip: 'add_category_action'.tr(),
              child: const Icon(Icons.add),
            ),
          ),
        );
      },
      orElse: () => null,
    );
  }

  void _navigateToAddBudget() {
    context.push(RoutePaths.budgetsAdd);
  }
}
