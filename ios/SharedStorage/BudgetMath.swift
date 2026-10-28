import Foundation

// Burn-rate math shared by the WidgetKit extension and the App Intent. The
// Dart engine (Phase 3) implements the same formulas; see CLAUDE.md §6
// "Engine formulas". All money is Int64 minor units (paise / cents).

/// The allowance cycle containing a moment: from one reset day (inclusive,
/// local midnight) to the next (exclusive). Reset days past the end of a
/// short month clamp to its last day. Mirrors `lib/domain/budget_cycle.dart`.
public struct BudgetCycle: Equatable {
    public let start: Date
    public let end: Date
    public let resetDay: Int
    private let calendar: Calendar

    public init(containing moment: Date, resetDay: Int, calendar: Calendar = .current) {
        let day = min(max(resetDay, 1), 31)
        let thisMonth = Self.firstOfMonth(moment, calendar)
        let thisReset = Self.resetDate(monthStart: thisMonth, resetDay: day, calendar)
        if moment >= thisReset {
            start = thisReset
            end = Self.resetDate(
                monthStart: calendar.date(byAdding: .month, value: 1, to: thisMonth)!,
                resetDay: day, calendar)
        } else {
            start = Self.resetDate(
                monthStart: calendar.date(byAdding: .month, value: -1, to: thisMonth)!,
                resetDay: day, calendar)
            end = thisReset
        }
        self.resetDay = day
        self.calendar = calendar
    }

    public var lengthInDays: Int {
        calendar.dateComponents([.day], from: start, to: end).day ?? 0
    }

    /// Days left including the day of `today`; 0 once the cycle is over.
    public func daysRemaining(from today: Date) -> Int {
        let days = calendar.dateComponents(
            [.day], from: calendar.startOfDay(for: today), to: end
        ).day ?? 0
        return min(max(days, 0), lengthInDays)
    }

    public static func == (lhs: BudgetCycle, rhs: BudgetCycle) -> Bool {
        lhs.start == rhs.start && lhs.end == rhs.end && lhs.resetDay == rhs.resetDay
    }

    private static func firstOfMonth(_ date: Date, _ calendar: Calendar) -> Date {
        calendar.date(from: calendar.dateComponents([.year, .month], from: date))!
    }

    private static func resetDate(monthStart: Date, resetDay: Int, _ calendar: Calendar) -> Date {
        let daysInMonth = calendar.range(of: .day, in: .month, for: monthStart)?.count ?? 28
        return calendar.date(byAdding: .day, value: min(resetDay, daysInMonth) - 1, to: monthStart)!
    }
}

/// Everything the widget and intent dialog show, read in one pass.
public struct LedgerSnapshot {
    public var monthlyAllowanceMinor: Int64
    public var bankBalanceMinor: Int64
    public var owedToMeMinor: Int64
    public var iOweMinor: Int64
    /// Personal (my_share) spend this cycle before today.
    public var spentBeforeTodayMinor: Int64
    /// Personal spend today (local calendar day).
    public var spentTodayMinor: Int64
    /// Personal spend over the 7 days ending today, today included.
    public var last7DaysSpendMinor: Int64
    public var currencySymbol: String
    public var cycle: BudgetCycle
    public var now: Date

    public init(
        monthlyAllowanceMinor: Int64, bankBalanceMinor: Int64, owedToMeMinor: Int64,
        iOweMinor: Int64, spentBeforeTodayMinor: Int64, spentTodayMinor: Int64,
        last7DaysSpendMinor: Int64, currencySymbol: String, cycle: BudgetCycle, now: Date
    ) {
        self.monthlyAllowanceMinor = monthlyAllowanceMinor
        self.bankBalanceMinor = bankBalanceMinor
        self.owedToMeMinor = owedToMeMinor
        self.iOweMinor = iOweMinor
        self.spentBeforeTodayMinor = spentBeforeTodayMinor
        self.spentTodayMinor = spentTodayMinor
        self.last7DaysSpendMinor = last7DaysSpendMinor
        self.currencySymbol = currencySymbol
        self.cycle = cycle
        self.now = now
    }
}

/// Safe-to-spend, recalibration and Days-Until-Broke for one snapshot.
public struct BurnRateMetrics: Equatable {
    /// `Bank balance − money I owe friends`.
    public let trueSpendableMinor: Int64
    public let owedToMeMinor: Int64
    public let daysRemaining: Int
    /// `max(0, allowance − spend before today) / days remaining`.
    public let dailyLimitMinor: Int64
    /// `dailyLimit − spent today`; negative when over budget.
    public let leftTodayMinor: Int64
    /// Tomorrow's recalibrated limit given today's spending (nil on the last day).
    public let tomorrowLimitMinor: Int64?
    /// Rolling 7-day average personal spend per day.
    public let avgDailyBurnMinor: Int64
    /// `max(0, true spendable) / avg daily burn`; nil when nothing was spent.
    public let daysUntilBroke: Int?
    /// The day cash hits zero at the current pace.
    public let brokeDate: Date?

    public var isSurvivalMode: Bool {
        guard let daysUntilBroke else { return false }
        return daysUntilBroke < daysRemaining
    }

    public var isOverToday: Bool { leftTodayMinor < 0 }

    public init(snapshot s: LedgerSnapshot, calendar: Calendar = .current) {
        trueSpendableMinor = s.bankBalanceMinor - s.iOweMinor
        owedToMeMinor = s.owedToMeMinor
        let remaining = s.cycle.daysRemaining(from: s.now)
        daysRemaining = remaining

        let budgetLeftBeforeToday = max(0, s.monthlyAllowanceMinor - s.spentBeforeTodayMinor)
        dailyLimitMinor = remaining > 0 ? budgetLeftBeforeToday / Int64(remaining) : 0
        leftTodayMinor = dailyLimitMinor - s.spentTodayMinor

        let budgetLeftAfterToday = max(
            0, s.monthlyAllowanceMinor - s.spentBeforeTodayMinor - s.spentTodayMinor)
        tomorrowLimitMinor = remaining > 1 ? budgetLeftAfterToday / Int64(remaining - 1) : nil

        avgDailyBurnMinor = s.last7DaysSpendMinor / 7
        if avgDailyBurnMinor > 0 {
            let days = Int(max(0, trueSpendableMinor) / avgDailyBurnMinor)
            daysUntilBroke = days
            brokeDate = calendar.date(byAdding: .day, value: days, to: calendar.startOfDay(for: s.now))
        } else {
            daysUntilBroke = nil
            brokeDate = nil
        }
    }
}

public enum Money {
    public static func toMinor(_ major: Double) -> Int64 { Int64((major * 100).rounded()) }

    public static func toMajor(_ minor: Int64) -> Double { Double(minor) / 100 }

    /// `₹1,20,000` / `$450.50`; whole amounts drop decimals.
    public static func format(_ minor: Int64, symbol: String) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: symbol == "₹" ? "en_IN" : "en_US")
        formatter.currencySymbol = symbol
        let digits = minor % 100 == 0 ? 0 : 2
        formatter.minimumFractionDigits = digits
        formatter.maximumFractionDigits = digits
        return formatter.string(from: NSNumber(value: toMajor(minor))) ?? "\(symbol)\(toMajor(minor))"
    }

    /// Lock Screen sized: `₹320`, `₹8.4k`, `₹1.2L` (rupees) / `$1.2M`.
    public static func compact(_ minor: Int64, symbol: String) -> String {
        let major = toMajor(minor)
        let sign = major < 0 ? "-" : ""
        let value = abs(major)
        func trim(_ v: Double) -> String {
            let text = String(format: "%.1f", v)
            return text.hasSuffix(".0") ? String(text.dropLast(2)) : text
        }
        if symbol == "₹" {
            if value >= 10_000_000 { return "\(sign)\(symbol)\(trim(value / 10_000_000))Cr" }
            if value >= 100_000 { return "\(sign)\(symbol)\(trim(value / 100_000))L" }
        } else if value >= 1_000_000 {
            return "\(sign)\(symbol)\(trim(value / 1_000_000))M"
        }
        if value >= 1_000 { return "\(sign)\(symbol)\(trim(value / 1_000))k" }
        return "\(sign)\(symbol)\(Int(value.rounded()))"
    }
}
