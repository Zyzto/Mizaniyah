import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import '../providers/transaction_providers.dart';
import '../widgets/transaction_card.dart';
import '../widgets/category_filter.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/loading_skeleton.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/utils/debouncer.dart';
import '../../../core/database/app_database.dart' as db;

class TransactionsListPage extends ConsumerStatefulWidget {
  const TransactionsListPage({super.key});

  @override
  ConsumerState<TransactionsListPage> createState() =>
      _TransactionsListPageState();
}

class _TransactionsListPageState extends ConsumerState<TransactionsListPage> {
  String _debouncedSearchQuery = '';
  int? _selectedCategoryId;
  late final Debouncer _searchDebouncer;

  @override
  void initState() {
    super.initState();
    _searchDebouncer = Debouncer(delay: const Duration(milliseconds: 500));
  }

  @override
  void dispose() {
    _searchDebouncer.dispose();
    super.dispose();
  }

  // Memoize filter object to prevent unnecessary provider rebuilds
  TransactionFilters _getFilters(String searchQuery) => TransactionFilters(
        categoryId: _selectedCategoryId,
        searchQuery: searchQuery.isEmpty ? null : searchQuery,
      );

  @override
  Widget build(BuildContext context) {
    // Watch search query from provider and debounce it
    final searchQuery = ref.watch(transactionSearchQueryProvider);
    if (searchQuery != _debouncedSearchQuery) {
      _searchDebouncer.call(() {
        if (mounted) {
          setState(() {
            _debouncedSearchQuery = searchQuery;
          });
        }
      });
    }

    // Use filtered provider instead of loading all transactions
    final transactionsAsync = ref.watch(
      filteredTransactionsProvider(_getFilters(_debouncedSearchQuery)),
    );

    return Column(
      children: [
        // Category filter
        CategoryFilter(
          selectedCategoryId: _selectedCategoryId,
          onCategorySelected: (categoryId) {
            setState(() {
              _selectedCategoryId = categoryId;
            });
          },
        ),
        // Transactions list
        Expanded(
          child: transactionsAsync.when(
            data: (transactions) {
              // Transactions are already filtered and sorted by the database query
              if (transactions.isEmpty) {
                // Determine if filters are active
                final hasFilters = _selectedCategoryId != null ||
                    (_debouncedSearchQuery.isNotEmpty);
                return EmptyState(
                  icon: Icons.receipt_long_outlined,
                  title: hasFilters
                      ? 'no_transactions_filtered'.tr()
                      : 'no_transactions'.tr(),
                  subtitle: hasFilters
                      ? null
                      : 'add_first_transaction'.tr(),
                  actionLabel: hasFilters
                      ? null
                      : 'add_transaction'.tr(),
                  onAction: hasFilters
                      ? null
                      : _navigateToAdd,
                );
              }

              return ListView.builder(
                itemCount: transactions.length,
                itemBuilder: (context, index) {
                  final transaction = transactions[index];
                  return TransactionCard(
                    transaction: transaction,
                    onTap: () => _navigateToDetail(transaction),
                  );
                },
              );
            },
            loading: () => const SkeletonList(itemCount: 5, itemHeight: 100),
            error: (error, stack) => ErrorState(
              title: 'error_loading_transactions'.tr(),
              message: error.toString(),
              onRetry: () {
                // Force provider refresh
                ref.invalidate(
                  filteredTransactionsProvider(_getFilters(_debouncedSearchQuery)),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  void _navigateToAdd() {
    context.push('/transactions/add');
  }

  void _navigateToDetail(db.Transaction transaction) {
    context.push('/transactions/${transaction.id}');
  }

}
