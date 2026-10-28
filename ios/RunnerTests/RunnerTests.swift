import XCTest

@testable import Runner

/// Swift side of the parser parity check: same fixtures as
/// test/domain/expense_phrase_parser_test.dart.
final class ExpensePhraseParserTests: XCTestCase {
  private struct Fixture: Decodable {
    let input: String
    let amount_minor: Int64?
    let merchant: String?
    let friends: [String]?
    let payer: String?
    let category: String?
  }

  func testSharedFixtures() throws {
    let url = URL(fileURLWithPath: #filePath)
      .deletingLastPathComponent()  // RunnerTests
      .deletingLastPathComponent()  // ios
      .deletingLastPathComponent()  // repo root
      .appendingPathComponent("test/fixtures/expense_phrases.json")
    let fixtures = try JSONDecoder().decode([Fixture].self, from: Data(contentsOf: url))
    XCTAssertFalse(fixtures.isEmpty)
    for fixture in fixtures {
      let parsed = ExpensePhraseParser.parse(fixture.input)
      guard let amount = fixture.amount_minor else {
        XCTAssertNil(parsed, fixture.input)
        continue
      }
      let result = try XCTUnwrap(parsed, fixture.input)
      XCTAssertEqual(result.amountMinor, amount, fixture.input)
      XCTAssertEqual(result.merchant, fixture.merchant, fixture.input)
      XCTAssertEqual(result.friends, fixture.friends, fixture.input)
      XCTAssertEqual(result.payer, fixture.payer, fixture.input)
      XCTAssertEqual(result.category, fixture.category, fixture.input)
    }
  }

  func testFriendCSV() {
    XCTAssertEqual(
      ExpensePhraseParser.friendNames(fromCSV: "rahul, Priya and aman & RAHUL"),
      ["Rahul", "Priya", "Aman"])
  }
}

final class SharedSQLiteManagerTests: XCTestCase {
  private var directory: URL!
  private var databaseURL: URL!

  override func setUpWithError() throws {
    directory = FileManager.default.temporaryDirectory
      .appendingPathComponent(UUID().uuidString, isDirectory: true)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    databaseURL = directory.appendingPathComponent("finance.sqlite")
  }

  override func tearDownWithError() throws {
    try? FileManager.default.removeItem(at: directory)
  }

  func testReadOnlyNeverCreatesTheFile() {
    XCTAssertThrowsError(try SharedSQLiteManager(mode: .readOnly, databaseURL: databaseURL)) {
      XCTAssertEqual($0 as? SharedStorageError, .databaseMissing)
    }
  }

  func testWALAndDefaults() throws {
    let manager = try SharedSQLiteManager(mode: .readWrite, databaseURL: databaseURL)
    let mode = try manager.query("PRAGMA journal_mode") { $0.string(0) }
    XCTAssertEqual(mode, ["wal"])
    let snapshot = try manager.readSnapshot()
    XCTAssertEqual(snapshot.bankBalanceMinor, 15_000_00)
    XCTAssertEqual(snapshot.currencySymbol, "₹")
  }

  func testNetShareSplitIWrote() throws {
    let manager = try SharedSQLiteManager(mode: .readWrite, databaseURL: databaseURL)
    let rahul = try manager.resolveFriend(named: "Rahul")
    let priya = try manager.resolveFriend(named: "Priya")
    let expense = SharedExpense.equalSplit(
      merchant: "Domino's", totalMinor: 450_00, friends: [rahul, priya], payer: nil,
      category: "Food", source: "VOICE_INTENT")
    XCTAssertEqual(expense.myShareMinor, 150_00)
    try manager.logExpense(expense)

    let reader = try SharedSQLiteManager(mode: .readOnly, databaseURL: databaseURL)
    let snapshot = try reader.readSnapshot()
    XCTAssertEqual(snapshot.bankBalanceMinor, 15_000_00 - 450_00)
    XCTAssertEqual(snapshot.owedToMeMinor, 300_00)
    XCTAssertEqual(snapshot.spentTodayMinor, 150_00)
    XCTAssertEqual(try manager.resolveFriend(named: "rahul").id, rahul.id)
  }

  func testFriendPaidOwesThePayer() throws {
    let manager = try SharedSQLiteManager(mode: .readWrite, databaseURL: databaseURL)
    let rahul = try manager.resolveFriend(named: "Rahul")
    let expense = SharedExpense.equalSplit(
      merchant: "Chai", totalMinor: 100_00, friends: [rahul], payer: rahul,
      category: "Food", source: "VOICE_INTENT")
    XCTAssertEqual(expense.friendShares.first?.shareMinor, 50_00)
    try manager.logExpense(expense)
    let snapshot = try manager.readSnapshot()
    XCTAssertEqual(snapshot.bankBalanceMinor, 15_000_00)
    XCTAssertEqual(snapshot.iOweMinor, 50_00)
  }

  /// Same cases as test/domain/burn_rate_test.dart.
  func testBurnRateSharedFixtures() throws {
    struct Expect: Decodable {
      let days_remaining: Int
      let daily_limit: Int64
      let left_today: Int64
      let tomorrow_limit: Int64?
      let avg_daily_burn: Int64
      let true_spendable: Int64
      let days_until_broke: Int?
      let broke_date: String?
      let survival: Bool
    }
    struct Case: Decodable {
      let name: String
      let today: String
      let reset_day: Int
      let allowance: Int64
      let bank: Int64
      let owed_to_me: Int64
      let i_owe: Int64
      let spent_before_today: Int64
      let spent_today: Int64
      let last_7_days: Int64
      let expect: Expect
    }
    let url = URL(fileURLWithPath: #filePath)
      .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
      .appendingPathComponent("test/fixtures/burn_rate_cases.json")
    let cases = try JSONDecoder().decode([Case].self, from: Data(contentsOf: url))
    XCTAssertFalse(cases.isEmpty)

    let calendar = Calendar(identifier: .gregorian)
    let isoDay = DateFormatter()
    isoDay.calendar = calendar
    isoDay.locale = Locale(identifier: "en_US_POSIX")
    isoDay.timeZone = calendar.timeZone
    isoDay.dateFormat = "yyyy-MM-dd"

    for c in cases {
      let today = try XCTUnwrap(isoDay.date(from: c.today), c.name)
      let snapshot = LedgerSnapshot(
        monthlyAllowanceMinor: c.allowance, bankBalanceMinor: c.bank, owedToMeMinor: c.owed_to_me,
        iOweMinor: c.i_owe, spentBeforeTodayMinor: c.spent_before_today,
        spentTodayMinor: c.spent_today, last7DaysSpendMinor: c.last_7_days, currencySymbol: "₹",
        cycle: BudgetCycle(containing: today, resetDay: c.reset_day, calendar: calendar), now: today)
      let m = BurnRateMetrics(snapshot: snapshot, calendar: calendar)
      XCTAssertEqual(m.daysRemaining, c.expect.days_remaining, c.name)
      XCTAssertEqual(m.dailyLimitMinor, c.expect.daily_limit, c.name)
      XCTAssertEqual(m.leftTodayMinor, c.expect.left_today, c.name)
      XCTAssertEqual(m.tomorrowLimitMinor, c.expect.tomorrow_limit, c.name)
      XCTAssertEqual(m.avgDailyBurnMinor, c.expect.avg_daily_burn, c.name)
      XCTAssertEqual(m.trueSpendableMinor, c.expect.true_spendable, c.name)
      XCTAssertEqual(m.daysUntilBroke, c.expect.days_until_broke, c.name)
      XCTAssertEqual(m.brokeDate.map(isoDay.string(from:)), c.expect.broke_date, c.name)
      XCTAssertEqual(m.isSurvivalMode, c.expect.survival, c.name)
    }
  }
}
