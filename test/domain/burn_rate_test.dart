import 'dart:convert';
import 'dart:io';

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
