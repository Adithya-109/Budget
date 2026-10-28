// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'engine_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Wall clock; override in tests.

@ProviderFor(clock)
final clockProvider = ClockProvider._();

/// Wall clock; override in tests.

final class ClockProvider extends $FunctionalProvider<Clock, Clock, Clock>
    with $Provider<Clock> {
  /// Wall clock; override in tests.
  ClockProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'clockProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$clockHash();

  @$internal
  @override
  $ProviderElement<Clock> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Clock create(Ref ref) {
    return clock(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Clock value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Clock>(value),
    );
  }
}

String _$clockHash() => r'ce4c8073e4878f6859ed9a59fae2c1819b4179af';

/// Local midnight of today. Re-emits at each local midnight so day-based
/// numbers (safe-to-spend, days remaining) roll over while the app is open.
/// Timers stall while the app is suspended, so the resume sync also
/// invalidates this provider.

@ProviderFor(currentDay)
final currentDayProvider = CurrentDayProvider._();

/// Local midnight of today. Re-emits at each local midnight so day-based
/// numbers (safe-to-spend, days remaining) roll over while the app is open.
/// Timers stall while the app is suspended, so the resume sync also
/// invalidates this provider.

final class CurrentDayProvider
    extends
        $FunctionalProvider<AsyncValue<DateTime>, DateTime, Stream<DateTime>>
    with $FutureModifier<DateTime>, $StreamProvider<DateTime> {
  /// Local midnight of today. Re-emits at each local midnight so day-based
  /// numbers (safe-to-spend, days remaining) roll over while the app is open.
  /// Timers stall while the app is suspended, so the resume sync also
  /// invalidates this provider.
  CurrentDayProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'currentDayProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$currentDayHash();

  @$internal
  @override
  $StreamProviderElement<DateTime> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<DateTime> create(Ref ref) {
    return currentDay(ref);
  }
}

String _$currentDayHash() => r'eb2f97beadb32f376fa68c5b700c94a0f4aad419';

/// The allowance cycle containing today. Only rebuilds when the day or the
/// reset day changes (not on every balance update).

@ProviderFor(currentCycle)
final currentCycleProvider = CurrentCycleProvider._();

/// The allowance cycle containing today. Only rebuilds when the day or the
/// reset day changes (not on every balance update).

final class CurrentCycleProvider
    extends
        $FunctionalProvider<
          AsyncValue<BudgetCycle>,
          BudgetCycle,
          FutureOr<BudgetCycle>
        >
    with $FutureModifier<BudgetCycle>, $FutureProvider<BudgetCycle> {
  /// The allowance cycle containing today. Only rebuilds when the day or the
  /// reset day changes (not on every balance update).
  CurrentCycleProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'currentCycleProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$currentCycleHash();

  @$internal
  @override
  $FutureProviderElement<BudgetCycle> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<BudgetCycle> create(Ref ref) {
    return currentCycle(ref);
  }
}

String _$currentCycleHash() => r'aca0256e96d5fc0631c1ff718e0edec94c81fac7';

/// Live inputs for the burn-rate engine, from one consistent SQL read.

@ProviderFor(ledgerSnapshot)
final ledgerSnapshotProvider = LedgerSnapshotProvider._();

/// Live inputs for the burn-rate engine, from one consistent SQL read.

final class LedgerSnapshotProvider
    extends
        $FunctionalProvider<
          AsyncValue<LedgerSnapshot>,
          LedgerSnapshot,
          Stream<LedgerSnapshot>
        >
    with $FutureModifier<LedgerSnapshot>, $StreamProvider<LedgerSnapshot> {
  /// Live inputs for the burn-rate engine, from one consistent SQL read.
  LedgerSnapshotProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'ledgerSnapshotProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$ledgerSnapshotHash();

  @$internal
  @override
  $StreamProviderElement<LedgerSnapshot> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<LedgerSnapshot> create(Ref ref) {
    return ledgerSnapshot(ref);
  }
}

String _$ledgerSnapshotHash() => r'6a62e9cffe3fd037194bb6f816e21a3e56a48e51';

/// Safe-to-spend today, tomorrow's recalibrated limit, the 7-day burn
/// velocity, Days-Until-Broke and Survival Mode.

@ProviderFor(burnRate)
final burnRateProvider = BurnRateProvider._();

/// Safe-to-spend today, tomorrow's recalibrated limit, the 7-day burn
/// velocity, Days-Until-Broke and Survival Mode.

final class BurnRateProvider
    extends
        $FunctionalProvider<
          AsyncValue<BurnRateMetrics>,
          AsyncValue<BurnRateMetrics>,
          AsyncValue<BurnRateMetrics>
        >
    with $Provider<AsyncValue<BurnRateMetrics>> {
  /// Safe-to-spend today, tomorrow's recalibrated limit, the 7-day burn
  /// velocity, Days-Until-Broke and Survival Mode.
  BurnRateProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'burnRateProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$burnRateHash();

  @$internal
  @override
  $ProviderElement<AsyncValue<BurnRateMetrics>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AsyncValue<BurnRateMetrics> create(Ref ref) {
    return burnRate(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<BurnRateMetrics> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<BurnRateMetrics>>(value),
    );
  }
}

String _$burnRateHash() => r'837654bec0407f5ad8f25e8df15eb0cf62df2d23';

/// `Bank balance − money I owe friends`, plus the floating receivables.

@ProviderFor(trueLiquidBalance)
final trueLiquidBalanceProvider = TrueLiquidBalanceProvider._();

/// `Bank balance − money I owe friends`, plus the floating receivables.

final class TrueLiquidBalanceProvider
    extends
        $FunctionalProvider<
          AsyncValue<TrueLiquidBalance>,
          AsyncValue<TrueLiquidBalance>,
          AsyncValue<TrueLiquidBalance>
        >
    with $Provider<AsyncValue<TrueLiquidBalance>> {
  /// `Bank balance − money I owe friends`, plus the floating receivables.
  TrueLiquidBalanceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'trueLiquidBalanceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$trueLiquidBalanceHash();

  @$internal
  @override
  $ProviderElement<AsyncValue<TrueLiquidBalance>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AsyncValue<TrueLiquidBalance> create(Ref ref) {
    return trueLiquidBalance(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<TrueLiquidBalance> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<TrueLiquidBalance>>(
        value,
      ),
    );
  }
}

String _$trueLiquidBalanceHash() => r'0432b6c4fbcafe3d811be54b91d33f1d8391075f';

/// Personal (net-share) spend per category this cycle.

@ProviderFor(cycleCategorySpend)
final cycleCategorySpendProvider = CycleCategorySpendProvider._();

/// Personal (net-share) spend per category this cycle.

final class CycleCategorySpendProvider
    extends
        $FunctionalProvider<
          AsyncValue<Map<TxnCategory, int>>,
          Map<TxnCategory, int>,
          Stream<Map<TxnCategory, int>>
        >
    with
        $FutureModifier<Map<TxnCategory, int>>,
        $StreamProvider<Map<TxnCategory, int>> {
  /// Personal (net-share) spend per category this cycle.
  CycleCategorySpendProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'cycleCategorySpendProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$cycleCategorySpendHash();

  @$internal
  @override
  $StreamProviderElement<Map<TxnCategory, int>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<Map<TxnCategory, int>> create(Ref ref) {
    return cycleCategorySpend(ref);
  }
}

String _$cycleCategorySpendHash() =>
    r'782fbe562107e50574d9644f9b5735560fc52b13';

/// Personal spend for every day of this cycle (zero-filled), for charts.

@ProviderFor(cycleDailySpend)
final cycleDailySpendProvider = CycleDailySpendProvider._();

/// Personal spend for every day of this cycle (zero-filled), for charts.

final class CycleDailySpendProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<DailySpend>>,
          List<DailySpend>,
          Stream<List<DailySpend>>
        >
    with $FutureModifier<List<DailySpend>>, $StreamProvider<List<DailySpend>> {
  /// Personal spend for every day of this cycle (zero-filled), for charts.
  CycleDailySpendProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'cycleDailySpendProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$cycleDailySpendHash();

  @$internal
  @override
  $StreamProviderElement<List<DailySpend>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<DailySpend>> create(Ref ref) {
    return cycleDailySpend(ref);
  }
}

String _$cycleDailySpendHash() => r'f94969430b749a9670082f28de116999bc3f82c4';

/// Reconciles the ledger with the balance the user's bank app shows. State
/// is the last result (null until the first reconciliation).

@ProviderFor(BalanceReconciler)
final balanceReconcilerProvider = BalanceReconcilerProvider._();

/// Reconciles the ledger with the balance the user's bank app shows. State
/// is the last result (null until the first reconciliation).
final class BalanceReconcilerProvider
    extends $NotifierProvider<BalanceReconciler, ReconciliationResult?> {
  /// Reconciles the ledger with the balance the user's bank app shows. State
  /// is the last result (null until the first reconciliation).
  BalanceReconcilerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'balanceReconcilerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$balanceReconcilerHash();

  @$internal
  @override
  BalanceReconciler create() => BalanceReconciler();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ReconciliationResult? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ReconciliationResult?>(value),
    );
  }
}

String _$balanceReconcilerHash() => r'98da0d03f228cce8e9f6e2f8a25eaa3695aa55d7';

/// Reconciles the ledger with the balance the user's bank app shows. State
/// is the last result (null until the first reconciliation).

abstract class _$BalanceReconciler extends $Notifier<ReconciliationResult?> {
  ReconciliationResult? build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<ReconciliationResult?, ReconciliationResult?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ReconciliationResult?, ReconciliationResult?>,
              ReconciliationResult?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
