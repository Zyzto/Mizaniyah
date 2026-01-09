import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../export_service.dart';
import '../../../features/transactions/providers/transaction_providers.dart';
import '../../../features/budgets/providers/budget_providers.dart';

final exportServiceProvider = Provider<ExportService>((ref) {
  final transactionRepository = ref.watch(transactionRepositoryProvider);
  final budgetRepository = ref.watch(budgetRepositoryProvider);
  return ExportService(transactionRepository, budgetRepository);
});
