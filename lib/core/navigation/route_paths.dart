/// Route path constants for the application
/// All route paths should be defined here to ensure consistency
class RoutePaths {
  // Main tabs
  static const String home = '/home';
  static const String accounts = '/accounts';
  static const String budget = '/budget';
  
  // Legacy/alias for backward compatibility
  static const String transactions = '/home'; // Home defaults to transactions
  static const String smsNotifications = '/accounts'; // SMS Templates is in Accounts tab

  // Transactions
  static const String transactionsAdd = '/transactions/add';
  static String transactionDetail(int id) => '/transactions/$id';
  static String transactionEdit(int id) => '/transactions/$id/edit';

  // Categories
  static const String categories = '/categories';
  static const String categoriesAdd = '/categories/add';
  static String categoryEdit(int id) => '/categories/$id/edit';

  // Accounts
  static const String accountsAdd = '/accounts/add';
  static String accountEdit(int id) => '/accounts/$id/edit';

  // Budgets
  static const String budgetsAdd = '/budgets/add';
  static String budgetEdit(int id) => '/budgets/$id/edit';

  // Settings
  static const String settings = '/settings';

  // Statistics
  static const String statistics = '/statistics';

  // Banks
  static const String banks = '/banks';
  static const String smsTemplateBuilder = '/banks/sms-template-builder';
  static const String smsTemplatePage = '/banks/sms-template';
  static const String smsReader = '/banks/sms-reader';
  static const String smsTemplateForm = '/banks/sms-template-form';
  static String smsTemplateEdit(int id) => '/banks/sms-template/$id/edit';

  // Helper methods to extract IDs from paths
  static int? extractTransactionId(String path) {
    final match = RegExp(r'/transactions/(\d+)').firstMatch(path);
    return match != null ? int.tryParse(match.group(1)!) : null;
  }

  static int? extractCategoryId(String path) {
    final match = RegExp(r'/categories/(\d+)').firstMatch(path);
    return match != null ? int.tryParse(match.group(1)!) : null;
  }

  static int? extractAccountId(String path) {
    final match = RegExp(r'/accounts/(\d+)').firstMatch(path);
    return match != null ? int.tryParse(match.group(1)!) : null;
  }

  static int? extractBudgetId(String path) {
    final match = RegExp(r'/budgets/(\d+)').firstMatch(path);
    return match != null ? int.tryParse(match.group(1)!) : null;
  }

  static int? extractSmsTemplateId(String path) {
    final match = RegExp(r'/banks/sms-template/(\d+)/edit').firstMatch(path);
    return match != null ? int.tryParse(match.group(1)!) : null;
  }
}
