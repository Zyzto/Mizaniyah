import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../daos/transaction_dao.dart';
import '../daos/account_dao.dart';
import '../daos/card_dao.dart';
import '../daos/category_dao.dart';
import '../daos/budget_dao.dart';
import '../daos/sms_template_dao.dart';
import '../daos/pending_sms_confirmation_dao.dart';
import '../daos/notification_history_dao.dart';
import 'database_provider.dart';

/// DAO providers - direct access to data layer without repository indirection
final transactionDaoProvider = Provider<TransactionDao>((ref) {
  final database = ref.watch(databaseProvider);
  return TransactionDao(database);
});

final accountDaoProvider = Provider<AccountDao>((ref) {
  final database = ref.watch(databaseProvider);
  return AccountDao(database);
});

final cardDaoProvider = Provider<CardDao>((ref) {
  final database = ref.watch(databaseProvider);
  return CardDao(database);
});

final categoryDaoProvider = Provider<CategoryDao>((ref) {
  final database = ref.watch(databaseProvider);
  return CategoryDao(database);
});

final budgetDaoProvider = Provider<BudgetDao>((ref) {
  final database = ref.watch(databaseProvider);
  return BudgetDao(database);
});

final smsTemplateDaoProvider = Provider<SmsTemplateDao>((ref) {
  final database = ref.watch(databaseProvider);
  return SmsTemplateDao(database);
});

final pendingSmsConfirmationDaoProvider = Provider<PendingSmsConfirmationDao>((ref) {
  final database = ref.watch(databaseProvider);
  return PendingSmsConfirmationDao(database);
});

final notificationHistoryDaoProvider = Provider<NotificationHistoryDao>((ref) {
  final database = ref.watch(databaseProvider);
  return NotificationHistoryDao(database);
});
