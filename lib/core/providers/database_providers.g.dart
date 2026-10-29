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

@ProviderFor(recentTransactions)
final recentTransactionsProvider = RecentTransactionsProvider._();

final class RecentTransactionsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<LedgerTransaction>>,
          List<LedgerTransaction>,
          Stream<List<LedgerTransaction>>
        >
    with
        $FutureModifier<List<LedgerTransaction>>,
        $StreamProvider<List<LedgerTransaction>> {
  RecentTransactionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'recentTransactionsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$recentTransactionsHash();

  @$internal
  @override
  $StreamProviderElement<List<LedgerTransaction>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<LedgerTransaction>> create(Ref ref) {
    return recentTransactions(ref);
  }
}

String _$recentTransactionsHash() =>
    r'9027c0a0585a1b9ab30269e28991b03aa16091d5';

/// Every unsettled split, oldest first.

@ProviderFor(openSplits)
final openSplitsProvider = OpenSplitsProvider._();

/// Every unsettled split, oldest first.

final class OpenSplitsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<OpenSplit>>,
          List<OpenSplit>,
          Stream<List<OpenSplit>>
        >
    with $FutureModifier<List<OpenSplit>>, $StreamProvider<List<OpenSplit>> {
  /// Every unsettled split, oldest first.
  OpenSplitsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'openSplitsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$openSplitsHash();

  @$internal
  @override
  $StreamProviderElement<List<OpenSplit>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<OpenSplit>> create(Ref ref) {
    return openSplits(ref);
  }
}

String _$openSplitsHash() => r'e3709566175ee940387f73f2bfad220ea3813fb8';

@ProviderFor(transactionSplits)
final transactionSplitsProvider = TransactionSplitsFamily._();

final class TransactionSplitsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<SplitEntry>>,
          List<SplitEntry>,
          Stream<List<SplitEntry>>
        >
    with $FutureModifier<List<SplitEntry>>, $StreamProvider<List<SplitEntry>> {
  TransactionSplitsProvider._({
    required TransactionSplitsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'transactionSplitsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$transactionSplitsHash();

  @override
  String toString() {
    return r'transactionSplitsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<List<SplitEntry>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<SplitEntry>> create(Ref ref) {
    final argument = this.argument as String;
    return transactionSplits(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is TransactionSplitsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$transactionSplitsHash() => r'f44894ed48f4669b7230065cae4be0a6904198d3';

final class TransactionSplitsFamily extends $Family
    with $FunctionalFamilyOverride<Stream<List<SplitEntry>>, String> {
  TransactionSplitsFamily._()
    : super(
        retry: null,
        name: r'transactionSplitsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  TransactionSplitsProvider call(String transactionId) =>
      TransactionSplitsProvider._(argument: transactionId, from: this);

  @override
  String toString() => r'transactionSplitsProvider';
}

@ProviderFor(activeSubscriptions)
final activeSubscriptionsProvider = ActiveSubscriptionsProvider._();

final class ActiveSubscriptionsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Subscription>>,
          List<Subscription>,
          Stream<List<Subscription>>
        >
    with
        $FutureModifier<List<Subscription>>,
        $StreamProvider<List<Subscription>> {
  ActiveSubscriptionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'activeSubscriptionsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$activeSubscriptionsHash();

  @$internal
  @override
  $StreamProviderElement<List<Subscription>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<Subscription>> create(Ref ref) {
    return activeSubscriptions(ref);
  }
}

String _$activeSubscriptionsHash() =>
    r'49768d5ff9255aba6f282b15532598d9a4357a6c';

@ProviderFor(subscriptionGraveyard)
final subscriptionGraveyardProvider = SubscriptionGraveyardProvider._();

final class SubscriptionGraveyardProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Subscription>>,
          List<Subscription>,
          Stream<List<Subscription>>
        >
    with
        $FutureModifier<List<Subscription>>,
        $StreamProvider<List<Subscription>> {
  SubscriptionGraveyardProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'subscriptionGraveyardProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$subscriptionGraveyardHash();

  @$internal
  @override
  $StreamProviderElement<List<Subscription>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<Subscription>> create(Ref ref) {
    return subscriptionGraveyard(ref);
  }
}

String _$subscriptionGraveyardHash() =>
    r'05a682bb86880a2244f9f7e967d892f86a433a45';

/// The user's currency symbol (₹ until settings load).

@ProviderFor(currencySymbol)
final currencySymbolProvider = CurrencySymbolProvider._();

/// The user's currency symbol (₹ until settings load).

final class CurrencySymbolProvider
    extends $FunctionalProvider<String, String, String>
    with $Provider<String> {
  /// The user's currency symbol (₹ until settings load).
  CurrencySymbolProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'currencySymbolProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$currencySymbolHash();

  @$internal
  @override
  $ProviderElement<String> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  String create(Ref ref) {
    return currencySymbol(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String>(value),
    );
  }
}

String _$currencySymbolHash() => r'dae647f30269ebee9fc2e3bd6d76cd01e7508677';

@ProviderFor(transactionById)
final transactionByIdProvider = TransactionByIdFamily._();

final class TransactionByIdProvider
    extends
        $FunctionalProvider<
          AsyncValue<LedgerTransaction?>,
          LedgerTransaction?,
          Stream<LedgerTransaction?>
        >
    with
        $FutureModifier<LedgerTransaction?>,
        $StreamProvider<LedgerTransaction?> {
  TransactionByIdProvider._({
    required TransactionByIdFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'transactionByIdProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$transactionByIdHash();

  @override
  String toString() {
    return r'transactionByIdProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<LedgerTransaction?> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<LedgerTransaction?> create(Ref ref) {
    final argument = this.argument as String;
    return transactionById(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is TransactionByIdProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$transactionByIdHash() => r'd7831bf154f6b0e6ad7c24e10cb60c8989517602';

final class TransactionByIdFamily extends $Family
    with $FunctionalFamilyOverride<Stream<LedgerTransaction?>, String> {
  TransactionByIdFamily._()
    : super(
        retry: null,
        name: r'transactionByIdProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  TransactionByIdProvider call(String id) =>
      TransactionByIdProvider._(argument: id, from: this);

  @override
  String toString() => r'transactionByIdProvider';
}
