import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import '../route_paths.dart';

/// AppBar for the budget page
PreferredSizeWidget buildBudgetAppBar(
  BuildContext context,
  WidgetRef ref,
  TabController? tabController, {
  required String location,
}) {
  // Only show actions on the main budget page (not sub-routes)
  final isMainPage = location == RoutePaths.budget;

  return AppBar(
    automaticallyImplyLeading: false,
    title: const SizedBox.shrink(),
    toolbarHeight: 0,
    bottom: isMainPage
        ? TabBar(
            controller: tabController,
            tabs: [
              Tab(
                icon: const Icon(Icons.account_balance_outlined),
                text: 'budgets'.tr(),
              ),
              Tab(
                icon: const Icon(Icons.category_outlined),
                text: 'categories'.tr(),
              ),
            ],
          )
        : null,
    actions: const [],
  );
}
