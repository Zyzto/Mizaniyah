import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';

/// Search delegate for transaction search
class TransactionSearchDelegate extends SearchDelegate {
  final ValueChanged<String> onQueryChanged;
  final String initialQuery;

  TransactionSearchDelegate({
    required this.onQueryChanged,
    this.initialQuery = '',
  }) : super(searchFieldLabel: 'search'.tr());

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          HapticFeedback.lightImpact();
          query = '';
        },
        tooltip: 'clear_search'.tr(),
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        HapticFeedback.lightImpact();
        close(context, null);
      },
      tooltip: 'back'.tr(),
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
