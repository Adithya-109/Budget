import 'package:drift/drift.dart';

import 'converters.dart';

// Column getters map to the snake_case column names in CLAUDE.md §3.
// DateTime columns are stored as INTEGER Unix epoch seconds (build.yaml keeps
// `store_date_time_values_as_text: false`), which is what Swift/Kotlin write.

/// Single-row settings table; the CHECK keeps it a singleton.
@DataClassName('BudgetConfigRow')
class BudgetConfig extends Table {
  @override
  String get tableName => 'budget_config';

  // CHECK constraints reference their own column; not real recursion.
  IntColumn get id => integer()
      // ignore: recursive_getters
      .check(id.equals(1))
      .withDefault(const Constant(1))();
  RealColumn get monthlyAllowance =>
      real().withDefault(const Constant(15000.0))();
  RealColumn get currentBankBalance =>
      real().withDefault(const Constant(15000.0))();

  /// Day of month the allowance arrives. 29–31 clamp to the month's last day.
  IntColumn get cycleResetDay => integer()
      // ignore: recursive_getters
      .check(cycleResetDay.isBetweenValues(1, 31))
      .withDefault(const Constant(1))();
  TextColumn get currencySymbol => text().withDefault(const Constant('₹'))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('LedgerTransaction')
@TableIndex(name: 'idx_transactions_created_at', columns: {#createdAt})
class Transactions extends Table {
  @override
  String get tableName => 'transactions';

  TextColumn get id => text()();
  TextColumn get merchant => text()();

  /// Cash that left whoever paid (the user's bank when [paidByMe]).
  RealColumn get totalPaid => real()();

  /// The user's personal cut: the only part that counts as spending.
  RealColumn get myShare => real()();
  TextColumn get category => text().map(const TxnCategoryConverter())();
  BoolColumn get paidByMe => boolean()();
  TextColumn get source => text().map(const TxnSourceConverter())();
  TextColumn get receiptImagePath => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('SplitEntry')
@TableIndex(name: 'idx_split_entries_transaction', columns: {#transactionId})
@TableIndex(
  name: 'idx_split_entries_friend_open',
  columns: {#friendId, #isSettled},
)
class SplitEntries extends Table {
  @override
  String get tableName => 'split_entries';

  TextColumn get id => text()();
  TextColumn get transactionId =>
      text().references(Transactions, #id, onDelete: KeyAction.cascade)();
  TextColumn get friendId => text()();
  TextColumn get friendName => text()();

  /// UPI ID (`name@okaxis`) or Venmo / Cash App handle.
  TextColumn get friendPaymentHandle => text().nullable()();
  RealColumn get amount => real()();
  TextColumn get direction => text().map(const SplitDirectionConverter())();
  BoolColumn get isSettled => boolean().withDefault(const Constant(false))();
  DateTimeColumn get settledAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('Subscription')
@TableIndex(
  name: 'idx_subscriptions_billing',
  columns: {#isActive, #billingDate},
)
class Subscriptions extends Table {
  @override
  String get tableName => 'subscriptions';

  TextColumn get id => text()();
  TextColumn get name => text()();
  RealColumn get amount => real()();
  RealColumn get myShare => real()();

  /// Next charge time.
  DateTimeColumn get billingDate => dateTime()();
  BoolColumn get isFreeTrial => boolean().withDefault(const Constant(false))();
  TextColumn get autoSplitGroupJson =>
      text().map(const SplitGroupConverter()).nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();

  /// Where to cancel a free trial before it converts (Free Trial Shield).
  TextColumn get cancelUrl => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
