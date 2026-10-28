import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderListenable;
import 'package:flutter_test/flutter_test.dart';
import 'package:splitburn/core/database/app_database.dart';
import 'package:splitburn/core/providers/database_providers.dart';
import 'package:splitburn/core/providers/engine_providers.dart';
import 'package:splitburn/core/sync/ledger_sync.dart';
import 'package:splitburn/domain/expense_draft.dart';

import '../support/test_database.dart';

const rahul = FriendRef(id: 'f-rahul', name: 'Rahul');

void main() {
  late AppDatabase db;
  late DateTime now;
  late ProviderContainer container;

  setUp(() {
    db = openTestDatabase();
    now = DateTime(2026, 10, 28, 15);
    container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        clockProvider.overrideWithValue(() => now),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  Future<void> spend(
    int minor,
    DateTime at, {
    List<FriendRef> with_ = const [],
  }) => db.ledgerDao.logExpense(
    ExpenseDraft.equalSplit(
      merchant: 'Spend',
      totalMinor: minor,
      friends: with_,
      category: TxnCategory.food,
      createdAt: at,
    ),
  );

  /// Keeps an async provider listened (Riverpod 3 pauses or disposes
  /// unlistened ones) and waits for a data value matching [where].
  Future<T> nextValue<T>(
    ProviderListenable<AsyncValue<T>> provider, {
    bool Function(T value)? where,
  }) async {
    final sub = container.listen(provider, (_, _) {});
    addTearDown(sub.close);
    for (var i = 0; i < 100; i++) {
      final value = sub.read();
      if (value is AsyncError<T>) throw value.error;
      if (value is AsyncData<T> && (where == null || where(value.value))) {
        return value.value;
      }
      await pumpEventQueue();
    }
    throw StateError('no matching value; last: ${sub.read()}');
  }

  test(
    'burn rate follows writes: the spec ₹400 → ₹650 recalibration',
    () async {
      await spend(1340000, DateTime(2026, 10, 3));
      var metrics = await nextValue(burnRateProvider);
      expect(metrics.daysRemaining, 4);
      expect(metrics.dailyLimitMinor, 40000);
      expect(metrics.leftTodayMinor, 40000);

      await spend(65000, DateTime(2026, 10, 28, 13));
      metrics = await nextValue(burnRateProvider, where: (m) => m.isOverToday);
      expect(metrics.leftTodayMinor, -25000);
      expect(metrics.tomorrowLimitMinor, 31666);
      expect(metrics.recalibrationDeltaMinor, 31666 - 40000);
    },
  );

  test('a group dinner I fronted only counts my share', () async {
    await spend(120000, DateTime(2026, 10, 28, 20), with_: [rahul]);
    final metrics = await nextValue(burnRateProvider);
    final balance = await nextValue(trueLiquidBalanceProvider);
    final categories = await nextValue(cycleCategorySpendProvider);

    expect(metrics.leftTodayMinor, metrics.dailyLimitMinor - 60000);
    expect(balance.bankBalanceMinor, 1380000);
    expect(balance.owedToMeMinor, 60000);
    expect(balance.trueSpendableMinor, 1380000);
    expect(categories, {TxnCategory.food: 60000});
  });

  test('changing the reset day moves the cycle', () async {
    expect(
      (await nextValue(currentCycleProvider)).start,
      DateTime(2026, 10, 1),
    );
    await db.budgetDao.updateSettings(cycleResetDay: 15);
    final cycle = await nextValue(
      currentCycleProvider,
      where: (c) => c.resetDay == 15,
    );
    expect(cycle.start, DateTime(2026, 10, 15));
    expect(cycle.end, DateTime(2026, 11, 15));
    final days = await nextValue(
      cycleDailySpendProvider,
      where: (d) => d.first.day == DateTime(2026, 10, 15),
    );
    expect(days, hasLength(31));
  });

  test('reconciler logs untracked spending and keeps the result', () async {
    final result = await container
        .read(balanceReconcilerProvider.notifier)
        .reconcile(1490000);
    expect(result.deltaMinor, -10000);
    expect(container.read(balanceReconcilerProvider), same(result));
    final metrics = await nextValue(
      burnRateProvider,
      where: (m) => m.trueSpendableMinor == 1490000,
    );
    expect(metrics.leftTodayMinor, metrics.dailyLimitMinor - 10000);
  });

  test('resume sync shows rows written behind Drift\'s back', () async {
    var balance = await nextValue(trueLiquidBalanceProvider);
    expect(balance.bankBalanceMinor, 1500000);

    // What the Android UPI listener does from its own process.
    await db.customStatement(
      "INSERT INTO transactions VALUES ('t-upi', 'Blinkit', 250.0, 250.0, "
      "'Groceries', 1, 'ANDROID_UPI_AUTO', NULL, ?)",
      [DateTime(2026, 10, 28, 12).millisecondsSinceEpoch ~/ 1000],
    );
    await db.customStatement(
      'UPDATE budget_config SET current_bank_balance = current_bank_balance - 250 '
      'WHERE id = 1',
    );
    await pumpEventQueue();
    expect(
      container.read(trueLiquidBalanceProvider).value!.bankBalanceMinor,
      1500000,
      reason: 'Drift has not noticed yet',
    );

    await container.read(ledgerSyncProvider).onForeground();
    balance = await nextValue(
      trueLiquidBalanceProvider,
      where: (b) => b.bankBalanceMinor != 1500000,
    );
    expect(balance.bankBalanceMinor, 1475000);
    final metrics = await nextValue(
      burnRateProvider,
      where: (m) => m.trueSpendableMinor == 1475000,
    );
    expect(metrics.leftTodayMinor, metrics.dailyLimitMinor - 25000);
  });

  test('resume sync charges recurring bills that fell due', () async {
    await db.subscriptionsDao.addSubscription(
      name: 'Wi-Fi',
      amountMinor: 90000,
      myShareMinor: 30000,
      billingDate: DateTime(2026, 10, 1, 9),
      splitGroup: const [
        SplitGroupMember(friendId: 'k', friendName: 'Kabir'),
        SplitGroupMember(friendId: 'm', friendName: 'Meera'),
      ],
    );
    await container.read(ledgerSyncProvider).onForeground();
    final summary = await db.ledgerDao.financialSummary();
    expect(summary.owedToMeMinor, 60000);
    expect(summary.totalPersonalSpendMinor, 30000);
  });

  test('currentDay rolls over at local midnight', () {
    fakeAsync((async) {
      final start = DateTime(2026, 10, 31, 23, 58);
      final clock = ProviderContainer(
        overrides: [
          clockProvider.overrideWithValue(() => start.add(async.elapsed)),
        ],
      );
      final days = <DateTime>[];
      final sub = clock.listen(
        currentDayProvider,
        (_, next) => next.whenData(days.add),
        fireImmediately: true,
      );
      async.flushMicrotasks();
      expect(days, [DateTime(2026, 10, 31)]);

      async.elapse(const Duration(minutes: 3));
      expect(days, [DateTime(2026, 10, 31), DateTime(2026, 11, 1)]);

      async.elapse(const Duration(days: 1));
      expect(days.last, DateTime(2026, 11, 2));
      sub.close();
      clock.dispose();
    });
  });
}
