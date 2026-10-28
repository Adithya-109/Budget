import SwiftUI
import WidgetKit

// Home Screen and Lock Screen widgets that read finance.sqlite from the App
// Group in SQLITE_OPEN_READONLY mode. All numbers come from BurnRateMetrics,
// the same formulas the Flutter dashboard uses.

// MARK: - Timeline

struct BalanceEntry: TimelineEntry {
    enum State {
        case ready(LedgerSnapshot, BurnRateMetrics)
        case notSetUp
        case failed(String)
    }

    let date: Date
    let state: State

    static var sample: BalanceEntry {
        let now = Date()
        let snapshot = LedgerSnapshot(
            monthlyAllowanceMinor: 15_000_00, bankBalanceMinor: 8_450_00, owedToMeMinor: 900_00,
            iOweMinor: 120_00, spentBeforeTodayMinor: 7_800_00, spentTodayMinor: 180_00,
            last7DaysSpendMinor: 2_940_00, currencySymbol: "₹",
            cycle: BudgetCycle(containing: now, resetDay: 1), now: now)
        return BalanceEntry(date: now, state: .ready(snapshot, BurnRateMetrics(snapshot: snapshot)))
    }
}

struct BalanceProvider: TimelineProvider {
    func placeholder(in context: Context) -> BalanceEntry { .sample }

    func getSnapshot(in context: Context, completion: @escaping (BalanceEntry) -> Void) {
        completion(context.isPreview ? .sample : load(at: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<BalanceEntry>) -> Void) {
        let now = Date()
        let calendar = Calendar.current
        let midnight = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: now))!
        var entries = [load(at: now)]
        // Pre-compute the post-midnight entry so the new day's limit shows up
        // on time even if WidgetKit delays the next reload.
        entries.append(load(at: midnight))
        let refresh = min(midnight, now.addingTimeInterval(30 * 60))
        completion(Timeline(entries: entries, policy: .after(refresh)))
    }

    private func load(at date: Date) -> BalanceEntry {
        do {
            let manager = try SharedSQLiteManager(mode: .readOnly)
            let snapshot = try manager.readSnapshot(now: date)
            return BalanceEntry(date: date, state: .ready(snapshot, BurnRateMetrics(snapshot: snapshot)))
        } catch SharedStorageError.databaseMissing {
            return BalanceEntry(date: date, state: .notSetUp)
        } catch {
            return BalanceEntry(date: date, state: .failed(error.localizedDescription))
        }
    }
}

// MARK: - Style

private enum Palette {
    static let ink = Color(red: 0.04, green: 0.04, blue: 0.06)
    static let paper = Color(red: 0.97, green: 0.96, blue: 0.92)
    static let lime = Color(red: 0.83, green: 1.0, blue: 0.23)
    static let magma = Color(red: 1.0, green: 0.35, blue: 0.12)
    static let survival = Color(red: 1.0, green: 0.18, blue: 0.33)
    static let owed = Color(red: 0.24, green: 0.86, blue: 0.52)
    static let muted = Color.white.opacity(0.6)
}

private extension View {
    /// iOS 17 requires widgets to declare their background as a container
    /// background; older systems just paint it.
    @ViewBuilder
    func widgetBackground(_ color: Color) -> some View {
        if #available(iOS 17.0, *) {
            containerBackground(for: .widget) { color }
        } else {
            background(color)
        }
    }

    func brutalBox(_ fill: Color) -> some View {
        padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(fill)
            .overlay(Rectangle().stroke(Palette.ink, lineWidth: 2))
    }
}

private let dashboardURL = URL(string: "splitburn://dashboard")!

// MARK: - Views

struct BalanceWidgetEntryView: View {
    @Environment(\.widgetFamily) private var family
    let entry: BalanceEntry

    var body: some View {
        switch entry.state {
        case let .ready(snapshot, metrics):
            content(snapshot, metrics).widgetURL(dashboardURL)
        case .notSetUp:
            message("Open SplitBurn to set up your budget.")
        case let .failed(reason):
            message(reason)
        }
    }

    @ViewBuilder
    private func content(_ s: LedgerSnapshot, _ m: BurnRateMetrics) -> some View {
        switch family {
        case .accessoryInline:
            AccessoryInlineView(snapshot: s, metrics: m).widgetBackground(.clear)
        case .accessoryCircular:
            AccessoryCircularView(snapshot: s, metrics: m).widgetBackground(.clear)
        case .accessoryRectangular:
            AccessoryRectangularView(snapshot: s, metrics: m).widgetBackground(.clear)
        case .systemMedium:
            MediumView(snapshot: s, metrics: m)
                .widgetBackground(m.isSurvivalMode ? Palette.survival : Palette.ink)
        default:
            SmallView(snapshot: s, metrics: m)
                .widgetBackground(m.isSurvivalMode ? Palette.survival : Palette.ink)
        }
    }

    @ViewBuilder
    private func message(_ text: String) -> some View {
        switch family {
        case .accessoryInline, .accessoryCircular, .accessoryRectangular:
            Text("SplitBurn").font(.headline).widgetBackground(.clear)
        default:
            VStack(alignment: .leading, spacing: 6) {
                Text("SPLITBURN").font(.system(size: 12, weight: .black, design: .monospaced))
                    .foregroundColor(Palette.lime)
                Text(text).font(.system(size: 13, weight: .semibold)).foregroundColor(.white)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .widgetBackground(Palette.ink)
        }
    }
}

/// Safe-to-spend hero with the True Liquid Balance pill.
private struct SmallView: View {
    let snapshot: LedgerSnapshot
    let metrics: BurnRateMetrics

    var body: some View {
        let symbol = snapshot.currencySymbol
        VStack(alignment: .leading, spacing: 4) {
            Text(metrics.isSurvivalMode ? "SURVIVAL MODE" : "SAFE TODAY")
                .font(.system(size: 11, weight: .black, design: .monospaced))
                .foregroundColor(metrics.isSurvivalMode ? Palette.ink : Palette.lime)
            Text(Money.compact(metrics.leftTodayMinor, symbol: symbol))
                .font(.system(size: 34, weight: .black, design: .rounded))
                .minimumScaleFactor(0.6)
                .lineLimit(1)
                .foregroundColor(metrics.isOverToday ? Palette.magma : .white)
            Text("of \(Money.compact(metrics.dailyLimitMinor, symbol: symbol)) limit")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(Palette.muted)
            Spacer(minLength: 0)
            Text("TRUE \(Money.compact(metrics.trueSpendableMinor, symbol: symbol))")
                .font(.system(size: 11, weight: .heavy, design: .monospaced))
                .foregroundColor(Palette.ink)
                .brutalBox(Palette.paper)
            if metrics.owedToMeMinor > 0 {
                Text("+\(Money.compact(metrics.owedToMeMinor, symbol: symbol)) owed")
                    .font(.system(size: 11, weight: .heavy, design: .monospaced))
                    .foregroundColor(Palette.ink)
                    .brutalBox(Palette.owed)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

private struct MediumView: View {
    let snapshot: LedgerSnapshot
    let metrics: BurnRateMetrics

    var body: some View {
        let symbol = snapshot.currencySymbol
        HStack(alignment: .top, spacing: 12) {
            SmallView(snapshot: snapshot, metrics: metrics)
            VStack(alignment: .leading, spacing: 6) {
                row("You owe", Money.format(snapshot.iOweMinor, symbol: symbol))
                row("Bank", Money.format(snapshot.bankBalanceMinor, symbol: symbol))
                if let tomorrow = metrics.tomorrowLimitMinor {
                    row("Tomorrow", Money.format(tomorrow, symbol: symbol))
                }
                Spacer(minLength: 0)
                Text(brokeLine)
                    .font(.system(size: 11, weight: .heavy, design: .monospaced))
                    .foregroundColor(Palette.ink)
                    .brutalBox(metrics.isSurvivalMode ? Palette.paper : Palette.lime)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var brokeLine: String {
        guard let days = metrics.daysUntilBroke, let date = metrics.brokeDate else {
            return "NO BURN THIS WEEK"
        }
        if metrics.isSurvivalMode {
            let day = date.formatted(.dateTime.day().month(.abbreviated)).uppercased()
            return "\(snapshot.currencySymbol)0 BY \(day)"
        }
        return "\(days) DAYS OF CASH"
    }

    private func row(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(label.uppercased())
                .font(.system(size: 9, weight: .black, design: .monospaced))
                .foregroundColor(Palette.muted)
            Text(value)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
    }
}

private struct AccessoryRectangularView: View {
    let snapshot: LedgerSnapshot
    let metrics: BurnRateMetrics

    var body: some View {
        let symbol = snapshot.currencySymbol
        VStack(alignment: .leading, spacing: 1) {
            Text(metrics.isSurvivalMode ? "Survival mode" : "Safe today")
                .font(.system(size: 12, weight: .semibold))
                .widgetAccentable()
            Text(Money.format(metrics.leftTodayMinor, symbol: symbol))
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text(
                "True \(Money.compact(metrics.trueSpendableMinor, symbol: symbol))"
                    + (metrics.owedToMeMinor > 0
                        ? " · +\(Money.compact(metrics.owedToMeMinor, symbol: symbol))" : "")
            )
            .font(.system(size: 12))
            .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct AccessoryCircularView: View {
    let snapshot: LedgerSnapshot
    let metrics: BurnRateMetrics

    var body: some View {
        let limit = max(metrics.dailyLimitMinor, 1)
        let fraction = min(max(Double(metrics.leftTodayMinor) / Double(limit), 0), 1)
        Gauge(value: fraction) {
            Text(snapshot.currencySymbol)
        } currentValueLabel: {
            Text(Money.compact(metrics.leftTodayMinor, symbol: ""))
                .minimumScaleFactor(0.5)
        }
        .gaugeStyle(.accessoryCircular)
    }
}

private struct AccessoryInlineView: View {
    let snapshot: LedgerSnapshot
    let metrics: BurnRateMetrics

    var body: some View {
        Text("\(Money.compact(metrics.leftTodayMinor, symbol: snapshot.currencySymbol)) safe today")
    }
}

// MARK: - Widget

struct BalanceWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: SharedStorageConstants.widgetKind, provider: BalanceProvider()) { entry in
            BalanceWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Safe to Spend")
        .description("Today's safe-to-spend, true liquid balance and what friends owe you.")
        .supportedFamilies([
            .systemSmall, .systemMedium,
            .accessoryRectangular, .accessoryCircular, .accessoryInline,
        ])
    }
}

@main
struct BalanceWidgetBundle: WidgetBundle {
    var body: some Widget {
        BalanceWidget()
    }
}
