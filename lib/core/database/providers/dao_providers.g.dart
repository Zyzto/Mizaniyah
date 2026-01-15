// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dao_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// DAO providers - direct access to data layer without repository indirection

// Ref type definitions
typedef TransactionDaoRef = Ref;
typedef AccountDaoRef = Ref;
typedef CardDaoRef = Ref;
typedef CategoryDaoRef = Ref;
typedef BudgetDaoRef = Ref;
typedef SmsTemplateDaoRef = Ref;
typedef PendingSmsConfirmationDaoRef = Ref;
typedef NotificationHistoryDaoRef = Ref;

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

String _$transactionDaoHash() => r'6dd777ae8ce182566fa701a25581c2e6069342a2';

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

String _$accountDaoHash() => r'5dd420d7504692da1189327d8d39b85fe8ac8ba8';

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

String _$cardDaoHash() => r'80fdad4e6d8d7bd96d7eb8ed73e436be6a7cdbb1';

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

String _$categoryDaoHash() => r'56856da532ebc5208aa3ff3aba14ef2ec9e5efd4';

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

String _$budgetDaoHash() => r'89ea6f08da88803f674732100f79fb0e595c601c';

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

String _$smsTemplateDaoHash() => r'79185becc84bafe6ea7f1417e37b3f775a209c03';

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
    r'e02267112a823c976d5db56d5b5a6f4db85b2143';

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
    r'25b5868191d7d86fcbfc877b61dbb5ea8a30c53a';
