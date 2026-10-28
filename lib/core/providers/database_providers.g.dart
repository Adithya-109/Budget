// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The one connection to `finance.sqlite`. Override in tests with an
/// in-memory `AppDatabase`.

@ProviderFor(appDatabase)
final appDatabaseProvider = AppDatabaseProvider._();

/// The one connection to `finance.sqlite`. Override in tests with an
/// in-memory `AppDatabase`.

final class AppDatabaseProvider
    extends $FunctionalProvider<AppDatabase, AppDatabase, AppDatabase>
    with $Provider<AppDatabase> {
  /// The one connection to `finance.sqlite`. Override in tests with an
  /// in-memory `AppDatabase`.
  AppDatabaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appDatabaseProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appDatabaseHash();

  @$internal
  @override
  $ProviderElement<AppDatabase> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AppDatabase create(Ref ref) {
    return appDatabase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppDatabase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AppDatabase>(value),
    );
  }
}

String _$appDatabaseHash() => r'7f7966435322f492209182ef2304ee35b5a2c3b4';

@ProviderFor(ledgerDao)
final ledgerDaoProvider = LedgerDaoProvider._();

final class LedgerDaoProvider
    extends $FunctionalProvider<LedgerDao, LedgerDao, LedgerDao>
    with $Provider<LedgerDao> {
  LedgerDaoProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'ledgerDaoProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$ledgerDaoHash();

  @$internal
  @override
  $ProviderElement<LedgerDao> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  LedgerDao create(Ref ref) {
    return ledgerDao(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LedgerDao value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LedgerDao>(value),
    );
  }
}

String _$ledgerDaoHash() => r'efeefe25358db6071f771d7e86b53ff60560da3f';

@ProviderFor(budgetDao)
final budgetDaoProvider = BudgetDaoProvider._();

final class BudgetDaoProvider
    extends $FunctionalProvider<BudgetDao, BudgetDao, BudgetDao>
    with $Provider<BudgetDao> {
  BudgetDaoProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'budgetDaoProvider',
        isAutoDispose: false,
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

String _$budgetDaoHash() => r'ba014a23588469e48d0bbbb8bdff39c5a0fef6f4';

@ProviderFor(subscriptionsDao)
final subscriptionsDaoProvider = SubscriptionsDaoProvider._();

final class SubscriptionsDaoProvider
    extends
        $FunctionalProvider<
          SubscriptionsDao,
          SubscriptionsDao,
          SubscriptionsDao
        >
    with $Provider<SubscriptionsDao> {
  SubscriptionsDaoProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'subscriptionsDaoProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$subscriptionsDaoHash();

  @$internal
  @override
  $ProviderElement<SubscriptionsDao> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SubscriptionsDao create(Ref ref) {
    return subscriptionsDao(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SubscriptionsDao value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SubscriptionsDao>(value),
    );
  }
}

String _$subscriptionsDaoHash() => r'f31d0670787fde7a0f3c32f614f0a1a38676fc7e';

@ProviderFor(financialSummary)
final financialSummaryProvider = FinancialSummaryProvider._();

final class FinancialSummaryProvider
    extends
        $FunctionalProvider<
          AsyncValue<FinancialSummaryViewData>,
          FinancialSummaryViewData,
          Stream<FinancialSummaryViewData>
        >
    with
        $FutureModifier<FinancialSummaryViewData>,
        $StreamProvider<FinancialSummaryViewData> {
  FinancialSummaryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'financialSummaryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$financialSummaryHash();

  @$internal
  @override
  $StreamProviderElement<FinancialSummaryViewData> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<FinancialSummaryViewData> create(Ref ref) {
    return financialSummary(ref);
  }
}

String _$financialSummaryHash() => r'00d3722422bbde2adce89adf87d0f91e2a0aec64';

@ProviderFor(budgetSettings)
final budgetSettingsProvider = BudgetSettingsProvider._();

final class BudgetSettingsProvider
    extends
        $FunctionalProvider<
          AsyncValue<BudgetConfigRow>,
          BudgetConfigRow,
          Stream<BudgetConfigRow>
        >
    with $FutureModifier<BudgetConfigRow>, $StreamProvider<BudgetConfigRow> {
  BudgetSettingsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'budgetSettingsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$budgetSettingsHash();

  @$internal
  @override
  $StreamProviderElement<BudgetConfigRow> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<BudgetConfigRow> create(Ref ref) {
    return budgetSettings(ref);
  }
}

String _$budgetSettingsHash() => r'4a8c253e1c68a8b7694dbd4234765bf1224a5d52';

@ProviderFor(friendBalances)
final friendBalancesProvider = FriendBalancesProvider._();

final class FriendBalancesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<FriendBalance>>,
          List<FriendBalance>,
          Stream<List<FriendBalance>>
        >
    with
        $FutureModifier<List<FriendBalance>>,
        $StreamProvider<List<FriendBalance>> {
  FriendBalancesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'friendBalancesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$friendBalancesHash();

  @$internal
  @override
  $StreamProviderElement<List<FriendBalance>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<FriendBalance>> create(Ref ref) {
    return friendBalances(ref);
  }
}

String _$friendBalancesHash() => r'21efe73aa6c0a2cf4cdf5079db9888ffb5c566a8';
