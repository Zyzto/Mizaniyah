import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/transactions/providers/transaction_providers.dart';
import '../../features/accounts/providers/account_providers.dart';
import '../../features/budgets/providers/budget_providers.dart';
import '../../features/categories/providers/category_providers.dart';
import '../../features/sms_templates/providers/sms_template_providers.dart';

/// Service to warm up provider cache for better performance
/// This ensures critical data starts loading early, reducing skeleton flashing
class ProviderCacheWarmingService {
  /// Warm up all critical providers for main navigation screens
  /// This should be called early in app lifecycle to start data loading
  static void warmUpProviders(WidgetRef ref) {
    // Warm up providers for all three main tabs
    // This ensures data is loading even before user navigates

    // Home tab providers
    ref.read(transactionsProvider);

    // Accounts tab providers
    ref.read(accountsProvider);
    ref.read(cardsByAccountProvider(null));
    ref.read(smsTemplatesProvider);
    ref.read(pendingSmsConfirmationsProvider);

    // Budget tab providers
    ref.read(activeBudgetsProvider);
    ref.read(categoriesProvider);

    // Note: We use ref.read() here to trigger providers without watching
    // The actual pages will watch these providers when built, maintaining
    // the streams and ensuring reactive updates
  }

  /// Warm up providers for a specific screen
  /// Useful when navigating to ensure data is ready
  static void warmUpForScreen(WidgetRef ref, String screen) {
    switch (screen) {
      case 'home':
        ref.read(transactionsProvider);
        break;
      case 'accounts':
        ref.read(accountsProvider);
        ref.read(cardsByAccountProvider(null));
        ref.read(smsTemplatesProvider);
        ref.read(pendingSmsConfirmationsProvider);
        break;
      case 'budget':
        ref.read(activeBudgetsProvider);
        ref.read(categoriesProvider);
        break;
    }
  }
}
