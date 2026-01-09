import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import '../providers/transaction_providers.dart';
import '../widgets/transaction_card.dart';
import '../widgets/category_filter.dart';
import '../../../core/services/providers/export_providers.dart';
import '../../statistics/pages/statistics_page.dart';
import 'transaction_form_page.dart';
import 'transaction_detail_page.dart';
import '../../../core/database/app_database.dart' as db;

class TransactionsListPage extends ConsumerStatefulWidget {
  const TransactionsListPage({super.key});

  @override
  ConsumerState<TransactionsListPage> createState() =>
      _TransactionsListPageState();
}

class _TransactionsListPageState extends ConsumerState<TransactionsListPage> {
  String _searchQuery = '';
  int? _selectedCategoryId;

  @override
  Widget build(BuildContext context) {
    final transactionsAsync = ref.watch(transactionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics_outlined),
            tooltip: 'Statistics',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const StatisticsPage()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              showSearch(
                context: context,
                delegate: _TransactionSearchDelegate(
                  onQueryChanged: (query) {
                    setState(() {
                      _searchQuery = query;
                    });
                  },
                ),
              );
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'export_transactions') {
                _exportTransactions();
              } else if (value == 'export_all') {
                _exportAll();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'export_transactions',
                child: Row(
                  children: [
                    Icon(Icons.file_download),
                    SizedBox(width: 8),
                    Text('Export Transactions'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'export_all',
                child: Row(
                  children: [
                    Icon(Icons.download),
                    SizedBox(width: 8),
                    Text('Export All Data'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
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
                // Filter transactions
                var filteredTransactions = transactions;

                // Filter by category
                if (_selectedCategoryId != null) {
                  filteredTransactions = filteredTransactions
                      .where((t) => t.categoryId == _selectedCategoryId)
                      .toList();
                }

                // Filter by search query
                if (_searchQuery.isNotEmpty) {
                  final query = _searchQuery.toLowerCase();
                  filteredTransactions = filteredTransactions
                      .where((t) => t.storeName.toLowerCase().contains(query))
                      .toList();
                }

                // Sort by date (newest first)
                filteredTransactions.sort((a, b) => b.date.compareTo(a.date));

                if (filteredTransactions.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.receipt_long_outlined,
                          size: 64,
                          color: Theme.of(context).colorScheme.outline,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          transactions.isEmpty
                              ? 'No transactions yet'
                              : 'No transactions match your filters',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        if (transactions.isEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Add your first transaction to get started',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ],
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: filteredTransactions.length,
                  itemBuilder: (context, index) {
                    final transaction = filteredTransactions[index];
                    return TransactionCard(
                      transaction: transaction,
                      onTap: () => _navigateToDetail(transaction),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(child: Text('Error: $error')),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAdd,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _navigateToAdd() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const TransactionFormPage()),
    );
  }

  void _navigateToDetail(db.Transaction transaction) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => TransactionDetailPage(transaction: transaction),
      ),
    );
  }

  Future<void> _exportTransactions() async {
    try {
      final exportService = ref.read(exportServiceProvider);
      final filePath = await exportService.exportTransactionsToCsv();

      if (mounted && filePath != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Transactions exported to: $filePath'),
            action: SnackBarAction(
              label: 'Copy Path',
              onPressed: () {
                Clipboard.setData(ClipboardData(text: filePath));
              },
            ),
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to export transactions')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _exportAll() async {
    try {
      final exportService = ref.read(exportServiceProvider);
      final results = await exportService.exportAll();

      if (mounted) {
        final transactionsPath = results['transactions'];
        final budgetsPath = results['budgets'];

        final message = StringBuffer();
        if (transactionsPath != null) {
          message.writeln('Transactions: $transactionsPath');
        }
        if (budgetsPath != null) {
          message.writeln('Budgets: $budgetsPath');
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              message.toString().isEmpty
                  ? 'Export failed'
                  : 'Data exported successfully',
            ),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }
}

class _TransactionSearchDelegate extends SearchDelegate {
  final ValueChanged<String> onQueryChanged;

  _TransactionSearchDelegate({required this.onQueryChanged});

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    onQueryChanged(query);
    close(context, query);
    return const SizedBox.shrink();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return const SizedBox.shrink();
  }
}
