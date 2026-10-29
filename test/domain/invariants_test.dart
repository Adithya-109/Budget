import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:splitburn/domain/debt_simplifier.dart';
import 'package:splitburn/domain/expense_draft.dart';
import 'package:splitburn/domain/expense_phrase_parser.dart';
import 'package:splitburn/domain/split_calculator.dart';

/// Property checks over random inputs: the contracts every caller (command
/// bar, App Intent, split sheet, group settle-up) relies on.
void main() {
  group('ExpensePhraseParser fuzz', () {
    const vocabulary = [
      'spent',
      'paid',
      'by',
      'on',
      'for',
      'at',
      'with',
      'and',
      '&',
      ',',
      'split',
      'between',
      'me',
      'us',
      'the',
      'a',
      "Domino's",
      'chai',
      'auto',
      'Uber',
      'rent',
      'Rahul',
      'priya',
      'AMAN',
      'Zoya-Khan',
      "o'neil",
      '450',
      '1,200',
      '1,20,000',
      '45.50',
      '1.2k',
      '₹99',
      'Rs.',
      'rs',
      'INR',
      r'$',
      'bucks',
      '0',
      '0.01',
      '-50',
      '12abc',
      '99999999999',
      '.',
      '..',
      '!!',
      '🍕',
      'नमस्ते',
      '\t',
      '  ',
      '(',
      ')',
      '@',
      '#',
    ];

    test('random phrases never throw and parse to usable drafts', () {
      final rng = Random(2026);
      var parsedCount = 0;
      for (var i = 0; i < 20000; i++) {
        final words = List.generate(
          rng.nextInt(12),
          (_) => vocabulary[rng.nextInt(vocabulary.length)],
        );
        final phrase = words.join(rng.nextBool() ? ' ' : '  ');
        final parsed = ExpensePhraseParser.parse(phrase);
        if (parsed == null) continue;
        parsedCount++;
        final reason = '"$phrase" → $parsed';

        expect(parsed.amountMinor, greaterThan(0), reason: reason);
        expect(parsed.merchant.trim(), isNotEmpty, reason: reason);
        final lowerFriends = parsed.friends.map((f) => f.toLowerCase());
        expect(
          lowerFriends.toSet().length,
          parsed.friends.length,
          reason: 'friends are unique: $reason',
        );
        expect(
          parsed.friends.every((f) => f.trim().isNotEmpty),
          isTrue,
          reason: reason,
        );
        if (parsed.payer != null) {
          expect(parsed.friends, contains(parsed.payer), reason: reason);
        }

        // Equal split always covers the bill exactly; the only refusal is a
        // friend-paid bill too small to leave the user a share.
        try {
          final draft = parsed.toDraft(
            resolveFriend: (n) => FriendRef(id: n.toLowerCase(), name: n),
          );
          final friendTotal = draft.friendShares.values.fold(
            0,
            (a, b) => a + b,
          );
          expect(draft.myShareMinor + friendTotal, parsed.amountMinor);
          expect(draft.friendShares.length, parsed.friends.length);
        } on ArgumentError {
          expect(parsed.payer, isNotNull, reason: reason);
          expect(
            parsed.amountMinor,
            lessThan(parsed.friends.length + 1),
            reason: reason,
          );
        }
      }
      expect(parsedCount, greaterThan(5000), reason: 'fuzz reaches the parser');
    });
  });

  group('SplitCalculator', () {
    test('allocate is exact, fair to the paisa and order-stable', () {
      final rng = Random(11);
      for (var i = 0; i < 5000; i++) {
        final n = 1 + rng.nextInt(8);
        final weights = {
          for (var k = 0; k < n; k++)
            'p$k': rng.nextInt(10) == 0 ? 0 : 1 + rng.nextInt(100000),
        };
        if (weights.values.every((w) => w == 0)) weights['p0'] = 1;
        final total = rng.nextInt(3000000) - (rng.nextBool() ? 500000 : 0);
        final shares = SplitCalculator.allocate(total, weights);
        final weightSum = weights.values.fold(0, (a, b) => a + b);

        expect(shares.values.fold(0, (a, b) => a + b), total);
        expect(shares.keys, weights.keys);
        for (final MapEntry(key: k, value: share) in shares.entries) {
          final ideal = total * weights[k]! / weightSum;
          expect((share - ideal).abs(), lessThan(1), reason: '$k of $total');
          if (weights[k] == 0) expect(share, 0);
        }
      }
    });

    test('equal splits differ by at most one paisa, payer first', () {
      final rng = Random(12);
      for (var i = 0; i < 5000; i++) {
        final n = 1 + rng.nextInt(12);
        final total = rng.nextInt(10000000);
        final people = [for (var k = 0; k < n; k++) 'p$k'];
        final shares = SplitCalculator.equal(total, people);
        expect(shares.values.fold(0, (a, b) => a + b), total);
        final values = shares.values.toList();
        expect(values.reduce(max) - values.reduce(min), lessThanOrEqualTo(1));
        expect(
          shares['p0'],
          values.reduce(max),
          reason: 'payer absorbs rounding',
        );
      }
    });

    test('itemized receipts always add up to items + extras', () {
      final rng = Random(13);
      for (var i = 0; i < 3000; i++) {
        final people = [for (var k = 0; k < 1 + rng.nextInt(6); k++) 'p$k'];
        final items = [
          for (var j = 0; j < 1 + rng.nextInt(10); j++)
            ReceiptLine(
              label: 'item $j',
              priceMinor: rng.nextInt(80000),
              sharedBy: ([
                ...people,
              ]..shuffle(rng)).take(1 + rng.nextInt(people.length)).toList(),
            ),
        ];
        final itemsTotal = items.fold(0, (s, l) => s + l.priceMinor);
        // Tax + tip, or a discount no bigger than the items.
        final extras = rng.nextBool()
            ? rng.nextInt(20000)
            : -rng.nextInt(itemsTotal ~/ 2 + 1);
        final split = SplitCalculator.itemized(
          items,
          extrasMinor: itemsTotal == 0 ? 0 : extras,
        );
        final sum = split.totalsMinor.values.fold(0, (a, b) => a + b);
        expect(sum, itemsTotal + (itemsTotal == 0 ? 0 : extras));
        expect(split.totalsMinor.values.every((t) => t >= 0), isTrue);
        // Nobody who claimed nothing pays tax.
        for (final p in people) {
          if (!items.any((l) => l.sharedBy.contains(p))) {
            expect(split.totalsMinor.containsKey(p), isFalse);
          }
        }
      }
    });
  });

  group('DebtSimplifier', () {
    void checkInvariants(List<Debt<String>> debts, {int? exactLimit}) {
      final balances = DebtSimplifier.netBalances(debts);
      final transfers = exactLimit == null
          ? DebtSimplifier.simplify(debts)
          : DebtSimplifier.simplify(debts, exactLimit: exactLimit);
      final reason = '$balances';

      final after = Map.of(balances);
      for (final t in transfers) {
        expect(t.amountMinor, greaterThan(0), reason: reason);
        expect(t.from, isNot(t.to), reason: reason);
        // Only people with a non-zero balance move money, and only in the
        // direction of their balance: debtors pay, creditors receive.
        expect(balances[t.from], lessThan(0), reason: reason);
        expect(balances[t.to], greaterThan(0), reason: reason);
        after[t.from] = after[t.from]! + t.amountMinor;
        after[t.to] = after[t.to]! - t.amountMinor;
      }
      expect(after.values.every((v) => v == 0), isTrue, reason: reason);
      if (balances.isNotEmpty) {
        expect(transfers.length, lessThanOrEqualTo(balances.length - 1));
      }
      expect(transfers.length, lessThanOrEqualTo(debts.length));
      // Nobody pays more than they owe in total.
      final moved = transfers.fold(0, (s, t) => s + t.amountMinor);
      final owed = balances.values.where((v) => v > 0).fold(0, (a, b) => a + b);
      expect(moved, owed, reason: reason);
    }

    test('exact and heuristic settlements respect every invariant', () {
      final rng = Random(99);
      for (var i = 0; i < 1500; i++) {
        final people = 2 + rng.nextInt(i.isEven ? 8 : 30);
        final debts = [
          for (var k = 0; k < 1 + rng.nextInt(people * 3); k++)
            Debt(
              from: 'p${rng.nextInt(people)}',
              to: 'p${rng.nextInt(people)}',
              amountMinor: rng.nextInt(5) == 0 ? 0 : 1 + rng.nextInt(500000),
            ),
        ];
        checkInvariants(debts);
        checkInvariants(debts, exactLimit: 2);
      }
    });

    test('exact never uses more transfers than the heuristic', () {
      final rng = Random(5);
      for (var i = 0; i < 500; i++) {
        final people = 3 + rng.nextInt(9);
        final debts = [
          for (var k = 0; k < people * 2; k++)
            Debt(
              from: 'p${rng.nextInt(people)}',
              to: 'p${rng.nextInt(people)}',
              amountMinor: (1 + rng.nextInt(8)) * 5000,
            ),
        ];
        expect(
          DebtSimplifier.simplify(debts).length,
          lessThanOrEqualTo(
            DebtSimplifier.simplify(debts, exactLimit: 0).length,
          ),
        );
      }
    });

    test('15 people solve exactly and quickly', () {
      final balances = {
        for (var i = 0; i < 14; i++)
          'p$i': (i.isEven ? 1 : -1) * (i + 1) * 1000,
      };
      balances['p14'] = -balances.values.fold(0, (a, b) => a + b);
      final watch = Stopwatch()..start();
      final transfers = DebtSimplifier.settleBalances(balances);
      watch.stop();
      expect(watch.elapsed, lessThan(const Duration(seconds: 2)));
      expect(transfers.length, lessThanOrEqualTo(14));
    });
  });
}
