import 'package:flutter_test/flutter_test.dart';
import 'package:splitburn/core/database/app_database.dart';
import 'package:splitburn/core/database/daos/ledger_dao.dart';
import 'package:splitburn/domain/budget_cycle.dart';
import 'package:splitburn/domain/burn_rate.dart';
import 'package:splitburn/domain/expense_draft.dart';

import '../support/test_database.dart';

const rahul = FriendRef(id: 'f-rahul', name: 'Rahul');

void main() {
  late AppDatabase db;
  late LedgerDao ledger;

  setUp(() {
    db = openTestDatabase();
    ledger = db.ledgerDao;
  });
  tearDown(() => db.close());

  Future<void> spend(
    int minor,
    DateTime at, {
    List<FriendRef> with_ = const [],
  }) => ledger.logExpense(
    ExpenseDraft.equalSplit(
      merchant: 'Spend',
      totalMinor: minor,
      friends: with_,
      category: TxnCategory.food,
      createdAt: at,
    ),
  );

  group('ledger snapshot windows', () {
    final today = DateTime(2026, 10, 28, 15, 30);
    final cycle = BudgetCycle.containing(today, resetDay: 1);

    test(
      'splits personal spend into before-today, today and the last 7 days',
      () async {
        await spend(50000, DateTime(2026, 9, 30, 23)); // last cycle
        await spend(30000, DateTime(2026, 10, 1)); // cycle start
        await spend(20000, DateTime(2026, 10, 21, 23, 59)); // 8 days ago
        await spend(10000, DateTime(2026, 10, 22)); // first day of the 7
        await spend(
          120000,
          DateTime(2026, 10, 28, 9),
          with_: [rahul],
        ); // ₹600 mine
        await spend(5000, DateTime(2026, 10, 29)); // tomorrow

        final s = await ledger.ledgerSnapshot(cycle: cycle, today: today);
        expect(s.today, DateTime(2026, 10, 28));
        expect(s.spentBeforeTodayMinor, 30000 + 20000 + 10000);
        expect(s.spentTodayMinor, 60000, reason: 'only my share of the ₹1,200');
        expect(s.last7DaysSpendMinor, 10000 + 60000);
        expect(s.owedToMeMinor, 60000);
        expect(s.monthlyAllowanceMinor, 1500000);
        expect(s.currencySymbol, '₹');
        expect(
          s.bankBalanceMinor,
          1500000 - 50000 - 30000 - 20000 - 10000 - 120000 - 5000,
        );
      },
    );

    test('a cycle that starts today has nothing before today', () async {
      final resetToday = BudgetCycle.containing(today, resetDay: 28);
      await spend(40000, DateTime(2026, 10, 27, 12));
      final s = await ledger.ledgerSnapshot(cycle: resetToday, today: today);
      expect(s.spentBeforeTodayMinor, 0);
      expect(s.last7DaysSpendMinor, 40000);
    });

    test(
      'stream re-emits when a friend settles (bank changes, spend does not)',
      () async {
        await spend(120000, DateTime(2026, 10, 28, 9), with_: [rahul]);
        final emitted = <(int, int)>[];
        final sub = ledger
            .watchLedgerSnapshot(cycle: cycle, today: today)
            .listen(
              (s) => emitted.add((s.bankBalanceMinor, s.spentTodayMinor)),
            );
        await pumpEventQueue();
        final split = (await ledger.openSplits()).single;
        await ledger.settleSplit(split.splitId);
        await pumpEventQueue();
        await sub.cancel();
        expect(emitted, [(1380000, 60000), (1440000, 60000)]);
      },
    );

    test('feeds BurnRateMetrics end to end', () async {
      await spend(1340000, DateTime(2026, 10, 5));
      await spend(65000, DateTime(2026, 10, 28, 13));
      final metrics = BurnRateMetrics.fromSnapshot(
        await ledger.ledgerSnapshot(cycle: cycle, today: today),
      );
      expect(metrics.dailyLimitMinor, 40000);
      expect(metrics.leftTodayMinor, -25000);
      expect(metrics.tomorrowLimitMinor, 31666);
    });
  });

  group('reconcileBankBalance', () {
    test(
      'a shortfall becomes an untracked expense and the bank matches',
      () async {
        final result = await ledger.reconcileBankBalance(
          1450000,
          at: DateTime(2026, 10, 28, 20),
        );
        expect(result.deltaMinor, -50000);
        expect(result.untrackedSpendTransactionId, isNotNull);

        final txn = (await ledger.transactionById(
          result.untrackedSpendTransactionId!,
        ))!;
        expect(txn.merchant, LedgerDao.untrackedSpendingMerchant);
        expect(txn.myShare, 500.0);
        final summary = await ledger.financialSummary();
        expect(summary.bankBalanceMinor, 1450000);
        expect(summary.totalPersonalSpendMinor, 50000);
      },
    );

    test('a shortfall can be corrected without counting as spend', () async {
      final result = await ledger.reconcileBankBalance(
        1450000,
        logShortfallAsSpend: false,
      );
      expect(result.untrackedSpendTransactionId, isNull);
      final summary = await ledger.financialSummary();
      expect(summary.bankBalanceMinor, 1450000);
      expect(summary.totalPersonalSpendMinor, 0);
    });

    test('extra money just sets the balance; no change is a no-op', () async {
      var result = await ledger.reconcileBankBalance(1600000);
      expect(result.deltaMinor, 100000);
      expect((await ledger.financialSummary()).bankBalanceMinor, 1600000);

      result = await ledger.reconcileBankBalance(1600000);
      expect(result.deltaMinor, 0);
      expect(await db.select(db.transactions).get(), isEmpty);
    });
  });
}
