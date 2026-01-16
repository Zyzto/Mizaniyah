import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../export_service.dart';
import '../../../core/database/providers/dao_providers.dart';

part 'export_providers.g.dart';

@riverpod
ExportService exportService(Ref ref) {
  final transactionDao = ref.watch(transactionDaoProvider);
  final budgetDao = ref.watch(budgetDaoProvider);
  return ExportService(transactionDao, budgetDao);
}
