/// Filter parameters for transactions
/// Must be immutable and have proper equality for Riverpod code generation
class TransactionFilters {
  final int? categoryId;
  final String? searchQuery;

  const TransactionFilters({this.categoryId, this.searchQuery});

  TransactionFilters copyWith({int? categoryId, String? searchQuery}) {
    return TransactionFilters(
      categoryId: categoryId ?? this.categoryId,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransactionFilters &&
          runtimeType == other.runtimeType &&
          categoryId == other.categoryId &&
          searchQuery == other.searchQuery;

  @override
  int get hashCode => Object.hash(categoryId, searchQuery);
}
