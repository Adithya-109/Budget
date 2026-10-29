import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:splitburn/domain/budget_cycle.dart';
import 'package:splitburn/domain/burn_rate.dart';

DateTime _date(String iso) {
  final parts = iso.split('-').map(int.parse).toList();
  return DateTime(parts[0], parts[1], parts[2]);
}

String _iso(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

void main() {
  // Shared with ios/RunnerTests so the Dart engine and the widget agree.
  final cases = (jsonDecode(
    File('test/fixtures/burn_rate_cases.json').readAsStringSync(),
  ) as List).cast<Map<String, Object?>>();

  group('shared fixtures', () {
    for (final c in cases) {
      test(c['name']! as String, () {
        final today = _date(c['today']! as String);
        final metrics = BurnRateMetrics.fromSnapshot(
          LedgerSnapshot(
            monthlyAllowanceMinor: c['allowance']! as int,
            bankBalanceMinor: c['bank']! as int,
            owedToMeMinor: c['owed_to_me']! as int,
            iOweMinor: c['i_owe']! as int,
            spentBeforeTodayMinor: c['spent_before_today']! as int,
            spentTodayMinor: c['spent_today']! as int,
            last7DaysSpendMinor: c['last_7_days']! as int,
            currencySymbol: '₹',
            cycle: BudgetCycle.containing(
              today,
              resetDay: c['reset_day']! as int,
            ),
            today: today,
          ),
        );
        final e = c['expect']! as Map<String, Object?>;
        expect(metrics.daysRemaining, e['days_remaining']);
        expect(metrics.dailyLimitMinor, e['daily_limit']);
        expect(metrics.leftTodayMinor, e['left_today']);
        expect(metrics.tomorrowLimitMinor, e['tomorrow_limit']);
        expect(metrics.avgDailyBurnMinor, e['avg_daily_burn']);
        expect(metrics.trueSpendableMinor, e['true_spendable']);
        expect(metrics.daysUntilBroke, e['days_until_broke']);
        expect(
          metrics.brokeDate == null ? null : _iso(metrics.brokeDate!),
          e['broke_date'],
        );
        expect(metrics.isSurvivalMode, e['survival']);
      });
    }
  });

  test('recalibration delta: overspending lowers tomorrow, underspending raises it', () {
    LedgerSnapshot snapshot(int spentToday) => LedgerSnapshot(
      monthlyAllowanceMinor: 1500000,
      bankBalanceMinor: 1000000,
      owedToMeMinor: 0,
      iOweMinor: 0,
      spentBeforeTodayMinor: 1340000,
      spentTodayMinor: spentToday,
      last7DaysSpendMinor: 0,
      currencySymbol: '₹',
      cycle: BudgetCycle.containing(DateTime(2026, 10, 28), resetDay: 1),
      today: DateTime(2026, 10, 28),
    );
    final over = BurnRateMetrics.fromSnapshot(snapshot(65000));
    expect(over.dailyLimitMinor, 40000);
    expect(over.recalibrationDeltaMinor, 31666 - 40000);
    expect(over.isOverToday, isTrue);

    final under = BurnRateMetrics.fromSnapshot(snapshot(10000));
    expect(under.tomorrowLimitMinor, 50000);
    expect(under.recalibrationDeltaMinor, 10000);
    expect(under.budgetLeftMinor, 150000);
  });

  test('engine invariants hold for random snapshots and every reset day', () {
    final rng = Random(7);
    for (var i = 0; i < 5000; i++) {
      final resetDay = 1 + rng.nextInt(31);
      final today = DateTime(2026, 1 + rng.nextInt(24), 1 + rng.nextInt(31));
      final cycle = BudgetCycle.containing(today, resetDay: resetDay);
      LedgerSnapshot snap({int? spentToday, int? iOwe}) => LedgerSnapshot(
        monthlyAllowanceMinor: rng.nextInt(5000000),
        bankBalanceMinor: rng.nextInt(4000000) - 500000,
        owedToMeMinor: rng.nextInt(200000),
        iOweMinor: iOwe ?? rng.nextInt(300000),
        spentBeforeTodayMinor: rng.nextInt(4000000),
        spentTodayMinor: spentToday ?? rng.nextInt(300000),
        last7DaysSpendMinor: rng.nextInt(10) == 0 ? 0 : rng.nextInt(2000000),
        currencySymbol: '₹',
        cycle: cycle,
        today: DateTime(today.year, today.month, today.day),
      );
      final s = snap();
      final m = BurnRateMetrics.fromSnapshot(s);
      final reason = 'case $i: $cycle on $today';

      expect(m.daysRemaining, inInclusiveRange(1, cycle.lengthInDays));
      expect(m.dailyLimitMinor, greaterThanOrEqualTo(0), reason: reason);
      // The limit never promises more than is left of the allowance.
      expect(
        m.dailyLimitMinor * m.daysRemaining,
        lessThanOrEqualTo(
          max(0, s.monthlyAllowanceMinor - s.spentBeforeTodayMinor),
        ),
        reason: reason,
      );
      expect(m.leftTodayMinor + s.spentTodayMinor, m.dailyLimitMinor);
      expect(
        m.tomorrowLimitMinor == null,
        m.daysRemaining == 1,
        reason: reason,
      );
      expect(m.trueSpendableMinor, s.bankBalanceMinor - s.iOweMinor);
      if (m.daysUntilBroke == null) {
        expect(m.avgDailyBurnMinor, 0, reason: reason);
        expect(m.isSurvivalMode, isFalse, reason: reason);
      } else {
        expect(m.daysUntilBroke, greaterThanOrEqualTo(0));
        // Survival Mode exactly when the money runs out inside this cycle.
        expect(
          m.isSurvivalMode,
          m.brokeDate!.isBefore(cycle.end),
          reason: reason,
        );
      }

      // Recalibration: spending more today never raises tomorrow's limit,
      // and never changes today's.
      final more = BurnRateMetrics.fromSnapshot(
        LedgerSnapshot(
          monthlyAllowanceMinor: s.monthlyAllowanceMinor,
          bankBalanceMinor: s.bankBalanceMinor,
          owedToMeMinor: s.owedToMeMinor,
          iOweMinor: s.iOweMinor,
          spentBeforeTodayMinor: s.spentBeforeTodayMinor,
          spentTodayMinor: s.spentTodayMinor + 1 + rng.nextInt(100000),
          last7DaysSpendMinor: s.last7DaysSpendMinor,
          currencySymbol: '₹',
          cycle: s.cycle,
          today: s.today,
        ),
      );
      expect(more.dailyLimitMinor, m.dailyLimitMinor, reason: reason);
      if (m.tomorrowLimitMinor != null) {
        expect(
          more.tomorrowLimitMinor,
          lessThanOrEqualTo(m.tomorrowLimitMinor!),
          reason: reason,
        );
      }

      // Owing friends more never buys more days.
      final owingMore = BurnRateMetrics.fromSnapshot(
        LedgerSnapshot(
          monthlyAllowanceMinor: s.monthlyAllowanceMinor,
          bankBalanceMinor: s.bankBalanceMinor,
          owedToMeMinor: s.owedToMeMinor,
          iOweMinor: s.iOweMinor + rng.nextInt(100000),
          spentBeforeTodayMinor: s.spentBeforeTodayMinor,
          spentTodayMinor: s.spentTodayMinor,
          last7DaysSpendMinor: s.last7DaysSpendMinor,
          currencySymbol: '₹',
          cycle: s.cycle,
          today: s.today,
        ),
      );
      if (m.daysUntilBroke != null) {
        expect(owingMore.daysUntilBroke, lessThanOrEqualTo(m.daysUntilBroke!));
      }
    }
  });

  test(
    'spending exactly the daily limit every day uses the allowance exactly',
    () {
      // Never "over today", and the last day's limit picks up every paisa the
      // truncating division left behind.
      for (final resetDay in [1, 10, 29, 31]) {
        final cycle = BudgetCycle.containing(
          DateTime(2026, 1, 15),
          resetDay: resetDay,
        );
        const allowance = 1234567;
        var spent = 0;
        for (final day in cycle.days) {
          final m = BurnRateMetrics.fromSnapshot(
            LedgerSnapshot(
              monthlyAllowanceMinor: allowance,
              bankBalanceMinor: allowance - spent,
              owedToMeMinor: 0,
              iOweMinor: 0,
              spentBeforeTodayMinor: spent,
              spentTodayMinor: 0,
              last7DaysSpendMinor: 0,
              currencySymbol: '₹',
              cycle: cycle,
              today: day,
            ),
          );
          expect(m.isOverToday, isFalse);
          spent += m.dailyLimitMinor;
        }
        expect(spent, allowance, reason: 'reset day $resetDay');
      }
    },
  );

  test('true liquid balance', () {
    const balance = TrueLiquidBalance(
      bankBalanceMinor: 845000,
      iOweMinor: 12000,
      owedToMeMinor: 90000,
    );
    expect(balance.trueSpendableMinor, 833000);
    expect(balance.settledUpMinor, 923000);
  });
}
