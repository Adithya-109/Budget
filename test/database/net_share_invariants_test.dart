import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:splitburn/core/database/app_database.dart';
import 'package:splitburn/core/database/daos/ledger_dao.dart';
import 'package:splitburn/domain/expense_draft.dart';

import '../support/test_database.dart';

const _friends = [
  FriendRef(id: 'f-rahul', name: 'Rahul'),
  FriendRef(id: 'f-priya', name: 'Priya'),
  FriendRef(id: 'f-aman', name: 'Aman'),
  FriendRef(id: 'f-zoya', name: 'Zoya'),
];
const _startingBankMinor = 1500000;

class _ModelSplit {
  _ModelSplit(this.id, this.friendId, this.amountMinor, this.direction);

  final String id;
  final String friendId;
  final int amountMinor;
  final SplitDirection direction;
  bool settled = false;

  /// Cash this split moved once settled (CLAUDE.md write contract).
  int get settledCashMinor => !settled
      ? 0
      : direction == SplitDirection.owesMe
      ? amountMinor
      : -amountMinor;
}

class _ModelTxn {
  _ModelTxn(this.draft, this.splits);

  final ExpenseDraft draft;
  final List<_ModelSplit> splits;
}

/// Reference model of the write contract, kept by hand alongside the DB.
class _Model {
  final txns = <String, _ModelTxn>{};

  Iterable<_ModelSplit> get splits => txns.values.expand((t) => t.splits);

  int get bankMinor =>
      _startingBankMinor -
      txns.values
          .where((t) => t.draft.paidByMe)
          .fold<int>(0, (s, t) => s + t.draft.totalPaidMinor) +
      splits.fold<int>(0, (s, x) => s + x.settledCashMinor);

  int get personalSpendMinor =>
      txns.values.fold<int>(0, (s, t) => s + t.draft.myShareMinor);

  int open(SplitDirection d, {String? friendId}) => splits
      .where(
        (x) =>
            !x.settled &&
            x.direction == d &&
            (friendId == null || x.friendId == friendId),
      )
      .fold<int>(0, (s, x) => s + x.amountMinor);
}

/// A random but valid draft: 1–3 friends, uneven shares, odd paise.
ExpenseDraft _randomDraft(Random rng, int n) {
  final people = ([..._friends]..shuffle(rng)).take(1 + rng.nextInt(3));
  final total = 1 + rng.nextInt(rng.nextBool() ? 5000 : 2500000);
  final friendShares = <FriendRef, int>{};
  var left = total;
  for (final f in people) {
    final share = rng.nextInt(left + 1);
    friendShares[f] = share;
    left -= share;
  }
  final paidByFriend = left > 0 && rng.nextInt(3) == 0;
  return ExpenseDraft(
    merchant: 'Bill $n',
    totalPaidMinor: total,
    myShareMinor: left,
    payer: paidByFriend ? PaidByFriend(people.first) : const PaidByMe(),
    category: TxnCategory.values[rng.nextInt(TxnCategory.values.length)],
    friendShares: friendShares,
    createdAt: DateTime(2026, 10, 1 + rng.nextInt(28), rng.nextInt(24)),
  );
}

void main() {
  late AppDatabase db;
  late LedgerDao ledger;

  setUp(() {
    db = openTestDatabase();
    ledger = db.ledgerDao;
  });
  tearDown(() => db.close());

  Future<List<_ModelSplit>> splitsFor(String txnId, ExpenseDraft d) async {
    final rows = await (db.select(
      db.splitEntries,
    )..where((s) => s.transactionId.equals(txnId))).get();
    return [
      for (final r in rows)
        _ModelSplit(r.id, r.friendId, (r.amount * 100).round(), r.direction),
    ];
  }

  Future<void> expectMatches(_Model model, String step) async {
    final s = await ledger.financialSummary();
    expect(s.bankBalanceMinor, model.bankMinor, reason: '$step: bank');
    expect(
      s.totalPersonalSpendMinor,
      model.personalSpendMinor,
      reason: '$step: personal spend',
    );
    expect(
      s.owedToMeMinor,
      model.open(SplitDirection.owesMe),
      reason: '$step: owed to me',
    );
    expect(
      s.iOweMinor,
      model.open(SplitDirection.iOwe),
      reason: '$step: I owe',
    );
    expect(
      s.trueSpendableCashMinor,
      model.bankMinor - model.open(SplitDirection.iOwe),
      reason: '$step: true spendable',
    );
  }

  for (final seed in [1, 2, 3, 4, 5]) {
    test(
      'random ledger history matches the write contract (seed $seed)',
      () async {
        final rng = Random(seed);
        final model = _Model();
        var n = 0;

        for (var step = 0; step < 120; step++) {
          final allSplits = model.splits.toList();
          final op = model.txns.isEmpty ? 0 : rng.nextInt(7);
          String label;
          switch (op) {
            case 0 || 1:
              final draft = _randomDraft(rng, n++);
              final id = await ledger.logExpense(draft);
              model.txns[id] = _ModelTxn(draft, await splitsFor(id, draft));
              label = 'log ${draft.merchant}';
            case 2 when allSplits.isNotEmpty:
              final split = allSplits[rng.nextInt(allSplits.length)];
              expect(await ledger.settleSplit(split.id), !split.settled);
              split.settled = true;
              label = 'settle ${split.id}';
            case 3 when allSplits.isNotEmpty:
              final split = allSplits[rng.nextInt(allSplits.length)];
              expect(await ledger.unsettleSplit(split.id), split.settled);
              split.settled = false;
              label = 'unsettle ${split.id}';
            case 4:
              final friend = _friends[rng.nextInt(_friends.length)];
              final hadOpen = allSplits.any(
                (x) => x.friendId == friend.id && !x.settled,
              );
              final result = await ledger.settleAllWithFriend(friend.id);
              expect(
                result.bankDeltaMinor,
                model.open(SplitDirection.owesMe, friendId: friend.id) -
                    model.open(SplitDirection.iOwe, friendId: friend.id),
              );
              for (final x in allSplits.where((x) => x.friendId == friend.id)) {
                x.settled = true;
              }
              expect(result.settledCount > 0, hadOpen);
              label = 'settle all with ${friend.name}';
            case 5:
              final id = model.txns.keys.elementAt(
                rng.nextInt(model.txns.length),
              );
              final draft = _randomDraft(rng, n++);
              await ledger.resplitTransaction(id, draft);
              model.txns[id] = _ModelTxn(draft, await splitsFor(id, draft));
              label = 're-split $id';
            default:
              final id = model.txns.keys.elementAt(
                rng.nextInt(model.txns.length),
              );
              await ledger.deleteTransaction(id);
              model.txns.remove(id);
              label = 'delete $id';
          }
          await expectMatches(model, 'step $step ($label)');
        }

        // Per-friend balances agree with the model too.
        for (final b in await ledger.friendBalances()) {
          expect(
            b.owedToMeMinor,
            model.open(SplitDirection.owesMe, friendId: b.friend.id),
          );
          expect(
            b.iOweMinor,
            model.open(SplitDirection.iOwe, friendId: b.friend.id),
          );
        }
        // Cycle spend is only my shares.
        expect(
          await ledger.personalSpendBetween(
            DateTime(2026, 10, 1),
            DateTime(2026, 11, 1),
          ),
          model.personalSpendMinor,
        );

        // Deleting everything leaves no trace: the bank is back where it began.
        for (final id in [...model.txns.keys]) {
          await ledger.deleteTransaction(id);
          model.txns.remove(id);
        }
        await expectMatches(model, 'after deleting everything');
        expect(model.bankMinor, _startingBankMinor);
        expect(await db.select(db.splitEntries).get(), isEmpty);
      },
    );
  }

  test(
    'settling never changes personal spend or the category budget',
    () async {
      final rng = Random(42);
      for (var i = 0; i < 20; i++) {
        await ledger.logExpense(_randomDraft(rng, i));
      }
      final before = await ledger.financialSummary();
      for (final split in await ledger.openSplits()) {
        await ledger.settleSplit(split.splitId);
      }
      final after = await ledger.financialSummary();
      expect(after.totalPersonalSpendMinor, before.totalPersonalSpendMinor);
      expect(after.owedToMeMinor, 0);
      expect(after.iOweMinor, 0);
      expect(
        after.bankBalanceMinor,
        before.bankBalanceMinor + before.owedToMeMinor - before.iOweMinor,
        reason: 'receivables come in, payables go out, nothing else moves',
      );
      expect(
        after.trueSpendableCashMinor,
        before.trueSpendableCashMinor + before.owedToMeMinor,
        reason: 'paying what I owe was already counted in true spendable',
      );
    },
  );
}
