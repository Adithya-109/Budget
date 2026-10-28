import AppIntents
import Foundation
import WidgetKit

/// Category picker for the structured Shortcuts parameter. Raw values are the
/// `transactions.category` codes.
@available(iOS 16.0, *)
enum ExpenseCategoryOption: String, AppEnum {
    case food = "Food"
    case groceries = "Groceries"
    case transit = "Transit"
    case utilities = "Utilities"
    case fun = "Fun"
    case other = "Other"

    static let typeDisplayRepresentation: TypeDisplayRepresentation = "Category"
    static let caseDisplayRepresentations: [ExpenseCategoryOption: DisplayRepresentation] = [
        .food: "Food",
        .groceries: "Groceries",
        .transit: "Transit",
        .utilities: "Utilities",
        .fun: "Fun",
        .other: "Other",
    ]
}

/// Logs an expense straight into the shared ledger without opening the app
/// (or booting Flutter). Bind it to the Apple Pay "Transaction" automation
/// with Amount + Merchant, or to the Action Button / Siri with a phrase like
/// "Spent 450 on Domino's with Rahul and Priya".
@available(iOS 16.0, *)
struct LogSplitExpenseIntent: AppIntent {
    static let title: LocalizedStringResource = "Log Split Expense"
    static let description = IntentDescription(
        "Log an expense in SplitBurn and split it with friends without opening the app.")
    static let openAppWhenRun = false

    @Parameter(
        title: "What did you spend?",
        description: "For example: Spent 450 on Domino's with Rahul and Priya",
        requestValueDialog: IntentDialog("What did you spend? Try “450 on Domino's with Rahul”."))
    var phrase: String?

    @Parameter(title: "Amount", description: "Total bill. Use the Apple Pay automation's Amount.")
    var amount: Double?

    @Parameter(title: "Merchant")
    var merchant: String?

    @Parameter(title: "Friends", description: "Comma-separated names to split equally with.")
    var friendsCsv: String?

    @Parameter(title: "Paid By", description: "Leave empty if you paid.")
    var paidBy: String?

    @Parameter(title: "Category")
    var category: ExpenseCategoryOption?

    static var parameterSummary: some ParameterSummary {
        Summary("Log \(\.$amount) at \(\.$merchant) split with \(\.$friendsCsv)") {
            \.$phrase
            \.$paidBy
            \.$category
        }
    }

    func perform() async throws -> some IntentResult & ReturnsValue<String> & ProvidesDialog {
        let spoken = phrase?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let parsed = spoken.isEmpty ? nil : ExpensePhraseParser.parse(spoken)

        let structuredAmount = amount.map(Money.toMinor)
        guard let totalMinor = structuredAmount ?? parsed?.amountMinor, totalMinor > 0 else {
            if spoken.isEmpty && amount == nil {
                throw $phrase.needsValueError()
            }
            throw $amount.needsValueError("I couldn't find an amount. How much was it?")
        }

        let merchantName = merchant.nonBlank
            ?? parsed?.merchant
            ?? ExpensePhraseParser.fallbackMerchant
        var friendNames = friendsCsv.nonBlank.map(ExpensePhraseParser.friendNames(fromCSV:))
            ?? parsed?.friends
            ?? []
        let payerName = paidBy.nonBlank.map(ExpensePhraseParser.normalizeName) ?? parsed?.payer
        if let payerName, !friendNames.contains(where: { $0.caseInsensitiveCompare(payerName) == .orderedSame }) {
            friendNames.insert(payerName, at: 0)
        }
        let categoryCode = category?.rawValue
            ?? parsed.map(\.category).flatMap { $0 == CategoryClassifier.other ? nil : $0 }
            ?? CategoryClassifier.classify(words: merchantName.split(separator: " ").map(String.init))

        let manager = try SharedSQLiteManager(mode: .readWrite)
        let friends = try friendNames.map { try manager.resolveFriend(named: $0) }
        let payer = payerName.flatMap { name in
            friends.first { $0.name.caseInsensitiveCompare(name) == .orderedSame }
        }
        let expense = SharedExpense.equalSplit(
            merchant: merchantName,
            totalMinor: totalMinor,
            friends: friends,
            payer: payer,
            category: categoryCode,
            source: spoken.isEmpty ? "APPLE_PAY_SHORTCUT" : "VOICE_INTENT")
        let transactionId = try manager.logExpense(expense)

        WidgetCenter.shared.reloadTimelines(ofKind: SharedStorageConstants.widgetKind)

        let snapshot = try manager.readSnapshot()
        let metrics = BurnRateMetrics(snapshot: snapshot)
        return .result(
            value: transactionId,
            dialog: IntentDialog(stringLiteral: Self.confirmation(
                for: expense, metrics: metrics, symbol: snapshot.currencySymbol)))
    }

    /// "Logged ₹450 at Domino's. Rahul and Priya owe you ₹150 each. ₹320 left today."
    static func confirmation(for expense: SharedExpense, metrics: BurnRateMetrics, symbol: String) -> String {
        func money(_ minor: Int64) -> String { Money.format(minor, symbol: symbol) }
        var parts = ["Logged \(money(expense.totalMinor)) at \(expense.merchant)."]
        if let payer = expense.payer {
            parts.append("You owe \(payer.name) \(money(expense.myShareMinor)).")
        } else if !expense.friendShares.isEmpty {
            let names = ListFormatter.localizedString(byJoining: expense.friendShares.map(\.friend.name))
            let amounts = Set(expense.friendShares.map(\.shareMinor))
            if expense.friendShares.count > 1, amounts.count == 1, let each = amounts.first {
                parts.append("\(names) owe you \(money(each)) each.")
            } else {
                let owed = expense.friendShares.reduce(0) { $0 + $1.shareMinor }
                parts.append("\(names) \(expense.friendShares.count == 1 ? "owes" : "owe") you \(money(owed)).")
            }
        }
        if metrics.isOverToday {
            parts.append("You're \(money(-metrics.leftTodayMinor)) over today's limit.")
        } else {
            parts.append("\(money(metrics.leftTodayMinor)) left to spend today.")
        }
        return parts.joined(separator: " ")
    }
}

@available(iOS 16.0, *)
struct SplitBurnShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: LogSplitExpenseIntent(),
            phrases: [
                "Log a split in \(.applicationName)",
                "Log an expense in \(.applicationName)",
                "Split a bill with \(.applicationName)",
            ],
            shortTitle: "Log Split",
            systemImageName: "indianrupeesign.circle")
    }
}

private extension Optional where Wrapped == String {
    /// The trimmed string, or nil if missing or blank.
    var nonBlank: String? {
        guard let trimmed = self?.trimmingCharacters(in: .whitespacesAndNewlines), !trimmed.isEmpty else {
            return nil
        }
        return trimmed
    }
}
