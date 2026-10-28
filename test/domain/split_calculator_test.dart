import 'package:flutter_test/flutter_test.dart';
import 'package:splitburn/core/database/enums.dart';
import 'package:splitburn/domain/expense_draft.dart';
import 'package:splitburn/domain/split_calculator.dart';

int _sum(Map<Object?, int> m) => m.values.fold(0, (a, b) => a + b);

void main() {
  group('equal', () {
    test('450 between 3 is 150 each', () {
      expect(SplitCalculator.equal(45000, ['me', 'rahul', 'priya']), {
        'me': 15000,
        'rahul': 15000,
        'priya': 15000,
      });
    });

    test('leftover paisa goes to the first participant (the payer)', () {
      final shares = SplitCalculator.equal(10000, ['me', 'a', 'b']);
      expect(shares, {'me': 3334, 'a': 3333, 'b': 3333});
      expect(_sum(shares), 10000);
    });

    test('rejects empty and duplicate participants', () {
      expect(() => SplitCalculator.equal(100, <String>[]), throwsArgumentError);
      expect(() => SplitCalculator.equal(100, ['a', 'a']), throwsArgumentError);
    });
  });

  group('exact', () {
    test('accepts shares that add up', () {
      expect(SplitCalculator.exact(1000, {'a': 600, 'b': 400}), {
        'a': 600,
        'b': 400,
      });
    });

    test('reports how far off a mismatched split is', () {
      expect(
        () => SplitCalculator.exact(1000, {'a': 600, 'b': 300}),
        throwsA(
          isA<SplitMismatchError>()
              .having((e) => e.expectedMinor, 'expected', 1000)
              .having((e) => e.actualMinor, 'actual', 900),
        ),
      );
    });
  });

  group('percentage', () {
    test('splits by basis points and always sums to the bill', () {
      final shares = SplitCalculator.percentage(99999, {
        'a': 3333,
        'b': 3333,
        'c': 3334,
      });
      expect(_sum(shares), 99999);
      expect(shares, {'a': 33330, 'b': 33330, 'c': 33339});
    });

    test('must total 100%', () {
      expect(
        () => SplitCalculator.percentage(1000, {'a': 5000, 'b': 4000}),
        throwsArgumentError,
      );
    });
  });

  group('itemized receipt', () {
    test('items split among who ate them; tax and tip proportional', () {
      final split = SplitCalculator.itemized(
        const [
          ReceiptLine(
            label: 'Paneer Tikka',
            priceMinor: 30000,
            sharedBy: ['me', 'rahul'],
          ),
          ReceiptLine(
            label: 'Butter Naan x4',
            priceMinor: 20000,
            sharedBy: ['me', 'rahul', 'priya', 'aman'],
          ),
          ReceiptLine(
            label: 'Mocktail',
            priceMinor: 15000,
            sharedBy: ['priya'],
          ),
          ReceiptLine(
            label: 'Chicken Biryani',
            priceMinor: 35000,
            sharedBy: ['aman'],
          ),
        ],
        extrasMinor: 10000, // 5% GST + ₹50 tip on a ₹1,000 subtotal
      );
      expect(split.subtotalsMinor, {
        'me': 20000,
        'rahul': 20000,
        'priya': 20000,
        'aman': 40000,
      });
      expect(split.extrasMinor, {
        'me': 2000,
        'rahul': 2000,
        'priya': 2000,
        'aman': 4000,
      });
      expect(split.billTotalMinor, 110000);
    });

    test('discounts reduce shares proportionally', () {
      final split = SplitCalculator.itemized(const [
        ReceiptLine(label: 'A', priceMinor: 30000, sharedBy: ['x']),
        ReceiptLine(label: 'B', priceMinor: 10000, sharedBy: ['y']),
      ], extrasMinor: -4000);
      expect(split.totalsMinor, {'x': 27000, 'y': 9000});
    });

    test('unclaimed items are an error', () {
      expect(
        () => SplitCalculator.itemized(const [
          ReceiptLine<String>(
            label: 'Mystery fries',
            priceMinor: 9000,
            sharedBy: [],
          ),
        ]),
        throwsA(isA<UnclaimedItemError>()),
      );
    });
  });

  group('allocate', () {
    test('largest remainder, ties broken by order, always exact', () {
      for (final total in [1, 7, 101, 99999, -101]) {
        final shares = SplitCalculator.allocate(total, {
          'a': 1,
          'b': 1,
          'c': 1,
        });
        expect(_sum(shares), total);
      }
      expect(SplitCalculator.allocate(-100, {'a': 1, 'b': 1, 'c': 1}), {
        'a': -34,
        'b': -33,
        'c': -33,
      });
    });
  });

  group('ExpenseDraft', () {
    const rahul = FriendRef(id: 'r', name: 'Rahul');
    const priya = FriendRef(id: 'p', name: 'Priya');

    test(
      'equalSplit when I paid: friends owe their share, I absorb rounding',
      () {
        final draft = ExpenseDraft.equalSplit(
          merchant: 'Cab',
          totalMinor: 10000,
          friends: const [rahul, priya],
          category: TxnCategory.transit,
        );
        expect(draft.myShareMinor, 3334);
        expect(draft.friendShares, {rahul: 3333, priya: 3333});
        expect(draft.frontedForOthersMinor, 6666);
      },
    );

    test('equalSplit when a friend paid: the payer absorbs rounding', () {
      final draft = ExpenseDraft.equalSplit(
        merchant: 'Cab',
        totalMinor: 10000,
        friends: const [rahul, priya],
        payer: const PaidByFriend(rahul),
        category: TxnCategory.transit,
      );
      expect(draft.friendShares[rahul], 3334);
      expect(draft.myShareMinor, 3333);
      expect(draft.frontedForOthersMinor, 0);
    });

    test('rejects shares that do not cover the bill', () {
      expect(
        () => ExpenseDraft(
          merchant: 'X',
          totalPaidMinor: 1000,
          myShareMinor: 300,
          payer: const PaidByMe(),
          category: TxnCategory.food,
          friendShares: {rahul: 300},
        ),
        throwsA(isA<SplitMismatchError>()),
      );
    });

    test('a paying friend must be on the bill', () {
      expect(
        () => ExpenseDraft(
          merchant: 'X',
          totalPaidMinor: 1000,
          myShareMinor: 1000,
          payer: const PaidByFriend(rahul),
          category: TxnCategory.food,
        ),
        throwsArgumentError,
      );
    });
  });
}
