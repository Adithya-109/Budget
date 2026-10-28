/// The allowance cycle a moment falls in: from one reset day (inclusive, local
/// midnight) to the next (exclusive).
///
/// Students get money on a fixed day of month, not on the 1st, so every
/// "this month" query is really "this cycle". Reset days past the end of a
/// short month clamp to its last day (a 31st reset lands on 28/29 Feb).
class BudgetCycle {
  BudgetCycle._(this.start, this.end, this.resetDay);

  factory BudgetCycle.containing(DateTime moment, {required int resetDay}) {
    if (resetDay < 1 || resetDay > 31) {
      throw RangeError.range(resetDay, 1, 31, 'resetDay');
    }
    final local = moment.toLocal();
    final thisMonthsReset = _resetDate(local.year, local.month, resetDay);
    if (!local.isBefore(thisMonthsReset)) {
      return BudgetCycle._(
        thisMonthsReset,
        _resetDate(local.year, local.month + 1, resetDay),
        resetDay,
      );
    }
    return BudgetCycle._(
      _resetDate(local.year, local.month - 1, resetDay),
      thisMonthsReset,
      resetDay,
    );
  }

  /// Local midnight on the reset day that opened this cycle.
  final DateTime start;

  /// Local midnight on the next reset day (exclusive).
  final DateTime end;

  final int resetDay;

  /// Calendar days in the cycle (DST-safe).
  int get lengthInDays => _calendarDaysBetween(start, end);

  /// Days left including [today]; 0 once the cycle is over.
  int daysRemaining(DateTime today) {
    final days = _calendarDaysBetween(_dateOnly(today.toLocal()), end);
    return days.clamp(0, lengthInDays);
  }

  /// Days already elapsed before [today] (today itself not counted).
  int daysElapsed(DateTime today) => lengthInDays - daysRemaining(today);

  bool contains(DateTime moment) =>
      !moment.isBefore(start) && moment.isBefore(end);

  BudgetCycle get next => BudgetCycle.containing(end, resetDay: resetDay);

  BudgetCycle get previous => BudgetCycle.containing(
    start.subtract(const Duration(days: 1)),
    resetDay: resetDay,
  );

  /// Local midnight for each day in the cycle, in order.
  Iterable<DateTime> get days sync* {
    for (var i = 0; i < lengthInDays; i++) {
      yield DateTime(start.year, start.month, start.day + i);
    }
  }

  static DateTime _resetDate(int year, int month, int resetDay) {
    // DateTime normalizes month overflow (month 13 → January next year).
    final firstOfMonth = DateTime(year, month);
    final lastDay = DateTime(firstOfMonth.year, firstOfMonth.month + 1, 0).day;
    return DateTime(
      firstOfMonth.year,
      firstOfMonth.month,
      resetDay > lastDay ? lastDay : resetDay,
    );
  }

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  static int _calendarDaysBetween(DateTime from, DateTime to) {
    final a = DateTime.utc(from.year, from.month, from.day);
    final b = DateTime.utc(to.year, to.month, to.day);
    return b.difference(a).inDays;
  }

  @override
  bool operator ==(Object other) =>
      other is BudgetCycle &&
      other.start == start &&
      other.end == end &&
      other.resetDay == resetDay;

  @override
  int get hashCode => Object.hash(start, end, resetDay);

  @override
  String toString() => 'BudgetCycle($start → $end, resetDay: $resetDay)';
}
