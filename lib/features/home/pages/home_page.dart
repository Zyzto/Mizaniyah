import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../transactions/pages/transactions_list_page.dart';

/// Home page - modular page that defaults to transactions
/// Can be extended to show other content in the future
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Default to transactions view
    // This can be made modular in the future to show different content
    return const TransactionsListPage();
  }
}
