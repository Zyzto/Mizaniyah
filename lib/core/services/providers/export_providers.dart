import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../export_service.dart';
import '../../../core/database/providers/dao_providers.dart';

final exportServiceProvider = Provider<ExportService>((ref) {
  final transactionDao = ref.watch(transactionDaoProvider);
  final budgetDao = ref.watch(budgetDaoProvider);
  return ExportService(transactionDao, budgetDao);
});
