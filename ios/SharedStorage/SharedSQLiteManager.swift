import Foundation
import SQLite3

// Zero-dependency access to the shared `finance.sqlite` for the Runner app
// (App Intents) and the BalanceWidgetExtension (read-only). Follows the write
// contract in CLAUDE.md §6 exactly as the Dart LedgerDao does.

public enum SharedStorageConstants {
    public static let appGroupIdentifier = "group.com.splitburn.app"
    public static let databaseFileName = "finance.sqlite"
    public static let widgetKind = "BalanceWidget"
}

public enum SharedStorageError: LocalizedError, Equatable {
    case appGroupUnavailable
    case databaseMissing
    case sqlite(code: Int32, message: String)
    case invalidExpense(String)

    public var errorDescription: String? {
        switch self {
        case .appGroupUnavailable:
            return "SplitBurn's shared storage isn't available. Enable the App Groups capability (group.com.splitburn.app)."
        case .databaseMissing:
            return "Open SplitBurn once to set up your ledger."
        case let .sqlite(code, message):
            return "Ledger error \(code): \(message)"
        case let .invalidExpense(reason):
            return reason
        }
    }
}

public struct LedgerFriend: Equatable {
    public let id: String
    public let name: String
    public let paymentHandle: String?

    public init(id: String, name: String, paymentHandle: String? = nil) {
        self.id = id
        self.name = name
        self.paymentHandle = paymentHandle
    }
}

public struct FriendShare: Equatable {
    public let friend: LedgerFriend
    public let shareMinor: Int64

    public init(friend: LedgerFriend, shareMinor: Int64) {
        self.friend = friend
        self.shareMinor = shareMinor
    }
}

/// A fully allocated expense; Swift twin of Dart's `ExpenseDraft`.
public struct SharedExpense: Equatable {
    public var merchant: String
    public var totalMinor: Int64
    public var myShareMinor: Int64
    /// `transactions.category` code, e.g. "Food".
    public var category: String
    /// `transactions.source` code, e.g. "VOICE_INTENT".
    public var source: String
    /// `nil` when the user paid.
    public var payer: LedgerFriend?
    /// Every friend's share, including a paying friend's own share.
    public var friendShares: [FriendShare]
    public var createdAt: Date

    public init(
        merchant: String, totalMinor: Int64, myShareMinor: Int64, category: String,
        source: String, payer: LedgerFriend?, friendShares: [FriendShare], createdAt: Date
    ) {
        self.merchant = merchant
        self.totalMinor = totalMinor
        self.myShareMinor = myShareMinor
        self.category = category
        self.source = source
        self.payer = payer
        self.friendShares = friendShares
        self.createdAt = createdAt
    }

    /// Equal split between the user and `friends`; leftover paisa go to the
    /// earliest participants, listed payer first (same rule as Dart).
    public static func equalSplit(
        merchant: String, totalMinor: Int64, friends: [LedgerFriend], payer: LedgerFriend?,
        category: String, source: String, createdAt: Date = Date()
    ) -> SharedExpense {
        enum Participant: Equatable { case me, friend(LedgerFriend) }
        var participants: [Participant] = []
        if let payer { participants.append(.friend(payer)) }
        participants.append(.me)
        for friend in friends where friend.id != payer?.id
            && !participants.contains(.friend(friend)) {
            participants.append(.friend(friend))
        }
        let count = Int64(participants.count)
        let base = totalMinor / count
        let remainder = Int(totalMinor % count)
        var mine: Int64 = 0
        var shares: [FriendShare] = []
        for (index, participant) in participants.enumerated() {
            let share = base + (index < remainder ? 1 : 0)
            switch participant {
            case .me: mine = share
            case let .friend(friend): shares.append(FriendShare(friend: friend, shareMinor: share))
            }
        }
        return SharedExpense(
            merchant: merchant, totalMinor: totalMinor, myShareMinor: mine,
            category: category, source: source, payer: payer, friendShares: shares,
            createdAt: createdAt)
    }

    func validate() throws {
        if merchant.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            throw SharedStorageError.invalidExpense("Add a merchant or description.")
        }
        if totalMinor <= 0 { throw SharedStorageError.invalidExpense("The amount must be more than zero.") }
        if myShareMinor < 0 || friendShares.contains(where: { $0.shareMinor < 0 }) {
            throw SharedStorageError.invalidExpense("Shares can't be negative.")
        }
        let allocated = myShareMinor + friendShares.reduce(0) { $0 + $1.shareMinor }
        if allocated != totalMinor {
            throw SharedStorageError.invalidExpense("Shares add up to \(allocated) but the bill is \(totalMinor).")
        }
        if let payer {
            if !friendShares.contains(where: { $0.friend.id == payer.id }) {
                throw SharedStorageError.invalidExpense("\(payer.name) paid but isn't on the bill.")
            }
            if myShareMinor == 0 {
                throw SharedStorageError.invalidExpense("You have no share in a bill \(payer.name) paid.")
            }
        }
    }
}

public enum SQLValue {
    case int(Int64)
    case double(Double)
    case text(String)
    case null
}

public final class SharedSQLiteManager {
    public enum AccessMode { case readOnly, readWrite }

    public static var appGroupIdentifier: String { SharedStorageConstants.appGroupIdentifier }

    public static func databaseURL() throws -> URL {
        guard let container = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: SharedStorageConstants.appGroupIdentifier
        ) else { throw SharedStorageError.appGroupUnavailable }
        return container.appendingPathComponent(SharedStorageConstants.databaseFileName)
    }

    public let mode: AccessMode
    private var db: OpaquePointer?

    /// Opens the shared ledger. Read-only connections (WidgetKit) never create
    /// the file; read-write connections create it and apply the schema.
    public init(mode: AccessMode, databaseURL: URL? = nil) throws {
        let url = try databaseURL ?? Self.databaseURL()
        if mode == .readOnly && !FileManager.default.fileExists(atPath: url.path) {
            throw SharedStorageError.databaseMissing
        }
        let flags = (mode == .readOnly
            ? SQLITE_OPEN_READONLY
            : SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE) | SQLITE_OPEN_FULLMUTEX
        var handle: OpaquePointer?
        let rc = sqlite3_open_v2(url.path, &handle, flags, nil)
        guard rc == SQLITE_OK, let handle else {
            let message = handle.map { String(cString: sqlite3_errmsg($0)) } ?? "unable to open"
            sqlite3_close_v2(handle)
            throw SharedStorageError.sqlite(code: rc, message: message)
        }
        self.db = handle
        self.mode = mode
        try configureConnection()
        if mode == .readWrite { try ensureSchema() }
    }

    deinit {
        sqlite3_close_v2(db)
    }

    // MARK: - Connection setup (CLAUDE.md §2 rule 2)

    private func configureConnection() throws {
        sqlite3_busy_timeout(db, 5000)
        if mode == .readWrite {
            try execute("PRAGMA journal_mode = WAL;")
        } else {
            // A read-only handle can't switch modes; on a WAL file this just
            // reports "wal", so a failure here is not fatal.
            try? execute("PRAGMA journal_mode = WAL;")
        }
        try execute("PRAGMA busy_timeout = 5000;")
        try execute("PRAGMA foreign_keys = ON;")
    }

    /// Idempotent: every statement is IF NOT EXISTS / OR IGNORE, and
    /// `user_version` is left to Drift.
    private func ensureSchema() throws {
        try inTransaction {
            for statement in FinanceSchema.statements {
                try execute(statement)
            }
        }
    }

    // MARK: - Ledger writes

    /// Inserts the transaction, its IOUs and the bank delta atomically.
    /// Returns the new transaction id.
    @discardableResult
    public func logExpense(_ expense: SharedExpense) throws -> String {
        try expense.validate()
        let transactionId = UUID().uuidString.lowercased()
        try inTransaction {
            try run(
                """
                INSERT INTO transactions (id, merchant, total_paid, my_share, category,
                  paid_by_me, source, receipt_image_path, created_at)
                VALUES (?, ?, ?, ?, ?, ?, ?, NULL, ?)
                """,
                [
                    .text(transactionId),
                    .text(expense.merchant.trimmingCharacters(in: .whitespacesAndNewlines)),
                    .double(Money.toMajor(expense.totalMinor)),
                    .double(Money.toMajor(expense.myShareMinor)),
                    .text(expense.category),
                    .int(expense.payer == nil ? 1 : 0),
                    .text(expense.source),
                    .int(Int64(expense.createdAt.timeIntervalSince1970)),
                ])
            if let payer = expense.payer {
                try insertSplit(transactionId, payer, expense.myShareMinor, direction: "I_OWE")
            } else {
                for share in expense.friendShares where share.shareMinor > 0 {
                    try insertSplit(transactionId, share.friend, share.shareMinor, direction: "OWES_ME")
                }
                try adjustBankBalance(by: -expense.totalMinor)
            }
        }
        return transactionId
    }

    /// The friend the user most recently split with under this name
    /// (case-insensitive), or a new identity.
    public func resolveFriend(named name: String) throws -> LedgerFriend {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let existing = try query(
            """
            SELECT s.friend_id, s.friend_name,
              (SELECT s2.friend_payment_handle FROM split_entries s2
                 JOIN transactions t2 ON t2.id = s2.transaction_id
                WHERE s2.friend_id = s.friend_id AND s2.friend_payment_handle IS NOT NULL
                ORDER BY t2.created_at DESC LIMIT 1)
            FROM split_entries s JOIN transactions t ON t.id = s.transaction_id
            WHERE lower(s.friend_name) = lower(?)
            ORDER BY t.created_at DESC, s.id LIMIT 1
            """,
            [.text(trimmed)]
        ) { row in
            LedgerFriend(id: row.string(0), name: row.string(1), paymentHandle: row.optionalString(2))
        }
        return existing.first ?? LedgerFriend(id: UUID().uuidString.lowercased(), name: trimmed)
    }

    private func insertSplit(
        _ transactionId: String, _ friend: LedgerFriend, _ amountMinor: Int64, direction: String
    ) throws {
        try run(
            """
            INSERT INTO split_entries (id, transaction_id, friend_id, friend_name,
              friend_payment_handle, amount, direction, is_settled, settled_at)
            VALUES (?, ?, ?, ?, ?, ?, ?, 0, NULL)
            """,
            [
                .text(UUID().uuidString.lowercased()),
                .text(transactionId),
                .text(friend.id),
                .text(friend.name),
                friend.paymentHandle.map(SQLValue.text) ?? .null,
                .double(Money.toMajor(amountMinor)),
                .text(direction),
            ])
    }

    private func adjustBankBalance(by deltaMinor: Int64) throws {
        guard deltaMinor != 0 else { return }
        try run(
            "UPDATE budget_config SET current_bank_balance = ROUND(current_bank_balance + ?, 2) WHERE id = 1",
            [.double(Money.toMajor(deltaMinor))])
    }

    // MARK: - Reads

    /// Balance, IOUs and the personal-spend windows the burn-rate math needs.
    public func readSnapshot(now: Date = Date(), calendar: Calendar = .current) throws -> LedgerSnapshot {
        let summary = try query(
            """
            SELECT v.monthly_allowance, v.bank_balance, v.total_owed_to_me, v.total_i_owe,
                   c.cycle_reset_day, c.currency_symbol
            FROM financial_summary_view v, budget_config c WHERE c.id = 1
            """
        ) { row in
            (allowance: row.double(0), bank: row.double(1), owedToMe: row.double(2),
             iOwe: row.double(3), resetDay: Int(row.int(4)), symbol: row.string(5))
        }
        guard let s = summary.first else {
            throw SharedStorageError.databaseMissing
        }
        let cycle = BudgetCycle(containing: now, resetDay: s.resetDay, calendar: calendar)
        let startOfToday = calendar.startOfDay(for: now)
        let startOfTomorrow = calendar.date(byAdding: .day, value: 1, to: startOfToday)!
        let weekStart = calendar.date(byAdding: .day, value: -6, to: startOfToday)!
        let todayStartInCycle = max(cycle.start, min(startOfToday, cycle.end))
        let spentBeforeToday = try personalSpend(from: cycle.start, to: todayStartInCycle)
        let spentToday = try personalSpend(from: startOfToday, to: startOfTomorrow)
        let spentLast7Days = try personalSpend(from: weekStart, to: startOfTomorrow)

        return LedgerSnapshot(
            monthlyAllowanceMinor: Money.toMinor(s.allowance),
            bankBalanceMinor: Money.toMinor(s.bank),
            owedToMeMinor: Money.toMinor(s.owedToMe),
            iOweMinor: Money.toMinor(s.iOwe),
            spentBeforeTodayMinor: spentBeforeToday,
            spentTodayMinor: spentToday,
            last7DaysSpendMinor: spentLast7Days,
            currencySymbol: s.symbol,
            cycle: cycle,
            now: now)
    }

    /// Sum of `my_share` with `created_at` in `[from, to)`.
    public func personalSpend(from: Date, to: Date) throws -> Int64 {
        guard from < to else { return 0 }
        let rows = try query(
            "SELECT COALESCE(SUM(my_share), 0.0) FROM transactions WHERE created_at >= ? AND created_at < ?",
            [.int(Int64(from.timeIntervalSince1970)), .int(Int64(to.timeIntervalSince1970))]
        ) { $0.double(0) }
        return Money.toMinor(rows.first ?? 0)
    }

    // MARK: - SQLite plumbing

    public func execute(_ sql: String) throws {
        var error: UnsafeMutablePointer<CChar>?
        let rc = sqlite3_exec(db, sql, nil, nil, &error)
        if rc != SQLITE_OK {
            let message = error.map { String(cString: $0) } ?? lastErrorMessage
            sqlite3_free(error)
            throw SharedStorageError.sqlite(code: rc, message: message)
        }
    }

    public func run(_ sql: String, _ values: [SQLValue] = []) throws {
        let statement = try prepare(sql, values)
        defer { sqlite3_finalize(statement) }
        let rc = sqlite3_step(statement)
        guard rc == SQLITE_DONE || rc == SQLITE_ROW else {
            throw SharedStorageError.sqlite(code: rc, message: lastErrorMessage)
        }
    }

    public func query<T>(_ sql: String, _ values: [SQLValue] = [], map: (Row) throws -> T) throws -> [T] {
        let statement = try prepare(sql, values)
        defer { sqlite3_finalize(statement) }
        var results: [T] = []
        while true {
            let rc = sqlite3_step(statement)
            if rc == SQLITE_DONE { break }
            guard rc == SQLITE_ROW else {
                throw SharedStorageError.sqlite(code: rc, message: lastErrorMessage)
            }
            results.append(try map(Row(statement: statement!)))
        }
        return results
    }

    /// `BEGIN IMMEDIATE` takes the write lock up front so a concurrent writer
    /// waits on busy_timeout instead of failing mid-transaction.
    public func inTransaction(_ body: () throws -> Void) throws {
        try execute("BEGIN IMMEDIATE;")
        do {
            try body()
            try execute("COMMIT;")
        } catch {
            try? execute("ROLLBACK;")
            throw error
        }
    }

    private var lastErrorMessage: String { String(cString: sqlite3_errmsg(db)) }

    private func prepare(_ sql: String, _ values: [SQLValue]) throws -> OpaquePointer? {
        var statement: OpaquePointer?
        let rc = sqlite3_prepare_v2(db, sql, -1, &statement, nil)
        guard rc == SQLITE_OK else {
            throw SharedStorageError.sqlite(code: rc, message: lastErrorMessage)
        }
        for (offset, value) in values.enumerated() {
            let index = Int32(offset + 1)
            let bindRC: Int32
            switch value {
            case let .int(v): bindRC = sqlite3_bind_int64(statement, index, v)
            case let .double(v): bindRC = sqlite3_bind_double(statement, index, v)
            case let .text(v): bindRC = sqlite3_bind_text(statement, index, v, -1, sqliteTransient)
            case .null: bindRC = sqlite3_bind_null(statement, index)
            }
            if bindRC != SQLITE_OK {
                sqlite3_finalize(statement)
                throw SharedStorageError.sqlite(code: bindRC, message: lastErrorMessage)
            }
        }
        return statement
    }

    public struct Row {
        let statement: OpaquePointer

        public func int(_ column: Int32) -> Int64 { sqlite3_column_int64(statement, column) }

        public func double(_ column: Int32) -> Double { sqlite3_column_double(statement, column) }

        public func string(_ column: Int32) -> String {
            optionalString(column) ?? ""
        }

        public func optionalString(_ column: Int32) -> String? {
            guard sqlite3_column_type(statement, column) != SQLITE_NULL,
                  let text = sqlite3_column_text(statement, column) else { return nil }
            return String(cString: text)
        }
    }
}

/// SQLite copies bound text immediately (SQLITE_TRANSIENT).
private let sqliteTransient = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
