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

  func testBurnRateMetrics() {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "Asia/Kolkata")!
    let now = calendar.date(from: DateComponents(year: 2026, month: 10, day: 28, hour: 15))!
    let snapshot = LedgerSnapshot(
      monthlyAllowanceMinor: 15_000_00, bankBalanceMinor: 4_000_00, owedToMeMinor: 0,
      iOweMinor: 500_00, spentBeforeTodayMinor: 13_400_00, spentTodayMinor: 650_00,
      last7DaysSpendMinor: 3_500_00, currencySymbol: "₹",
      cycle: BudgetCycle(containing: now, resetDay: 1, calendar: calendar), now: now)
    let metrics = BurnRateMetrics(snapshot: snapshot, calendar: calendar)
    XCTAssertEqual(metrics.daysRemaining, 4)
    XCTAssertEqual(metrics.dailyLimitMinor, 400_00)
    XCTAssertEqual(metrics.leftTodayMinor, -250_00)
    XCTAssertEqual(metrics.tomorrowLimitMinor, 316_66)
    XCTAssertEqual(metrics.trueSpendableMinor, 3_500_00)
    XCTAssertEqual(metrics.daysUntilBroke, 7)
    XCTAssertFalse(metrics.isSurvivalMode)
  }
}
