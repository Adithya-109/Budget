import 'budget_cycle.dart';

/// Everything the burn-rate engine needs, read in one consistent query
/// (`LedgerDao.watchLedgerSnapshot`). Twin of Swift's `LedgerSnapshot`.
class LedgerSnapshot {
  const LedgerSnapshot({
    required this.monthlyAllowanceMinor,
    required this.bankBalanceMinor,
    required this.owedToMeMinor,
    required this.iOweMinor,
    required this.spentBeforeTodayMinor,
    required this.spentTodayMinor,
    required this.last7DaysSpendMinor,
    required this.currencySymbol,
    required this.cycle,
    required this.today,
  });

  final int monthlyAllowanceMinor;
  final int bankBalanceMinor;
  final int owedToMeMinor;
  final int iOweMinor;

  /// Personal (`my_share`) spend this cycle before today.
  final int spentBeforeTodayMinor;

  /// Personal spend on the local calendar day [today].
  final int spentTodayMinor;

  /// Personal spend over the 7 days ending today, today included.
  final int last7DaysSpendMinor;
  final String currencySymbol;
  final BudgetCycle cycle;

  /// Local midnight of the day being evaluated.
  final DateTime today;

  int get spentThisCycleMinor => spentBeforeTodayMinor + spentTodayMinor;

  @override
  bool operator ==(Object other) =>
      other is LedgerSnapshot &&
      other.monthlyAllowanceMinor == monthlyAllowanceMinor &&
      other.bankBalanceMinor == bankBalanceMinor &&
      other.owedToMeMinor == owedToMeMinor &&
      other.iOweMinor == iOweMinor &&
      other.spentBeforeTodayMinor == spentBeforeTodayMinor &&
      other.spentTodayMinor == spentTodayMinor &&
      other.last7DaysSpendMinor == last7DaysSpendMinor &&
      other.currencySymbol == currencySymbol &&
      other.cycle == cycle &&
      other.today == today;

  @override
  int get hashCode => Object.hash(
    monthlyAllowanceMinor,
    bankBalanceMinor,
    owedToMeMinor,
    iOweMinor,
    spentBeforeTodayMinor,
    spentTodayMinor,
    last7DaysSpendMinor,
    currencySymbol,
    cycle,
    today,
  );
}

/// Safe-to-spend, recalibration and Days-Until-Broke for one snapshot.
///
/// The formulas are the contract in CLAUDE.md §6 "Engine formulas" and must
/// match Swift's `BurnRateMetrics` (which feeds the widget) exactly;
/// `test/fixtures/burn_rate_cases.json` checks both. All money is minor
/// units with truncating integer division.
class BurnRateMetrics {
  const BurnRateMetrics._({
    required this.trueSpendableMinor,
    required this.owedToMeMinor,
    required this.daysRemaining,
    required this.dailyLimitMinor,
    required this.leftTodayMinor,
    required this.tomorrowLimitMinor,
    required this.avgDailyBurnMinor,
    required this.daysUntilBroke,
    required this.brokeDate,
    required this.budgetLeftMinor,
  });

  factory BurnRateMetrics.fromSnapshot(LedgerSnapshot s) {
    final trueSpendable = s.bankBalanceMinor - s.iOweMinor;
    final remaining = s.cycle.daysRemaining(s.today);

    final budgetLeftBeforeToday = _atLeastZero(
      s.monthlyAllowanceMinor - s.spentBeforeTodayMinor,
    );
    final dailyLimit = remaining > 0 ? budgetLeftBeforeToday ~/ remaining : 0;

    final budgetLeftAfterToday =
        s.monthlyAllowanceMinor - s.spentThisCycleMinor;
    final tomorrowLimit = remaining > 1
        ? _atLeastZero(budgetLeftAfterToday) ~/ (remaining - 1)
        : null;

    final avgBurn = s.last7DaysSpendMinor ~/ 7;
    int? daysUntilBroke;
    DateTime? brokeDate;
    if (avgBurn > 0) {
      daysUntilBroke = _atLeastZero(trueSpendable) ~/ avgBurn;
      brokeDate = DateTime(
        s.today.year,
        s.today.month,
        s.today.day + daysUntilBroke,
      );
    }

    return BurnRateMetrics._(
      trueSpendableMinor: trueSpendable,
      owedToMeMinor: s.owedToMeMinor,
      daysRemaining: remaining,
      dailyLimitMinor: dailyLimit,
      leftTodayMinor: dailyLimit - s.spentTodayMinor,
      tomorrowLimitMinor: tomorrowLimit,
      avgDailyBurnMinor: avgBurn,
      daysUntilBroke: daysUntilBroke,
      brokeDate: brokeDate,
      budgetLeftMinor: budgetLeftAfterToday,
    );
  }

  /// `Bank balance − money I owe friends`.
  final int trueSpendableMinor;

  /// Floating receivables (the green "+ owed" badge).
  final int owedToMeMinor;

  /// Days left in the cycle, today included.
  final int daysRemaining;

  /// Safe-to-spend today: what's left of the allowance before today, spread
  /// over the remaining days.
  final int dailyLimitMinor;

  /// `dailyLimit − spent today`; negative when over.
  final int leftTodayMinor;

  /// Tomorrow's limit after today's spending (null on the cycle's last day).
  final int? tomorrowLimitMinor;

  /// Rolling 7-day average personal spend per day.
  final int avgDailyBurnMinor;

  /// Whole days of true spendable cash at the current pace (null if nothing
  /// was spent this week).
  final int? daysUntilBroke;

  /// The local date cash hits zero at the current pace.
  final DateTime? brokeDate;

  /// Allowance minus this cycle's personal spend, today included (may be
  /// negative).
  final int budgetLeftMinor;

  bool get isSurvivalMode =>
      daysUntilBroke != null && daysUntilBroke! < daysRemaining;

  bool get isOverToday => leftTodayMinor < 0;

  /// How tomorrow's limit moved versus today's because of today's spending
  /// (drives the recalibration animation). Negative = it dropped.
  int? get recalibrationDeltaMinor =>
      tomorrowLimitMinor == null ? null : tomorrowLimitMinor! - dailyLimitMinor;

  static int _atLeastZero(int value) => value < 0 ? 0 : value;

  @override
  bool operator ==(Object other) =>
      other is BurnRateMetrics &&
      other.trueSpendableMinor == trueSpendableMinor &&
      other.owedToMeMinor == owedToMeMinor &&
      other.daysRemaining == daysRemaining &&
      other.dailyLimitMinor == dailyLimitMinor &&
      other.leftTodayMinor == leftTodayMinor &&
      other.tomorrowLimitMinor == tomorrowLimitMinor &&
      other.avgDailyBurnMinor == avgDailyBurnMinor &&
      other.daysUntilBroke == daysUntilBroke &&
      other.brokeDate == brokeDate &&
      other.budgetLeftMinor == budgetLeftMinor;

  @override
  int get hashCode => Object.hash(
    trueSpendableMinor,
    owedToMeMinor,
    daysRemaining,
    dailyLimitMinor,
    leftTodayMinor,
    tomorrowLimitMinor,
    avgDailyBurnMinor,
    daysUntilBroke,
    brokeDate,
    budgetLeftMinor,
  );
}

/// The True Liquid Balance pill: what's really yours, plus what's floating.
class TrueLiquidBalance {
  const TrueLiquidBalance({
    required this.bankBalanceMinor,
    required this.iOweMinor,
    required this.owedToMeMinor,
  });

  final int bankBalanceMinor;
  final int iOweMinor;
  final int owedToMeMinor;

  /// `Actual Bank Balance − Money I Owe Friends`.
  int get trueSpendableMinor => bankBalanceMinor - iOweMinor;

  /// Where the user lands once every IOU in both directions is settled.
  int get settledUpMinor => trueSpendableMinor + owedToMeMinor;

  @override
  bool operator ==(Object other) =>
      other is TrueLiquidBalance &&
      other.bankBalanceMinor == bankBalanceMinor &&
      other.iOweMinor == iOweMinor &&
      other.owedToMeMinor == owedToMeMinor;

  @override
  int get hashCode => Object.hash(bankBalanceMinor, iOweMinor, owedToMeMinor);
}
