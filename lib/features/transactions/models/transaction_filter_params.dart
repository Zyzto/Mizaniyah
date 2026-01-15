/// Non-nullable filter parameters for transactions
/// Used for Riverpod code generation compatibility (family providers don't support nullable params)
class TransactionFilterParams {
  final int categoryId; // Use -1 for "no filter"
  final String searchQuery; // Use empty string for "no filter"

  const TransactionFilterParams({
    required this.categoryId,
    required this.searchQuery,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransactionFilterParams &&
          runtimeType == other.runtimeType &&
          categoryId == other.categoryId &&
          searchQuery == other.searchQuery;

  @override
  int get hashCode => Object.hash(categoryId, searchQuery);
}
