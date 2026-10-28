import 'package:flutter_test/flutter_test.dart';
import 'package:splitburn/core/database/app_database.dart';
import 'package:splitburn/core/database/daos/ledger_dao.dart';
import 'package:splitburn/domain/debt_simplifier.dart';
import 'package:splitburn/domain/expense_draft.dart';

import '../support/test_database.dart';

const rahul = FriendRef(
  id: 'f-rahul',
  name: 'Rahul',
  paymentHandle: 'rahul@okaxis',
);
const priya = FriendRef(id: 'f-priya', name: 'Priya');
const aman = FriendRef(id: 'f-aman', name: 'Aman');

void main() {
  late AppDatabase db;
  late LedgerDao ledger;

  setUp(() {
    db = openTestDatabase();
    ledger = db.ledgerDao;
  });

  tearDown(() => db.close());

  Future<FinancialSummaryViewData> summary() => ledger.financialSummary();

  group('fresh database', () {
    test('has the singleton budget row with spec defaults', () async {
      final config = await db.budgetDao.config();
      expect(config.id, 1);
      expect(config.monthlyAllowance, 15000.0);
      expect(config.currentBankBalance, 15000.0);
      expect(config.cycleResetDay, 1);
      expect(config.currencySymbol, '₹');
    });

    test('rejects a second budget row', () async {
      await expectLater(
        db.customStatement('INSERT INTO budget_config (id) VALUES (2)'),
        throwsA(anything),
      );
    });
  });

  group('net-share accounting', () {
    test(
      '₹1,200 dinner for 4 I fronted: only ₹300 is personal spend',
      () async {
        final at = DateTime(2026, 10, 5, 21);
        final id = await ledger.logExpense(
          ExpenseDraft.equalSplit(
            merchant: 'Barbeque Nation',
            totalMinor: 120000,
            friends: const [rahul, priya, aman],
            category: TxnCategory.food,
            createdAt: at,
          ),
        );

        final txn = (await ledger.transactionById(id))!;
        expect(txn.totalPaid, 1200.0);
        expect(txn.myShare, 300.0);
        expect(txn.paidByMe, isTrue);

        final s = await summary();
        expect(s.bankBalanceMinor, 1380000, reason: 'bank −1,200');
        expect(s.totalPersonalSpendMinor, 30000);
        expect(s.owedToMeMinor, 90000, reason: '₹900 floating receivables');
        expect(s.iOweMinor, 0);
        expect(s.trueSpendableCashMinor, 1380000);

        final spend = await ledger.personalSpendBetween(
          DateTime(2026, 10, 1),
          DateTime(2026, 11, 1),
        );
        expect(spend, 30000);
      },
    );

    test(
      'friend repayment restores cash without counting as income or spend',
      () async {
        await ledger.logExpense(
          ExpenseDraft.equalSplit(
            merchant: 'Pizza',
            totalMinor: 120000,
            friends: const [rahul, priya, aman],
            category: TxnCategory.food,
            createdAt: DateTime(2026, 10, 5),
          ),
        );
        final rahulsSplit = (await ledger.openSplits(friendId: rahul.id))
            .single;

        expect(await ledger.settleSplit(rahulsSplit.splitId), isTrue);
        expect(
          await ledger.settleSplit(rahulsSplit.splitId),
          isFalse,
          reason: 'settling twice must not double-credit',
        );

        final s = await summary();
        expect(s.bankBalanceMinor, 1380000 + 30000);
        expect(s.owedToMeMinor, 60000);
        expect(s.totalPersonalSpendMinor, 30000, reason: 'spend unchanged');
      },
    );

    test('friend paid: bank untouched, my share becomes a payable', () async {
      await ledger.logExpense(
        ExpenseDraft.equalSplit(
          merchant: 'Auto to campus',
          totalMinor: 12000,
          friends: const [priya],
          payer: const PaidByFriend(priya),
          category: TxnCategory.transit,
          createdAt: DateTime(2026, 10, 6),
        ),
      );
      var s = await summary();
      expect(s.bankBalanceMinor, 1500000);
      expect(s.iOweMinor, 6000);
      expect(s.totalPersonalSpendMinor, 6000);
      expect(s.trueSpendableCashMinor, 1500000 - 6000);

      final split = (await ledger.openSplits()).single;
      expect(split.direction, SplitDirection.iOwe);
      await ledger.settleSplit(split.splitId);

      s = await summary();
      expect(s.bankBalanceMinor, 1500000 - 6000);
      expect(s.iOweMinor, 0);
      expect(
        s.trueSpendableCashMinor,
        1500000 - 6000,
        reason: 'paying a debt does not change true spendable cash',
      );
    });

    test('unsettle reverses the settlement cash', () async {
      await ledger.logExpense(
        ExpenseDraft.equalSplit(
          merchant: 'Coffee',
          totalMinor: 24000,
          friends: const [rahul],
          category: TxnCategory.food,
        ),
      );
      final split = (await ledger.openSplits()).single;
      await ledger.settleSplit(split.splitId);
      expect(await ledger.unsettleSplit(split.splitId), isTrue);
      final s = await summary();
      expect(s.bankBalanceMinor, 1500000 - 24000);
      expect(s.owedToMeMinor, 12000);
    });

    test('settle all with a friend moves only the net cash', () async {
      await ledger.logExpense(
        ExpenseDraft.equalSplit(
          merchant: 'Groceries',
          totalMinor: 100000,
          friends: const [rahul],
          category: TxnCategory.groceries,
        ),
      ); // Rahul owes 500
      await ledger.logExpense(
        ExpenseDraft.equalSplit(
          merchant: 'Movie',
          totalMinor: 40000,
          friends: const [rahul],
          payer: const PaidByFriend(rahul),
          category: TxnCategory.fun,
        ),
      ); // I owe Rahul 200

      final balance = (await ledger.friendBalances()).single;
      expect(balance.netMinor, 30000);
      expect(balance.openSplitCount, 2);
      expect(balance.friend.paymentHandle, 'rahul@okaxis');

      final result = await ledger.settleAllWithFriend(rahul.id);
      expect(result.settledCount, 2);
      expect(result.bankDeltaMinor, 30000);

      final s = await summary();
      expect(s.bankBalanceMinor, 1500000 - 100000 + 30000);
      expect(s.owedToMeMinor, 0);
      expect(s.iOweMinor, 0);
      expect((await ledger.friendBalances()).single.isSettledUp, isTrue);
    });

    test('deleting a transaction undoes payment and settlements', () async {
      final id = await ledger.logExpense(
        ExpenseDraft.equalSplit(
          merchant: 'Typo',
          totalMinor: 90000,
          friends: const [rahul, priya],
          category: TxnCategory.food,
        ),
      );
      final first = (await ledger.openSplits()).first;
      await ledger.settleSplit(first.splitId);

      await ledger.deleteTransaction(id);

      final s = await summary();
      expect(s.bankBalanceMinor, 1500000);
      expect(s.owedToMeMinor, 0);
      expect(s.totalPersonalSpendMinor, 0);
      expect(await db.select(db.splitEntries).get(), isEmpty);
    });

    test('FK cascade removes splits even when deleted with raw SQL', () async {
      final id = await ledger.logExpense(
        ExpenseDraft.equalSplit(
          merchant: 'Chai',
          totalMinor: 6000,
          friends: const [aman],
          category: TxnCategory.food,
        ),
      );
      await db.customStatement('DELETE FROM transactions WHERE id = ?', [id]);
      expect(await db.select(db.splitEntries).get(), isEmpty);
    });

    test(
      'resplit turns an auto-captured UPI payment into a group bill',
      () async {
        final at = DateTime(2026, 10, 9, 13, 30);
        final id = await ledger.logExpense(
          ExpenseDraft(
            merchant: "Domino's",
            totalPaidMinor: 45000,
            myShareMinor: 45000,
            payer: const PaidByMe(),
            category: TxnCategory.food,
            source: TxnSource.androidUpiAuto,
            createdAt: at,
          ),
        );
        await ledger.resplitTransaction(
          id,
          ExpenseDraft.equalSplit(
            merchant: "Domino's",
            totalMinor: 45000,
            friends: const [rahul, priya],
            category: TxnCategory.food,
          ),
        );

        final txn = (await ledger.transactionById(id))!;
        expect(txn.myShare, 150.0);
        expect(txn.source, TxnSource.androidUpiAuto);
        expect(txn.createdAt, at);
        final s = await summary();
        expect(
          s.bankBalanceMinor,
          1500000 - 45000,
          reason: 'charged once, not twice',
        );
        expect(s.owedToMeMinor, 30000);
      },
    );

    test('category breakdown sums my share, not the bill', () async {
      final start = DateTime(2026, 10, 1);
      final end = DateTime(2026, 11, 1);
      await ledger.logExpense(
        ExpenseDraft.equalSplit(
          merchant: 'Dinner',
          totalMinor: 120000,
          friends: const [rahul, priya, aman],
          category: TxnCategory.food,
          createdAt: DateTime(2026, 10, 2),
        ),
      );
      await ledger.logExpense(
        ExpenseDraft(
          merchant: 'Metro card',
          totalPaidMinor: 50000,
          myShareMinor: 50000,
          payer: const PaidByMe(),
          category: TxnCategory.transit,
          createdAt: DateTime(2026, 10, 3),
        ),
      );
      await ledger.logExpense(
        ExpenseDraft(
          merchant: 'Last month',
          totalPaidMinor: 99900,
          myShareMinor: 99900,
          payer: const PaidByMe(),
          category: TxnCategory.food,
          createdAt: DateTime(2026, 9, 30),
        ),
      );

      final breakdown = await ledger.watchCategorySpend(start, end).first;
      expect(breakdown, {TxnCategory.transit: 50000, TxnCategory.food: 30000});
    });

    test('daily spend is zero-filled per local day', () async {
      await ledger.logExpense(
        ExpenseDraft(
          merchant: 'Breakfast',
          totalPaidMinor: 8000,
          myShareMinor: 8000,
          payer: const PaidByMe(),
          category: TxnCategory.food,
          createdAt: DateTime(2026, 10, 1, 8),
        ),
      );
      await ledger.logExpense(
        ExpenseDraft(
          merchant: 'Dinner',
          totalPaidMinor: 40000,
          myShareMinor: 20000,
          payer: const PaidByMe(),
          category: TxnCategory.food,
          friendShares: {rahul: 20000},
          createdAt: DateTime(2026, 10, 1, 21),
        ),
      );
      await ledger.logExpense(
        ExpenseDraft(
          merchant: 'Snacks',
          totalPaidMinor: 5000,
          myShareMinor: 5000,
          payer: const PaidByMe(),
          category: TxnCategory.food,
          createdAt: DateTime(2026, 10, 3, 17),
        ),
      );

      final days = await ledger.dailyPersonalSpend(
        DateTime(2026, 10, 1),
        DateTime(2026, 10, 4),
      );
      expect(days.map((d) => d.personalSpendMinor), [28000, 0, 5000]);
      expect(days.first.day, DateTime(2026, 10, 1));
    });

    test(
      'summary stream reacts to writes and to external-write sync',
      () async {
        final values = <int>[];
        final sub = ledger.watchFinancialSummary().listen(
          (s) => values.add(s.bankBalanceMinor),
        );
        await pumpEventQueue();

        await ledger.logExpense(
          ExpenseDraft(
            merchant: 'Xerox',
            totalPaidMinor: 2000,
            myShareMinor: 2000,
            payer: const PaidByMe(),
            category: TxnCategory.other,
          ),
        );
        await pumpEventQueue();

        // Simulates a write by Swift/Kotlin that Drift's stream can't see.
        await db.customStatement(
          'UPDATE budget_config SET current_bank_balance = 100.0 WHERE id = 1',
        );
        db.syncExternalWrites();
        await pumpEventQueue();
        await sub.cancel();

        expect(values, [1500000, 1498000, 10000]);
      },
    );
  });

  group('social ledger', () {
    test('friend directory uses latest name and handle; lookup is case-insensitive', () async {
      await ledger.logExpense(
        ExpenseDraft.equalSplit(
          merchant: 'Old',
          totalMinor: 2000,
          friends: const [FriendRef(id: 'f-priya', name: 'priya')],
          category: TxnCategory.food,
          createdAt: DateTime(2026, 9, 1),
        ),
      );
      await ledger.logExpense(
        ExpenseDraft.equalSplit(
          merchant: 'New',
          totalMinor: 2000,
          friends: const [
            FriendRef(
              id: 'f-priya',
              name: 'Priya S',
              paymentHandle: 'priya@ybl',
            ),
          ],
          category: TxnCategory.food,
          createdAt: DateTime(2026, 10, 1),
        ),
      );

      final friend = (await ledger.friendBalances()).single.friend;
      expect(friend.name, 'Priya S');
      expect(friend.paymentHandle, 'priya@ybl');
      expect((await ledger.findFriendByName('PRIYA s'))?.id, 'f-priya');
      expect(await ledger.findFriendByName('Nobody'), isNull);
    });

    test('open debt graph feeds the simplifier', () async {
      await ledger.logExpense(
        ExpenseDraft.equalSplit(
          merchant: 'Trip fuel',
          totalMinor: 90000,
          friends: const [rahul, priya],
          category: TxnCategory.transit,
        ),
      );
      await ledger.logExpense(
        ExpenseDraft.equalSplit(
          merchant: 'Trip stay',
          totalMinor: 60000,
          friends: const [rahul],
          payer: const PaidByFriend(rahul),
          category: TxnCategory.fun,
        ),
      );

      final graph = await ledger.openDebtGraph();
      final balances = DebtSimplifier.netBalances(graph);
      // Rahul owes me 300 and I owe Rahul 300: he nets out entirely.
      expect(balances, {kSelfId: 30000, priya.id: -30000});
      final transfers = DebtSimplifier.simplify(graph);
      expect(transfers, [
        Debt(from: priya.id, to: kSelfId, amountMinor: 30000),
      ]);
    });
  });
}
