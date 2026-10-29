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

/// DESIGN_SYSTEM.md tokens: Obsidian Matte (dark) / Warm Alabaster (light).
/// Mirrors `SplitBurnTokens` in lib/ui/theme.dart.
private struct Palette {
    let dark: Bool

    init(_ scheme: ColorScheme) { dark = scheme == .dark }

    private static func hex(_ value: UInt32) -> Color {
        Color(
            red: Double((value >> 16) & 0xFF) / 255,
            green: Double((value >> 8) & 0xFF) / 255,
            blue: Double(value & 0xFF) / 255)
    }

    var canvas: Color { Self.hex(dark ? 0x0E1014 : 0xF7F5F0) }
    var surface: Color { Self.hex(dark ? 0x1E222B : 0xF0EDE6) }
    var textPrimary: Color { Self.hex(dark ? 0xF3F4F6 : 0x111317) }
    var textSecondary: Color { Self.hex(dark ? 0x9CA3AF : 0x525866) }
    var safeMint: Color { Self.hex(dark ? 0x34D399 : 0x059669) }
    var survival: Color { Self.hex(dark ? 0xFB7185 : 0xE11D48) }
    var survivalEnd: Color { Self.hex(dark ? 0xF97316 : 0xEA580C) }
    var owed: Color { Self.hex(dark ? 0x4ADE80 : 0x16A34A) }
    var iOwe: Color { Self.hex(dark ? 0xF87171 : 0xDC2626) }

    /// Survival Mode paints the whole widget in the magma gradient.
    func background(survival isSurvival: Bool) -> LinearGradient {
        LinearGradient(
            colors: isSurvival ? [survival, survivalEnd] : [canvas, canvas],
            startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}

private extension View {
    /// iOS 17 requires widgets to declare their background as a container
    /// background; older systems just paint it.
    @ViewBuilder
    func widgetBackground<Background: View>(_ background: Background) -> some View {
        if #available(iOS 17.0, *) {
            containerBackground(for: .widget) { background }
        } else {
            self.background(background)
        }
    }

    /// Tinted capsule badge ("+₹900 owed").
    func pill(_ color: Color, onMagma: Bool) -> some View {
        padding(.horizontal, 8)
            .padding(.vertical, 3)
            .foregroundColor(onMagma ? .white : color)
            .background(Capsule().fill(onMagma ? Color.white.opacity(0.22) : color.opacity(0.16)))
    }
}

private let dashboardURL = URL(string: "splitburn://dashboard")!

// MARK: - Views

struct BalanceWidgetEntryView: View {
    @Environment(\.widgetFamily) private var family
    @Environment(\.colorScheme) private var scheme
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
        let palette = Palette(scheme)
        switch family {
        case .accessoryInline:
            AccessoryInlineView(snapshot: s, metrics: m).widgetBackground(Color.clear)
        case .accessoryCircular:
            AccessoryCircularView(snapshot: s, metrics: m).widgetBackground(Color.clear)
        case .accessoryRectangular:
            AccessoryRectangularView(snapshot: s, metrics: m).widgetBackground(Color.clear)
        case .systemMedium:
            MediumView(snapshot: s, metrics: m, palette: palette)
                .widgetBackground(palette.background(survival: m.isSurvivalMode))
        default:
            SmallView(snapshot: s, metrics: m, palette: palette)
                .widgetBackground(palette.background(survival: m.isSurvivalMode))
        }
    }

    @ViewBuilder
    private func message(_ text: String) -> some View {
        let palette = Palette(scheme)
        switch family {
        case .accessoryInline, .accessoryCircular, .accessoryRectangular:
            Text("SplitBurn").font(.headline).widgetBackground(Color.clear)
        default:
            VStack(alignment: .leading, spacing: 6) {
                Text("SplitBurn").font(.system(size: 13, weight: .heavy, design: .rounded))
                    .foregroundColor(palette.safeMint)
                Text(text).font(.system(size: 13, weight: .semibold))
                    .foregroundColor(palette.textPrimary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .widgetBackground(palette.canvas)
        }
    }
}

/// Safe-to-spend hero with the True Liquid Balance line.
private struct SmallView: View {
    let snapshot: LedgerSnapshot
    let metrics: BurnRateMetrics
    let palette: Palette

    var body: some View {
        let symbol = snapshot.currencySymbol
        let magma = metrics.isSurvivalMode
        VStack(alignment: .leading, spacing: 4) {
            Text(magma ? "SURVIVAL MODE" : "SAFE TODAY")
                .font(.system(size: 11, weight: .bold))
                .tracking(0.8)
                .foregroundColor(magma ? .white : palette.safeMint)
            Text(Money.compact(metrics.leftTodayMinor, symbol: symbol))
                .font(.system(size: 32, weight: .heavy, design: .rounded))
                .minimumScaleFactor(0.6)
                .lineLimit(1)
                .foregroundColor(
                    magma ? .white : metrics.isOverToday ? palette.iOwe : palette.textPrimary)
            Text("of \(Money.compact(metrics.dailyLimitMinor, symbol: symbol)) limit")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(magma ? .white.opacity(0.85) : palette.textSecondary)
            Spacer(minLength: 0)
            Text("True \(Money.compact(metrics.trueSpendableMinor, symbol: symbol))")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundColor(magma ? .white : palette.textPrimary)
            if metrics.owedToMeMinor > 0 {
                Text("+\(Money.compact(metrics.owedToMeMinor, symbol: symbol)) owed")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .pill(palette.owed, onMagma: magma)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

private struct MediumView: View {
    let snapshot: LedgerSnapshot
    let metrics: BurnRateMetrics
    let palette: Palette

    var body: some View {
        let symbol = snapshot.currencySymbol
        let magma = metrics.isSurvivalMode
        HStack(alignment: .top, spacing: 12) {
            SmallView(snapshot: snapshot, metrics: metrics, palette: palette)
            VStack(alignment: .leading, spacing: 6) {
                row("You owe", Money.format(snapshot.iOweMinor, symbol: symbol))
                row("Bank", Money.format(snapshot.bankBalanceMinor, symbol: symbol))
                if let tomorrow = metrics.tomorrowLimitMinor {
                    row("Tomorrow", Money.format(tomorrow, symbol: symbol))
                }
                Spacer(minLength: 0)
                Text(brokeLine)
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .pill(palette.safeMint, onMagma: magma)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var brokeLine: String {
        guard let days = metrics.daysUntilBroke, let date = metrics.brokeDate else {
            return "No burn this week"
        }
        if metrics.isSurvivalMode {
            let day = date.formatted(.dateTime.day().month(.abbreviated))
            return "\(snapshot.currencySymbol)0 by \(day)"
        }
        return "\(days) days of cash"
    }

    private func row(_ label: String, _ value: String) -> some View {
        let magma = metrics.isSurvivalMode
        return VStack(alignment: .leading, spacing: 0) {
            Text(label.uppercased())
                .font(.system(size: 9, weight: .bold))
                .tracking(0.6)
                .foregroundColor(magma ? .white.opacity(0.8) : palette.textSecondary)
            Text(value)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(magma ? .white : palette.textPrimary)
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
