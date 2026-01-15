import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import '../route_paths.dart';
import '../../../features/transactions/providers/transaction_providers.dart';
import '../transaction_search_delegate.dart';

/// AppBar for the home page (which shows transactions by default)
PreferredSizeWidget buildHomeAppBar(
  BuildContext context,
  WidgetRef ref, {
  required String location,
}) {
  final searchQuery = ref.watch(transactionSearchQueryProvider);
  final searchNotifier = ref.read(transactionSearchQueryProvider.notifier);

  // Only show actions on the main home page (not sub-routes)
  final isMainPage =
      location == RoutePaths.home || location == RoutePaths.transactions;

  return AppBar(
    automaticallyImplyLeading: false,
    title: const SizedBox.shrink(),
    actions: isMainPage
        ? [
            IconButton(
              icon: const Icon(Icons.analytics_outlined),
              tooltip: 'statistics'.tr(),
              onPressed: () {
                HapticFeedback.lightImpact();
                context.push(RoutePaths.statistics);
              },
            ),
            IconButton(
              icon: const Icon(Icons.search),
              tooltip: 'search'.tr(),
              onPressed: () {
                HapticFeedback.lightImpact();
                showSearch(
                  context: context,
                  delegate: TransactionSearchDelegate(
                    initialQuery: searchQuery,
                    onQueryChanged: (query) {
                      searchNotifier.updateQuery(query);
                    },
                  ),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              tooltip: 'settings'.tr(),
              onPressed: () {
                HapticFeedback.lightImpact();
                context.push(RoutePaths.settings);
              },
            ),
          ]
        : [],
  );
}
