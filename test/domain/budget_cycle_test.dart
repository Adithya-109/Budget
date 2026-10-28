import 'package:flutter_test/flutter_test.dart';
import 'package:splitburn/core/money.dart';
import 'package:splitburn/domain/budget_cycle.dart';

void main() {
  group('BudgetCycle', () {
    test('reset on the 1st: October cycle', () {
      final cycle = BudgetCycle.containing(
        DateTime(2026, 10, 28, 15),
        resetDay: 1,
      );
      expect(cycle.start, DateTime(2026, 10, 1));
      expect(cycle.end, DateTime(2026, 11, 1));
      expect(cycle.lengthInDays, 31);
      expect(
        cycle.daysRemaining(DateTime(2026, 10, 28, 15)),
        4,
        reason: '28–31 inclusive',
      );
      expect(cycle.daysElapsed(DateTime(2026, 10, 28)), 27);
    });

    test(
      'mid-month stipend: before the reset day belongs to the previous cycle',
      () {
        final cycle = BudgetCycle.containing(
          DateTime(2026, 10, 9),
          resetDay: 10,
        );
        expect(cycle.start, DateTime(2026, 9, 10));
        expect(cycle.end, DateTime(2026, 10, 10));
        expect(cycle.contains(DateTime(2026, 10, 9, 23, 59)), isTrue);
        expect(cycle.contains(DateTime(2026, 10, 10)), isFalse);
      },
    );

    test('reset day 31 clamps in short months and across the year end', () {
      final feb = BudgetCycle.containing(DateTime(2026, 3, 1), resetDay: 31);
      expect(feb.start, DateTime(2026, 2, 28));
      expect(feb.end, DateTime(2026, 3, 31));

      final dec = BudgetCycle.containing(DateTime(2027, 1, 5), resetDay: 31);
      expect(dec.start, DateTime(2026, 12, 31));
      expect(dec.end, DateTime(2027, 1, 31));
      expect(dec.next.start, DateTime(2027, 1, 31));
      expect(dec.previous.end, DateTime(2026, 12, 31));
    });

    test('days lists every local day once', () {
      final cycle = BudgetCycle.containing(DateTime(2026, 2, 14), resetDay: 1);
      expect(cycle.days.length, 28);
      expect(cycle.days.last, DateTime(2026, 2, 28));
    });

    test('rejects invalid reset days', () {
      expect(
        () => BudgetCycle.containing(DateTime(2026), resetDay: 0),
        throwsRangeError,
      );
      expect(
        () => BudgetCycle.containing(DateTime(2026), resetDay: 32),
        throwsRangeError,
      );
    });
  });

  group('Money', () {
    test('round-trips minor units', () {
      expect(Money.toMinor(1200.0), 120000);
      expect(Money.toMinor(0.1 + 0.2), 30);
      expect(Money.toMajor(33334), 333.34);
      expect(Money.round2(10 / 3), 3.33);
    });

    test('formats for display and deep links', () {
      expect(Money.format(12000000), '₹1,20,000');
      expect(Money.format(45050, symbol: r'$'), r'$450.50');
      expect(Money.toPlainDecimal(15000), '150.00');
      expect(Money.toPlainDecimal(5), '0.05');
    });
  });
}
