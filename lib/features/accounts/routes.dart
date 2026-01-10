import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/navigation/route_paths.dart';
import 'pages/account_form_page.dart';
import 'pages/card_form_page.dart';
import '../../../core/database/app_database.dart' as db;
import '../../../core/database/daos/account_dao.dart';
import '../../../core/database/daos/card_dao.dart';
import '../../../core/database/providers/database_provider.dart';

/// Account routes for the application (inside ShellRoute - with nav bar)
List<RouteBase> getAccountRoutes() {
  return [
    GoRoute(
      path: RoutePaths.accounts,
      builder: (context, state) => const SizedBox.shrink(), // Handled by MainScaffold
    ),
  ];
}

/// Account form routes (outside ShellRoute - full screen without nav bar)
List<RouteBase> getAccountFormRoutes() {
  return [
    // Account routes
    GoRoute(
      path: RoutePaths.accountsAdd,
      builder: (context, state) => const AccountFormPage(),
    ),
    GoRoute(
      path: '/accounts/:id/edit',
      builder: (context, state) {
        final id = int.tryParse(state.pathParameters['id'] ?? '');
        if (id == null) {
          return const SizedBox.shrink();
        }
        return AccountFormPageLoader(accountId: id);
      },
    ),
    // Card routes
    GoRoute(
      path: '/accounts/:accountId/card/add',
      builder: (context, state) {
        final accountId = int.tryParse(state.pathParameters['accountId'] ?? '');
        return CardFormPage(accountId: accountId);
      },
    ),
    GoRoute(
      path: '/accounts/card/:id/edit',
      builder: (context, state) {
        final id = int.tryParse(state.pathParameters['id'] ?? '');
        if (id == null) {
          return const SizedBox.shrink();
        }
        return CardFormPageLoader(cardId: id);
      },
    ),
  ];
}

/// Loader widget for account form page (edit mode)
class AccountFormPageLoader extends StatelessWidget {
  final int accountId;

  const AccountFormPageLoader({
    super.key,
    required this.accountId,
  });

  @override
  Widget build(BuildContext context) {
    final database = getDatabase();
    final accountDao = AccountDao(database);

    return FutureBuilder<db.Account?>(
      future: accountDao.getAccountById(accountId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final account = snapshot.data;
        if (account == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            context.go(RoutePaths.accounts);
          });
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return AccountFormPage(account: account);
      },
    );
  }
}

/// Loader widget for card form page (edit mode)
class CardFormPageLoader extends StatelessWidget {
  final int cardId;

  const CardFormPageLoader({
    super.key,
    required this.cardId,
  });

  @override
  Widget build(BuildContext context) {
    final database = getDatabase();
    final cardDao = CardDao(database);

    return FutureBuilder<db.Card?>(
      future: cardDao.getCardById(cardId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final card = snapshot.data;
        if (card == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            context.go(RoutePaths.accounts);
          });
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return CardFormPage(card: card);
      },
    );
  }
}
