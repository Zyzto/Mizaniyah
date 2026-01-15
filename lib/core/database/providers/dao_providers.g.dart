// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dao_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// DAO providers - direct access to data layer without repository indirection

@ProviderFor(transactionDao)
const transactionDaoProvider = TransactionDaoProvider._();

/// DAO providers - direct access to data layer without repository indirection

final class TransactionDaoProvider
    extends $FunctionalProvider<TransactionDao, TransactionDao, TransactionDao>
    with $Provider<TransactionDao> {
  /// DAO providers - direct access to data layer without repository indirection
  const TransactionDaoProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'transactionDaoProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$transactionDaoHash();

  @$internal
  @override
  $ProviderElement<TransactionDao> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  TransactionDao create(Ref ref) {
    return transactionDao(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TransactionDao value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TransactionDao>(value),
    );
  }
}

String _$transactionDaoHash() => r'1b3b7f1bd1fbc425b83365d025067d036a0959c0';

@ProviderFor(accountDao)
const accountDaoProvider = AccountDaoProvider._();

final class AccountDaoProvider
    extends $FunctionalProvider<AccountDao, AccountDao, AccountDao>
    with $Provider<AccountDao> {
  const AccountDaoProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'accountDaoProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$accountDaoHash();

  @$internal
  @override
  $ProviderElement<AccountDao> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AccountDao create(Ref ref) {
    return accountDao(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AccountDao value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AccountDao>(value),
    );
  }
}

String _$accountDaoHash() => r'66177bd74c5dc7fd269b3703a294263c417ed4fb';

@ProviderFor(cardDao)
const cardDaoProvider = CardDaoProvider._();

final class CardDaoProvider
    extends $FunctionalProvider<CardDao, CardDao, CardDao>
    with $Provider<CardDao> {
  const CardDaoProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'cardDaoProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$cardDaoHash();

  @$internal
  @override
  $ProviderElement<CardDao> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  CardDao create(Ref ref) {
    return cardDao(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CardDao value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CardDao>(value),
    );
  }
}

String _$cardDaoHash() => r'd22eeb83504151746a218fc185da887c7bec221d';

@ProviderFor(categoryDao)
const categoryDaoProvider = CategoryDaoProvider._();

final class CategoryDaoProvider
    extends $FunctionalProvider<CategoryDao, CategoryDao, CategoryDao>
    with $Provider<CategoryDao> {
  const CategoryDaoProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'categoryDaoProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$categoryDaoHash();

  @$internal
  @override
  $ProviderElement<CategoryDao> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  CategoryDao create(Ref ref) {
    return categoryDao(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CategoryDao value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CategoryDao>(value),
    );
  }
}

String _$categoryDaoHash() => r'13119f0980bd19c66251f44867bce63c26786937';

@ProviderFor(budgetDao)
const budgetDaoProvider = BudgetDaoProvider._();

final class BudgetDaoProvider
    extends $FunctionalProvider<BudgetDao, BudgetDao, BudgetDao>
    with $Provider<BudgetDao> {
  const BudgetDaoProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'budgetDaoProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$budgetDaoHash();

  @$internal
  @override
  $ProviderElement<BudgetDao> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  BudgetDao create(Ref ref) {
    return budgetDao(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BudgetDao value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BudgetDao>(value),
    );
  }
}

String _$budgetDaoHash() => r'01d666cd72256a674edaeac569a74908c48656a2';

@ProviderFor(smsTemplateDao)
const smsTemplateDaoProvider = SmsTemplateDaoProvider._();

final class SmsTemplateDaoProvider
    extends $FunctionalProvider<SmsTemplateDao, SmsTemplateDao, SmsTemplateDao>
    with $Provider<SmsTemplateDao> {
  const SmsTemplateDaoProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'smsTemplateDaoProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$smsTemplateDaoHash();

  @$internal
  @override
  $ProviderElement<SmsTemplateDao> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SmsTemplateDao create(Ref ref) {
    return smsTemplateDao(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SmsTemplateDao value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SmsTemplateDao>(value),
    );
  }
}

String _$smsTemplateDaoHash() => r'b4bbc9d76ea5bc6978459b41ad54dbfde5c53a57';

@ProviderFor(pendingSmsConfirmationDao)
const pendingSmsConfirmationDaoProvider = PendingSmsConfirmationDaoProvider._();

final class PendingSmsConfirmationDaoProvider
    extends
        $FunctionalProvider<
          PendingSmsConfirmationDao,
          PendingSmsConfirmationDao,
          PendingSmsConfirmationDao
        >
    with $Provider<PendingSmsConfirmationDao> {
  const PendingSmsConfirmationDaoProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pendingSmsConfirmationDaoProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pendingSmsConfirmationDaoHash();

  @$internal
  @override
  $ProviderElement<PendingSmsConfirmationDao> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  PendingSmsConfirmationDao create(Ref ref) {
    return pendingSmsConfirmationDao(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PendingSmsConfirmationDao value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PendingSmsConfirmationDao>(value),
    );
  }
}

String _$pendingSmsConfirmationDaoHash() =>
    r'f1652b0192272946d78f0eca385f3b0b9d90060e';

@ProviderFor(notificationHistoryDao)
const notificationHistoryDaoProvider = NotificationHistoryDaoProvider._();

final class NotificationHistoryDaoProvider
    extends
        $FunctionalProvider<
          NotificationHistoryDao,
          NotificationHistoryDao,
          NotificationHistoryDao
        >
    with $Provider<NotificationHistoryDao> {
  const NotificationHistoryDaoProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'notificationHistoryDaoProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$notificationHistoryDaoHash();

  @$internal
  @override
  $ProviderElement<NotificationHistoryDao> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  NotificationHistoryDao create(Ref ref) {
    return notificationHistoryDao(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(NotificationHistoryDao value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<NotificationHistoryDao>(value),
    );
  }
}

String _$notificationHistoryDaoHash() =>
    r'5b1fa2bcfa5e6e60aba8c90d2ca3e8cb2a65d53b';

@ProviderFor(categoryMappingDao)
const categoryMappingDaoProvider = CategoryMappingDaoProvider._();

final class CategoryMappingDaoProvider
    extends
        $FunctionalProvider<
          CategoryMappingDao,
          CategoryMappingDao,
          CategoryMappingDao
        >
    with $Provider<CategoryMappingDao> {
  const CategoryMappingDaoProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'categoryMappingDaoProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$categoryMappingDaoHash();

  @$internal
  @override
  $ProviderElement<CategoryMappingDao> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  CategoryMappingDao create(Ref ref) {
    return categoryMappingDao(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CategoryMappingDao value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CategoryMappingDao>(value),
    );
  }
}

String _$categoryMappingDaoHash() =>
    r'e8d44f9c8dfc9ce60b99b2cbf4325d1b104d851b';
