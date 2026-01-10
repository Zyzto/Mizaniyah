import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/navigation/route_paths.dart';

/// AppBar for the accounts page
PreferredSizeWidget buildAccountsAppBar(
  BuildContext context,
  WidgetRef ref,
  TabController? tabController, {
  required String location,
}) {
  // Only show actions on the main accounts page (not sub-routes)
  final isMainPage = location == RoutePaths.accounts;

  return AppBar(
    automaticallyImplyLeading: false,
    title: const SizedBox.shrink(),
    toolbarHeight: 0,
    bottom: isMainPage ? TabBar(
      controller: tabController,
      tabs: [
        Tab(
          icon: const Icon(Icons.account_balance_wallet_outlined),
          text: 'accounts'.tr(),
        ),
        Tab(
          icon: const Icon(Icons.pattern_outlined),
          text: 'sms_patterns'.tr(),
        ),
      ],
    ) : null,
    actions: [],
  );
}
