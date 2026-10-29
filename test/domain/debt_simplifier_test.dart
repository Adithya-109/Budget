import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:splitburn/domain/debt_simplifier.dart';

Debt<String> d(String from, String to, int amount) =>
    Debt(from: from, to: to, amountMinor: amount);

/// Applies [transfers] to [balances] and checks everyone ends at zero.
void expectSettles(Map<String, int> balances, List<Debt<String>> transfers) {
  final after = Map.of(balances);
  for (final t in transfers) {
    expect(t.amountMinor, greaterThan(0));
    after[t.from] = (after[t.from] ?? 0) + t.amountMinor;
    after[t.to] = (after[t.to] ?? 0) - t.amountMinor;
  }
  expect(after.values.every((v) => v == 0), isTrue, reason: '$after');
}

/// Brute-force minimum: n − (max zero-sum partition count), by recursion.
int bruteForceMinimum(List<int> amounts) {
  final nonZero = amounts.where((a) => a != 0).toList();
  int best(List<int> rest) {
    if (rest.isEmpty) return 0;
    // Remove the smallest zero-sum subset containing rest[0], recursively.
    var result = 1 << 30;
    final first = rest[0];
    final others = rest.sublist(1);
    for (var mask = 0; mask < 1 << others.length; mask++) {
      var sum = first;
      final picked = <int>[];
      final left = <int>[];
      for (var i = 0; i < others.length; i++) {
        if (mask & (1 << i) != 0) {
          sum += others[i];
          picked.add(i);
        } else {
          left.add(others[i]);
        }
      }
      if (sum == 0) result = min(result, picked.length + best(left));
    }
    return result;
  }

  return best(nonZero);
}

void main() {
  test('A owes B, B owes C → A pays C directly', () {
    final transfers = DebtSimplifier.simplify([
      d('A', 'B', 10000),
      d('B', 'C', 10000),
    ]);
    expect(transfers, [d('A', 'C', 10000)]);
  });

  test('cycles cancel out completely', () {
    expect(
      DebtSimplifier.simplify([
        d('A', 'B', 500),
        d('B', 'C', 500),
        d('C', 'A', 500),
      ]),
      isEmpty,
    );
  });

  test('opposite debts between two people net to one transfer', () {
    expect(DebtSimplifier.simplify([d('A', 'B', 700), d('B', 'A', 200)]), [
      d('A', 'B', 500),
    ]);
  });

  test('finds zero-sum sub-groups greedy matching would miss', () {
    // Greedy largest-first pairs 6→-5 first and needs 4 transfers; the
    // optimum splits {6,-6} and {5,-3,-2} for 3.
    final balances = {'a': 600, 'b': 500, 'c': -600, 'd': -300, 'e': -200};
    final transfers = DebtSimplifier.settleBalances(balances);
    expectSettles(balances, transfers);
    expect(transfers, hasLength(3));
  });

  test('group bills: trip where different people paid', () {
    final debts = DebtSimplifier.debtsFromExpenses([
      const GroupExpense(
        payer: 'me',
        sharesMinor: {'me': 1000, 'rahul': 1000, 'priya': 1000},
      ),
      const GroupExpense(
        payer: 'rahul',
        sharesMinor: {'me': 500, 'rahul': 500, 'priya': 500},
      ),
      const GroupExpense(
        payer: 'priya',
        sharesMinor: {'rahul': 300, 'priya': 300},
      ),
    ]);
    final balances = DebtSimplifier.netBalances(debts);
    expect(balances, {'me': 1500, 'rahul': -300, 'priya': -1200});
    final transfers = DebtSimplifier.simplify(debts);
    expectSettles(balances, transfers);
    expect(transfers, hasLength(2));
  });

  test('ignores zero, self and empty debts; rejects unbalanced input', () {
    expect(
      DebtSimplifier.simplify([d('A', 'A', 100), d('A', 'B', 0)]),
      isEmpty,
    );
    expect(
      () => DebtSimplifier.settleBalances({'a': 100, 'b': -50}),
      throwsArgumentError,
    );
  });

  test('exact solver matches brute force on random groups', () {
    final random = Random(42);
    for (var round = 0; round < 200; round++) {
      final people = 2 + random.nextInt(7);
      final debts = <Debt<String>>[
        for (var i = 0; i < people * 2; i++)
          d(
            'p${random.nextInt(people)}',
            'p${random.nextInt(people)}',
            (1 + random.nextInt(6)) * 100,
          ),
      ];
      final balances = DebtSimplifier.netBalances(debts);
      final transfers = DebtSimplifier.simplify(debts);
      expectSettles(balances, transfers);
      expect(
        transfers.length,
        bruteForceMinimum(balances.values.toList()),
        reason: 'balances: $balances',
      );
    }
  });

  test('large groups use the heuristic and still settle in at most n − 1', () {
    final random = Random(7);
    final balances = <String, int>{};
    var total = 0;
    for (var i = 0; i < 39; i++) {
      final v = (random.nextInt(2000) - 1000) * 10;
      balances['p$i'] = v;
      total += v;
    }
    balances['p39'] = -total;
    balances.removeWhere((_, v) => v == 0);

    final transfers = DebtSimplifier.settleBalances(balances);
    expectSettles(balances, transfers);
    expect(transfers.length, lessThanOrEqualTo(balances.length - 1));
  });

  test(
    'big group of separate sub-groups never needs more than the raw IOUs',
    () {
      // 8 unrelated tables of 3 (24 people, above the exact limit): one person
      // paid for two others at each. Merging them all into one greedy group
      // used to produce up to 23 transfers for 16 IOUs.
      final debts = [
        for (var t = 0; t < 8; t++) ...[
          d('t$t-a', 't$t-payer', 100 * (t + 1)),
          d('t$t-b', 't$t-payer', 70 * (t + 3)),
        ],
      ];
      final transfers = DebtSimplifier.simplify(debts);
      expectSettles(DebtSimplifier.netBalances(debts), transfers);
      expect(transfers, hasLength(16));
      expect(
        transfers.every(
          (t) => t.from.split('-').first == t.to.split('-').first,
        ),
        isTrue,
        reason: 'money stays inside each table',
      );
    },
  );

  test('heuristic pairs exact opposites first', () {
    final balances = {
      for (var i = 0; i < 10; i++) 'c$i': 100 * (i + 1),
      for (var i = 0; i < 10; i++) 'd$i': -100 * (i + 1),
    };
    final transfers = DebtSimplifier.settleBalances(balances, exactLimit: 4);
    expectSettles(balances, transfers);
    expect(transfers, hasLength(10));
  });
}
