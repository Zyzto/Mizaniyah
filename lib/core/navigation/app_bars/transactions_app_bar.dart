import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../features/transactions/providers/transaction_providers.dart';
import '../../../core/services/providers/export_providers.dart';
import '../../../core/widgets/error_snackbar.dart';
import '../../../core/navigation/route_paths.dart';
import '../transaction_search_delegate.dart';

/// AppBar for the transactions page
PreferredSizeWidget buildTransactionsAppBar(
  BuildContext context,
  WidgetRef ref, {
  required String location,
}) {
  final searchQuery = ref.watch(transactionSearchQueryProvider);
  final searchNotifier = ref.read(transactionSearchQueryProvider.notifier);

  // Only show actions on the main transactions page (not sub-routes)
  final isMainPage = location == RoutePaths.transactions;

  return AppBar(
    automaticallyImplyLeading: false,
    title: const SizedBox.shrink(),
    actions: isMainPage
        ? [
            IconButton(
              icon: const Icon(Icons.category_outlined),
              tooltip: 'categories'.tr(),
              onPressed: () {
                HapticFeedback.lightImpact();
                context.push(RoutePaths.categories);
              },
            ),
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
            PopupMenuButton<String>(
              onSelected: (value) {
                HapticFeedback.lightImpact();
                if (value == 'export_transactions') {
                  _exportTransactions(context, ref);
                } else if (value == 'export_all') {
                  _exportAll(context, ref);
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'export_transactions',
                  child: Row(
                    children: [
                      const Icon(Icons.file_download),
                      const SizedBox(width: 8),
                      Text('export_transactions'.tr()),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'export_all',
                  child: Row(
                    children: [
                      const Icon(Icons.download),
                      const SizedBox(width: 8),
                      Text('export_all'.tr()),
                    ],
                  ),
                ),
              ],
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

Future<void> _exportTransactions(BuildContext context, WidgetRef ref) async {
  try {
    final exportService = ref.read(exportServiceProvider);
    final filePath = await exportService.exportTransactionsToCsv();

    if (!context.mounted) return;
    if (filePath != null) {
      ErrorSnackbar.showSuccess(context, 'exported_successfully'.tr());
    } else {
      ErrorSnackbar.show(context, 'export_failed'.tr());
    }
  } catch (e) {
    if (!context.mounted) return;
    ErrorSnackbar.show(context, 'export_failed'.tr());
  }
}

Future<void> _exportAll(BuildContext context, WidgetRef ref) async {
  try {
    final exportService = ref.read(exportServiceProvider);
    final results = await exportService.exportAll();

    if (!context.mounted) return;
    final transactionsPath = results['transactions'];
    final budgetsPath = results['budgets'];

    if (transactionsPath != null || budgetsPath != null) {
      ErrorSnackbar.showSuccess(context, 'exported_successfully'.tr());
    } else {
      ErrorSnackbar.show(context, 'export_failed'.tr());
    }
  } catch (e) {
    if (!context.mounted) return;
    ErrorSnackbar.show(context, 'export_failed'.tr());
  }
}
