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

    test(
      'every day of two years, every reset day: cycles tile the calendar',
      () {
        // Run under several TZs by tool/test_all.sh so DST transitions (23 h /
        // 25 h days) are covered: all counts must be calendar days.
        for (var resetDay = 1; resetDay <= 31; resetDay++) {
          var cycle = BudgetCycle.containing(
            DateTime(2026),
            resetDay: resetDay,
          );
          while (cycle.start.isBefore(DateTime(2028))) {
            final days = cycle.days.toList();
            expect(days.length, cycle.lengthInDays);
            expect(cycle.lengthInDays, inInclusiveRange(28, 31));
            expect(days.first, cycle.start);
            for (var i = 0; i < days.length; i++) {
              final d = days[i];
              // The day's first instant (01:00 where DST starts at midnight,
              // e.g. America/Santiago).
              expect(
                d.subtract(const Duration(minutes: 1)).day,
                isNot(d.day),
                reason: '$d starts its day',
              );
              expect(cycle.daysRemaining(d), days.length - i);
              expect(
                cycle.daysRemaining(d.add(const Duration(hours: 23))),
                inInclusiveRange(days.length - i - 1, days.length - i),
              );
              expect(cycle.daysElapsed(d), i);
              expect(BudgetCycle.containing(d, resetDay: resetDay), cycle);
              expect(
                BudgetCycle.containing(
                  DateTime(d.year, d.month, d.day, 23, 59, 59),
                  resetDay: resetDay,
                ),
                cycle,
              );
            }
            expect(cycle.next.start, cycle.end);
            expect(cycle.next.previous, cycle);
            cycle = cycle.next;
          }
        }
      },
    );

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
