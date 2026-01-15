import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../daos/transaction_dao.dart';
import '../daos/account_dao.dart';
import '../daos/card_dao.dart';
import '../daos/category_dao.dart';
import '../daos/budget_dao.dart';
import '../daos/sms_template_dao.dart';
import '../daos/pending_sms_confirmation_dao.dart';
import '../daos/notification_history_dao.dart';
import 'database_provider.dart';

part 'dao_providers.g.dart';

/// DAO providers - direct access to data layer without repository indirection
@riverpod
TransactionDao transactionDao(TransactionDaoRef ref) {
  final database = ref.watch(databaseProvider);
  return TransactionDao(database);
}

@riverpod
AccountDao accountDao(AccountDaoRef ref) {
  final database = ref.watch(databaseProvider);
  return AccountDao(database);
}

@riverpod
CardDao cardDao(CardDaoRef ref) {
  final database = ref.watch(databaseProvider);
  return CardDao(database);
}

@riverpod
CategoryDao categoryDao(CategoryDaoRef ref) {
  final database = ref.watch(databaseProvider);
  return CategoryDao(database);
}

@riverpod
BudgetDao budgetDao(BudgetDaoRef ref) {
  final database = ref.watch(databaseProvider);
  return BudgetDao(database);
}

@riverpod
SmsTemplateDao smsTemplateDao(SmsTemplateDaoRef ref) {
  final database = ref.watch(databaseProvider);
  return SmsTemplateDao(database);
}

@riverpod
PendingSmsConfirmationDao pendingSmsConfirmationDao(
  PendingSmsConfirmationDaoRef ref,
) {
  final database = ref.watch(databaseProvider);
  return PendingSmsConfirmationDao(database);
}

@riverpod
NotificationHistoryDao notificationHistoryDao(NotificationHistoryDaoRef ref) {
  final database = ref.watch(databaseProvider);
  return NotificationHistoryDao(database);
}
