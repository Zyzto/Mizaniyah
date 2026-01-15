import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../services/budget_service.dart';
import '../../database/providers/dao_providers.dart';

part 'budget_service_provider.g.dart';

@riverpod
BudgetService budgetService(BudgetServiceRef ref) {
  final budgetDao = ref.watch(budgetDaoProvider);
  final transactionDao = ref.watch(transactionDaoProvider);
  return BudgetService(budgetDao, transactionDao);
}
