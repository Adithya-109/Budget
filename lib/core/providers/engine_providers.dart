import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/budget_cycle.dart';
import '../../domain/burn_rate.dart';
import '../database/app_database.dart';
import '../database/ledger_models.dart';
import 'database_providers.dart';

part 'engine_providers.g.dart';

typedef Clock = DateTime Function();

/// Wall clock; override in tests.
@Riverpod(keepAlive: true)
Clock clock(Ref ref) => DateTime.now;

/// Local midnight of today. Re-emits at each local midnight so day-based
/// numbers (safe-to-spend, days remaining) roll over while the app is open.
/// Timers stall while the app is suspended, so the resume sync also
/// invalidates this provider.
@Riverpod(keepAlive: true)
Stream<DateTime> currentDay(Ref ref) {
  final now = ref.watch(clockProvider);
  final controller = StreamController<DateTime>();
  Timer? timer;

  void emit() {
    final moment = now();
    final today = DateTime(moment.year, moment.month, moment.day);
    controller.add(today);
    final nextMidnight = DateTime(today.year, today.month, today.day + 1);
    // A second past midnight so the clock is unambiguously on the new day.
    timer = Timer(
      nextMidnight.difference(moment) + const Duration(seconds: 1),
      emit,
    );
  }

  emit();
  ref.onDispose(() {
    timer?.cancel();
    controller.close();
  });
  return controller.stream;
}

/// The allowance cycle containing today. Only rebuilds when the day or the
/// reset day changes (not on every balance update).
@riverpod
Future<BudgetCycle> currentCycle(Ref ref) async {
  final todayFuture = ref.watch(currentDayProvider.future);
  final resetDayFuture = ref.watch(
    budgetSettingsProvider.selectAsync((config) => config.cycleResetDay),
  );
  return BudgetCycle.containing(
    await todayFuture,
    resetDay: await resetDayFuture,
  );
}

/// Live inputs for the burn-rate engine, from one consistent SQL read.
@riverpod
Stream<LedgerSnapshot> ledgerSnapshot(Ref ref) async* {
  final dao = ref.watch(ledgerDaoProvider);
  final todayFuture = ref.watch(currentDayProvider.future);
  final cycleFuture = ref.watch(currentCycleProvider.future);
  final today = await todayFuture;
  final cycle = await cycleFuture;
  yield* dao.watchLedgerSnapshot(cycle: cycle, today: today);
}

/// Safe-to-spend today, tomorrow's recalibrated limit, the 7-day burn
/// velocity, Days-Until-Broke and Survival Mode.
@riverpod
AsyncValue<BurnRateMetrics> burnRate(Ref ref) =>
    ref.watch(ledgerSnapshotProvider).whenData(BurnRateMetrics.fromSnapshot);

/// `Bank balance − money I owe friends`, plus the floating receivables.
@riverpod
AsyncValue<TrueLiquidBalance> trueLiquidBalance(Ref ref) => ref
    .watch(financialSummaryProvider)
    .whenData(
      (summary) => TrueLiquidBalance(
        bankBalanceMinor: summary.bankBalanceMinor,
        iOweMinor: summary.iOweMinor,
        owedToMeMinor: summary.owedToMeMinor,
      ),
    );

/// Personal (net-share) spend per category this cycle.
@riverpod
Stream<Map<TxnCategory, int>> cycleCategorySpend(Ref ref) async* {
  final dao = ref.watch(ledgerDaoProvider);
  final cycle = await ref.watch(currentCycleProvider.future);
  yield* dao.watchCategorySpend(cycle.start, cycle.end);
}

/// Personal spend for every day of this cycle (zero-filled), for charts.
@riverpod
Stream<List<DailySpend>> cycleDailySpend(Ref ref) async* {
  final dao = ref.watch(ledgerDaoProvider);
  final cycle = await ref.watch(currentCycleProvider.future);
  yield* dao.watchDailyPersonalSpend(cycle.start, cycle.end);
}

/// Reconciles the ledger with the balance the user's bank app shows. State
/// is the last result (null until the first reconciliation).
@Riverpod(keepAlive: true)
class BalanceReconciler extends _$BalanceReconciler {
  @override
  ReconciliationResult? build() => null;

  Future<ReconciliationResult> reconcile(
    int actualBalanceMinor, {
    bool logShortfallAsSpend = true,
  }) async {
    final result = await ref
        .read(ledgerDaoProvider)
        .reconcileBankBalance(
          actualBalanceMinor,
          logShortfallAsSpend: logShortfallAsSpend,
          at: ref.read(clockProvider)(),
        );
    state = result;
    return result;
  }
}
