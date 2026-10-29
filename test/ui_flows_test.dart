import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:splitburn/core/database/app_database.dart';
import 'package:splitburn/domain/expense_draft.dart';

import 'support/app_harness.dart';

const rahul = FriendRef(
  id: 'f-rahul',
  name: 'Rahul',
  paymentHandle: 'rahul@okaxis',
);
const priya = FriendRef(id: 'f-priya', name: 'Priya');

Future<void> _dinner(AppDatabase db) => db.ledgerDao.logExpense(
  ExpenseDraft.equalSplit(
    merchant: 'Pizza',
    totalMinor: 90000,
    friends: const [rahul, priya],
    category: TxnCategory.food,
    createdAt: DateTime(2026, 10, 27, 20),
  ),
);

Finder _nav(String label) =>
    find.descendant(of: find.byType(NavigationBar), matching: find.text(label));

void main() {
  testWidgets('command bar: phrase → preview → logged as a net-share split', (
    tester,
  ) async {
    final app = await AppHarness.start(tester);
    await app.enter(
      find.byKey(const Key('command-bar')),
      "Spent 450 on Domino's with Rahul and Priya",
    );
    expect(find.byKey(const Key('command-preview')), findsOneWidget);
    expect(find.textContaining('split 3 ways · ₹150 each'), findsOneWidget);

    await app.tap(find.byKey(const Key('command-log')));
    await app.settle(() => app.text('true-spendable') == '₹14,550');

    final txns = await tester.runAsync(
      () => app.db.select(app.db.transactions).get(),
    );
    expect(txns!.single.myShare, 150.0);
    final splits = await tester.runAsync(
      () => app.db.select(app.db.splitEntries).get(),
    );
    expect(splits!.map((s) => s.friendName).toSet(), {'Rahul', 'Priya'});
    expect(
      find.textContaining('your share ₹150'),
      findsOneWidget,
      reason: 'snackbar',
    );
    await app.dispose();
  });

  testWidgets(
    'command bar: a bill too small to split explains, never crashes',
    (tester) async {
      final app = await AppHarness.start(tester);
      await app.enter(
        find.byKey(const Key('command-bar')),
        'Rahul paid 0.01 for chai with Priya',
      );
      expect(tester.takeException(), isNull);
      expect(find.textContaining('no share for you'), findsOneWidget);

      await app.tap(find.byKey(const Key('command-log')));
      await app.settle();
      final txns = await tester.runAsync(
        () => app.db.select(app.db.transactions).get(),
      );
      expect(txns, isEmpty, reason: 'nothing logged');
      await app.dispose();
    },
  );

  testWidgets(
    'split sheet: equal split with a new friend, exact mode validation',
    (tester) async {
      final app = await AppHarness.start(tester);
      await app.tap(find.byKey(const Key('add-expense')));
      await app.enter(find.byKey(const Key('split-amount')), '1200');
      await app.enter(
        find.byKey(const Key('split-merchant')),
        'Barbeque Nation',
      );
      await app.tap(find.byKey(const Key('add-friend')));
      await app.enter(find.byKey(const Key('friend-name')), 'Rahul');
      await app.tap(find.byKey(const Key('friend-add')));
      expect(find.byKey(const Key('split-summary')), findsOneWidget);
      expect(find.textContaining('Only your ₹600 counts'), findsOneWidget);

      await app.tap(find.text('Exact'));
      await app.enter(find.byKey(const Key('exact-You')), '500');
      expect(app.text('split-error'), contains('₹700 left'));
      await app.enter(find.byKey(const Key('exact-Rahul')), '700');
      expect(find.byKey(const Key('split-error')), findsNothing);

      await app.tap(find.byKey(const Key('split-save')));
      await app.settle(
        () => find.byKey(const Key('split-save')).evaluate().isEmpty,
      );
      final txn = (await tester.runAsync(
        () => app.db.select(app.db.transactions).getSingle(),
      ))!;
      expect(txn.totalPaid, 1200.0);
      expect(txn.myShare, 500.0);
      final split = (await tester.runAsync(
        () => app.db.select(app.db.splitEntries).getSingle(),
      ))!;
      expect(split.friendName, 'Rahul');
      expect(split.amount, 700.0);
      await app.dispose();
    },
  );

  testWidgets('friends: balances, friend detail and the Nudge Bot meme card', (
    tester,
  ) async {
    final app = await AppHarness.start(tester, seed: _dinner);
    await app.tap(_nav('Friends'));
    await app.settle(
      () => find.byKey(const Key('friend-Rahul')).evaluate().isNotEmpty,
    );
    expect(app.text('total-owed-to-me'), 'OWED TO YOU');
    expect(find.text('₹600'), findsWidgets);

    await app.tap(find.byKey(const Key('friend-Rahul')));
    await app.settle(() => app.text('friend-net') == '₹300');
    await app.tap(find.byKey(const Key('open-nudge')));
    expect(app.text('nudge-text'), startsWith('Hey Rahul!'));
    expect(
      app.text('nudge-text'),
      contains('#/l/'),
      reason: 'zero-install settle link',
    );

    await app.tap(find.text('Broke meme'));
    expect(find.text('Nutrition Facts'), findsOneWidget);
    await app.tap(find.text('1st-of-month'));
    expect(find.text('OCTOBER TAB'), findsOneWidget);
    await app.dispose();
  });

  testWidgets('group settle-up: two payers, simplified transfers, recorded', (
    tester,
  ) async {
    final app = await AppHarness.start(tester);
    await app.tap(_nav('Friends'));
    await app.tap(find.byKey(const Key('group-settle')));
    expect(find.text('Group settle-up'), findsWidgets);
    expect(
      find.text('Add amounts and who paid to see the transfers.'),
      findsOneWidget,
    );
    await app.dispose();
  });

  testWidgets('bills: shield a trial, countdown, bury it in the graveyard', (
    tester,
  ) async {
    final app = await AppHarness.start(tester);
    await app.tap(_nav('Bills'));
    await app.tap(find.byKey(const Key('add-bill')));
    await app.enter(find.byKey(const Key('bill-name')), 'Apple Music');
    await app.enter(find.byKey(const Key('bill-amount')), '119');
    await app.tap(find.byKey(const Key('bill-save')));
    await app.settle(
      () => find.byKey(const Key('trial-Apple Music')).evaluate().isNotEmpty,
    );
    expect(app.reminders.scheduled, contains('Apple Music'));
    expect(app.text('countdown-Apple Music'), startsWith('Charges in'));

    await app.tap(find.byKey(const Key('buried-Apple Music')));
    await app.settle(
      () => find.text('R.I.P. Apple Music').evaluate().isNotEmpty,
    );
    expect(find.textContaining('saved ₹119'), findsOneWidget);
    expect(app.reminders.cancelled, hasLength(1));
    await app.dispose();
  });

  testWidgets('settings: payment handle validation and bank reconcile', (
    tester,
  ) async {
    final app = await AppHarness.start(tester);
    await app.tap(_nav('Settings'));
    await app.enter(find.byKey(const Key('owner-name')), 'Adithya');
    await app.enter(find.byKey(const Key('owner-handle')), 'not a handle');
    await app.tap(find.byKey(const Key('owner-save')));
    expect(find.textContaining('Use a UPI ID'), findsOneWidget);
    await app.enter(find.byKey(const Key('owner-handle')), 'adithya@okaxis');
    await app.tap(find.byKey(const Key('owner-save')));
    final config = (await tester.runAsync(() => app.db.budgetDao.config()))!;
    expect(config.ownerPaymentHandle, 'adithya@okaxis');

    await app.tap(find.byKey(const Key('reconcile')));
    await app.enter(find.byKey(const Key('reconcile-amount')), '14500');
    await app.tap(find.text('Match'));
    await app.settle(
      () => find.textContaining('untracked spending').evaluate().isNotEmpty,
    );
    final summary = (await tester.runAsync(
      () => app.db.ledgerDao.financialSummary(),
    ))!;
    expect(summary.bankBalanceMinor, 1450000);
    expect(summary.totalPersonalSpendMinor, 50000);
    await app.dispose();
  });

  testWidgets('survival mode turns the hero red and names the broke date', (
    tester,
  ) async {
    final app = await AppHarness.start(
      tester,
      seed: (db) async {
        await (db.update(db.budgetConfig)..where((c) => c.id.equals(1))).write(
          const BudgetConfigCompanion(currentBankBalance: Value(2000.0)),
        );
        // ₹100/day for the 7 days ending "today" (10 Oct): ₹1,300 left lasts
        // 13 days, but the allowance is 22 days away.
        for (var day = 4; day <= 10; day++) {
          await db.ledgerDao.logExpense(
            ExpenseDraft(
              merchant: 'Canteen',
              totalPaidMinor: 10000,
              myShareMinor: 10000,
              payer: const PaidByMe(),
              category: TxnCategory.food,
              createdAt: DateTime(2026, 10, day, 13),
            ),
          );
        }
      },
      now: DateTime(2026, 10, 10, 15),
    );
    await app.settle(() => find.text('SURVIVAL MODE').evaluate().isNotEmpty);
    expect(find.text('SURVIVAL MODE'), findsOneWidget);
    expect(find.textContaining('₹0 on Fri 23 Oct'), findsOneWidget);
    await app.dispose();
  });
}
