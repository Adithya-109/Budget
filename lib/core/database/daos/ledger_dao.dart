import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../domain/budget_cycle.dart';
import '../../../domain/burn_rate.dart';
import '../../../domain/debt_simplifier.dart';
import '../../../domain/expense_draft.dart';
import '../../money.dart';
import '../app_database.dart';
import '../ledger_models.dart';
import '../tables.dart';

part 'ledger_dao.drift.dart';

/// Ledger key for the user in [Debt] graphs built from their splits.
const kSelfId = 'self';

/// Net-share accounting over `transactions` + `split_entries`.
///
/// Every write follows the contract in CLAUDE.md §6: one SQL transaction per
/// event, and bank balance changes are relative updates so a concurrent
/// native writer never loses an update.
@DriftAccessor(tables: [Transactions, SplitEntries, BudgetConfig])
class LedgerDao extends DatabaseAccessor<AppDatabase> with _$LedgerDaoMixin {
  LedgerDao(super.attachedDatabase);

  static const _uuid = Uuid();

  // ---------------------------------------------------------------------------
  // Writes
  // ---------------------------------------------------------------------------

  /// Logs an expense and its IOUs. Returns the transaction id.
  ///
  /// ₹1,200 dinner for 4 that the user paid: bank −1,200, personal spend +300,
  /// three ₹300 receivables. Same dinner a friend paid: bank unchanged,
  /// personal spend +300, one ₹300 payable to that friend.
  Future<String> logExpense(ExpenseDraft draft, {String? id}) {
    final transactionId = id ?? _uuid.v4();
    return transaction(() async {
      await _insertExpense(
        transactionId,
        draft,
        draft.createdAt ?? DateTime.now(),
      );
      return transactionId;
    });
  }

  /// Replaces how an existing transaction is split, e.g. turning an
  /// auto-captured ₹450 UPI payment into "450 with Rahul and Priya". The id,
  /// timestamp and source are kept; all old bank effects are reversed first.
  Future<void> resplitTransaction(String transactionId, ExpenseDraft draft) {
    return transaction(() async {
      final existing = await _requireTransaction(transactionId);
      await _deleteExpense(existing);
      await _insertExpense(
        transactionId,
        ExpenseDraft(
          merchant: draft.merchant,
          totalPaidMinor: draft.totalPaidMinor,
          myShareMinor: draft.myShareMinor,
          payer: draft.payer,
          category: draft.category,
          friendShares: draft.friendShares,
          source: existing.source,
          receiptImagePath: draft.receiptImagePath ?? existing.receiptImagePath,
        ),
        existing.createdAt,
      );
    });
  }

  /// Deletes a transaction as if it never happened: its splits go with it and
  /// every bank balance change it caused (including settlements) is undone.
  Future<void> deleteTransaction(String transactionId) {
    return transaction(() async {
      final existing = await (select(
        transactions,
      )..where((t) => t.id.equals(transactionId))).getSingleOrNull();
      if (existing != null) await _deleteExpense(existing);
    });
  }

  /// The True Liquid Balance reconciler: the user typed the balance their
  /// bank app shows. Any gap versus the ledger is resolved in one SQL
  /// transaction (so it can't race a native writer's relative update):
  ///
  /// * Bank shows **less** and [logShortfallAsSpend]: the gap is spending
  ///   that never got logged, so it becomes an "Untracked spending" expense
  ///   (it counts against the budget and the bank lands on [actualMinor]).
  /// * Bank shows **more**, or the shortfall should not count as spending:
  ///   the balance is simply set (e.g. pocket money arrived).
  Future<ReconciliationResult> reconcileBankBalance(
    int actualMinor, {
    bool logShortfallAsSpend = true,
    DateTime? at,
  }) {
    return transaction(() async {
      final config = await (select(
        budgetConfig,
      )..where((c) => c.id.equals(1))).getSingle();
      final previous = Money.toMinor(config.currentBankBalance);
      final delta = actualMinor - previous;
      String? loggedId;
      if (delta < 0 && logShortfallAsSpend) {
        loggedId = _uuid.v4();
        await _insertExpense(
          loggedId,
          ExpenseDraft(
            merchant: untrackedSpendingMerchant,
            totalPaidMinor: -delta,
            myShareMinor: -delta,
            payer: const PaidByMe(),
            category: TxnCategory.other,
          ),
          at ?? DateTime.now(),
        );
      } else if (delta != 0) {
        await (update(budgetConfig)..where((c) => c.id.equals(1))).write(
          BudgetConfigCompanion(
            currentBankBalance: Value(Money.toMajor(actualMinor)),
          ),
        );
      }
      return ReconciliationResult(
        previousMinor: previous,
        actualMinor: actualMinor,
        untrackedSpendTransactionId: loggedId,
      );
    });
  }

  static const untrackedSpendingMerchant = 'Untracked spending';

  Future<void> recategorize(String transactionId, TxnCategory category) async {
    await (update(transactions)..where((t) => t.id.equals(transactionId)))
        .write(TransactionsCompanion(category: Value(category)));
  }

  Future<void> renameMerchant(String transactionId, String merchant) async {
    final trimmed = merchant.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError.value(merchant, 'merchant', 'is empty');
    }
    await (update(transactions)..where((t) => t.id.equals(transactionId)))
        .write(TransactionsCompanion(merchant: Value(trimmed)));
  }

  /// Marks one split settled and moves the cash: a friend paying back adds to
  /// the bank (not income, not negative spend); the user paying a friend
  /// subtracts. Returns `false` if it was already settled.
  Future<bool> settleSplit(String splitId, {DateTime? at}) {
    return transaction(() async {
      final entry = await _requireSplit(splitId);
      final changed =
          await (update(
                splitEntries,
              )..where((s) => s.id.equals(splitId) & s.isSettled.equals(false)))
              .write(
                SplitEntriesCompanion(
                  isSettled: const Value(true),
                  settledAt: Value(at ?? DateTime.now()),
                ),
              );
      if (changed == 0) return false;
      await _adjustBankBalance(_settlementCashDelta(entry));
      return true;
    });
  }

  /// Undoes [settleSplit] (e.g. the UPI payment bounced). Returns `false` if
  /// the split was not settled.
  Future<bool> unsettleSplit(String splitId) {
    return transaction(() async {
      final entry = await _requireSplit(splitId);
      final changed =
          await (update(splitEntries)
                ..where((s) => s.id.equals(splitId) & s.isSettled.equals(true)))
              .write(
                const SplitEntriesCompanion(
                  isSettled: Value(false),
                  settledAt: Value(null),
                ),
              );
      if (changed == 0) return false;
      await _adjustBankBalance(-_settlementCashDelta(entry));
      return true;
    });
  }

  /// Settles every open split with one friend in both directions, moving only
  /// the net cash (they owed ₹500, the user owed them ₹200 → bank +₹300).
  Future<SettlementResult> settleAllWithFriend(
    String friendId, {
    DateTime? at,
  }) {
    return transaction(() async {
      final open =
          await (select(splitEntries)..where(
                (s) => s.friendId.equals(friendId) & s.isSettled.equals(false),
              ))
              .get();
      if (open.isEmpty) {
        return const SettlementResult(settledCount: 0, bankDeltaMinor: 0);
      }
      await (update(
        splitEntries,
      )..where((s) => s.id.isIn(open.map((e) => e.id)))).write(
        SplitEntriesCompanion(
          isSettled: const Value(true),
          settledAt: Value(at ?? DateTime.now()),
        ),
      );
      final delta = open.fold<int>(
        0,
        (sum, e) => sum + _settlementCashDelta(e),
      );
      await _adjustBankBalance(delta);
      return SettlementResult(settledCount: open.length, bankDeltaMinor: delta);
    });
  }

  /// Saves a friend's UPI / Venmo handle on all of their splits so future
  /// "Settle Now" links can be generated.
  Future<void> updateFriendPaymentHandle(
    String friendId,
    String? handle,
  ) async {
    final trimmed = handle?.trim();
    await (update(
      splitEntries,
    )..where((s) => s.friendId.equals(friendId))).write(
      SplitEntriesCompanion(
        friendPaymentHandle: Value(
          trimmed == null || trimmed.isEmpty ? null : trimmed,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Net-share reads
  // ---------------------------------------------------------------------------

  /// One consistent read of everything the burn-rate engine needs for
  /// [today] (any time on that local day) within [cycle]. Re-emits whenever
  /// transactions, splits or settings change.
  Stream<LedgerSnapshot> watchLedgerSnapshot({
    required BudgetCycle cycle,
    required DateTime today,
  }) => _ledgerSnapshotQuery(cycle, today).watchSingle();

  Future<LedgerSnapshot> ledgerSnapshot({
    required BudgetCycle cycle,
    required DateTime today,
  }) => _ledgerSnapshotQuery(cycle, today).getSingle();

  /// `financial_summary_view` (all-time personal spend, open IOUs, balance).
  Stream<FinancialSummaryViewData> watchFinancialSummary() => attachedDatabase
      .select(attachedDatabase.financialSummaryView)
      .watchSingle();

  Future<FinancialSummaryViewData> financialSummary() => attachedDatabase
      .select(attachedDatabase.financialSummaryView)
      .getSingle();

  Stream<List<LedgerTransaction>> watchRecentTransactions({int limit = 50}) {
    return (select(transactions)
          ..orderBy([
            (t) => OrderingTerm.desc(t.createdAt),
            (t) => OrderingTerm.asc(t.id),
          ])
          ..limit(limit))
        .watch();
  }

  Stream<List<LedgerTransaction>> watchTransactionsBetween(
    DateTime start,
    DateTime end,
  ) {
    return (select(transactions)
          ..where((t) => _inRange(t, start, end))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .watch();
  }

  Future<LedgerTransaction?> transactionById(String id) =>
      (select(transactions)..where((t) => t.id.equals(id))).getSingleOrNull();

  Stream<List<SplitEntry>> watchSplitsForTransaction(String transactionId) {
    return (select(splitEntries)
          ..where((s) => s.transactionId.equals(transactionId))
          ..orderBy([(s) => OrderingTerm.asc(s.friendName)]))
        .watch();
  }

  /// Sum of `my_share` in `[start, end)`: personal spending only, never the
  /// cash fronted for friends.
  Future<int> personalSpendBetween(DateTime start, DateTime end) =>
      _personalSpendQuery(start, end).map(_readSum).getSingle();

  Stream<int> watchPersonalSpendBetween(DateTime start, DateTime end) =>
      _personalSpendQuery(start, end).map(_readSum).watchSingle();

  /// Personal spend per category in `[start, end)`, largest first.
  Stream<Map<TxnCategory, int>> watchCategorySpend(
    DateTime start,
    DateTime end,
  ) {
    final total = transactions.myShare.sum();
    final query = selectOnly(transactions)
      ..addColumns([transactions.category, total])
      ..where(_inRange(transactions, start, end))
      ..groupBy([transactions.category])
      ..orderBy([OrderingTerm.desc(total)]);
    return query.watch().map((rows) {
      final result = <TxnCategory, int>{};
      for (final row in rows) {
        final category = TxnCategory.fromCode(row.read(transactions.category)!);
        result[category] =
            (result[category] ?? 0) + Money.toMinor(row.read(total) ?? 0);
      }
      return result;
    });
  }

  /// One entry per local calendar day in `[start, end)`, zero-filled, for
  /// burn-rate averages and charts.
  Future<List<DailySpend>> dailyPersonalSpend(DateTime start, DateTime end) =>
      _dailySpendQuery(
        start,
        end,
      ).get().then((rows) => _bucketByDay(rows, start, end));

  Stream<List<DailySpend>> watchDailyPersonalSpend(
    DateTime start,
    DateTime end,
  ) => _dailySpendQuery(
    start,
    end,
  ).watch().map((rows) => _bucketByDay(rows, start, end));

  // ---------------------------------------------------------------------------
  // Social ledger reads
  // ---------------------------------------------------------------------------

  /// Every friend the user has ever split with, biggest open balance first.
  /// Name and payment handle come from the friend's most recent split.
  Stream<List<FriendBalance>> watchFriendBalances() =>
      _friendBalancesQuery().watch().map(_mapFriendBalances);

  Future<List<FriendBalance>> friendBalances() =>
      _friendBalancesQuery().get().then(_mapFriendBalances);

  /// Case-insensitive lookup by name for the natural-language parser
  /// ("…with rahul" → the existing Rahul).
  Future<FriendRef?> findFriendByName(String name) async {
    final needle = name.trim().toLowerCase();
    if (needle.isEmpty) return null;
    for (final balance in await friendBalances()) {
      if (balance.friend.name.toLowerCase() == needle) return balance.friend;
    }
    return null;
  }

  /// Unsettled splits, oldest first; optionally for one friend (nudge digest).
  Stream<List<OpenSplit>> watchOpenSplits({String? friendId}) =>
      _openSplitsQuery(friendId).watch().map(_mapOpenSplits);

  Future<List<OpenSplit>> openSplits({String? friendId}) =>
      _openSplitsQuery(friendId).get().then(_mapOpenSplits);

  /// The user's open IOUs as a debt graph (`kSelfId` is the user), ready for
  /// [DebtSimplifier] alongside a group's other debts.
  Future<List<Debt<String>>> openDebtGraph() async {
    return [
      for (final split in await openSplits())
        switch (split.direction) {
          SplitDirection.owesMe => Debt(
            from: split.friend.id,
            to: kSelfId,
            amountMinor: split.amountMinor,
          ),
          SplitDirection.iOwe => Debt(
            from: kSelfId,
            to: split.friend.id,
            amountMinor: split.amountMinor,
          ),
        },
    ];
  }

  // ---------------------------------------------------------------------------
  // Internals
  // ---------------------------------------------------------------------------

  Selectable<LedgerSnapshot> _ledgerSnapshotQuery(
    BudgetCycle cycle,
    DateTime today,
  ) {
    final local = today.toLocal();
    final dayStart = DateTime(local.year, local.month, local.day);
    final tomorrow = DateTime(local.year, local.month, local.day + 1);
    final weekStart = DateTime(local.year, local.month, local.day - 6);
    // Spend "before today" never reaches outside the cycle.
    final beforeTodayEnd = dayStart.isBefore(cycle.start)
        ? cycle.start
        : (dayStart.isAfter(cycle.end) ? cycle.end : dayStart);
    const sum =
        'SELECT COALESCE(SUM(my_share), 0.0) FROM transactions '
        'WHERE created_at >= ? AND created_at < ?';
    return customSelect(
      '''
      SELECT v.monthly_allowance AS allowance, v.bank_balance AS bank,
             v.total_owed_to_me AS owed_to_me, v.total_i_owe AS i_owe,
             c.currency_symbol AS symbol,
             ($sum) AS before_today, ($sum) AS spent_today, ($sum) AS last_7
      FROM financial_summary_view v, budget_config c
      WHERE c.id = 1
      ''',
      variables: [
        Variable.withDateTime(cycle.start),
        Variable.withDateTime(beforeTodayEnd),
        Variable.withDateTime(dayStart),
        Variable.withDateTime(tomorrow),
        Variable.withDateTime(weekStart),
        Variable.withDateTime(tomorrow),
      ],
      readsFrom: {transactions, splitEntries, budgetConfig},
    ).map(
      (row) => LedgerSnapshot(
        monthlyAllowanceMinor: Money.toMinor(row.read<double>('allowance')),
        bankBalanceMinor: Money.toMinor(row.read<double>('bank')),
        owedToMeMinor: Money.toMinor(row.read<double>('owed_to_me')),
        iOweMinor: Money.toMinor(row.read<double>('i_owe')),
        spentBeforeTodayMinor: Money.toMinor(row.read<double>('before_today')),
        spentTodayMinor: Money.toMinor(row.read<double>('spent_today')),
        last7DaysSpendMinor: Money.toMinor(row.read<double>('last_7')),
        currencySymbol: row.read<String>('symbol'),
        cycle: cycle,
        today: dayStart,
      ),
    );
  }

  Future<void> _insertExpense(
    String id,
    ExpenseDraft draft,
    DateTime createdAt,
  ) async {
    await into(transactions).insert(
      TransactionsCompanion.insert(
        id: id,
        merchant: draft.merchant.trim(),
        totalPaid: Money.toMajor(draft.totalPaidMinor),
        myShare: Money.toMajor(draft.myShareMinor),
        category: draft.category,
        paidByMe: draft.paidByMe,
        source: draft.source,
        receiptImagePath: Value(draft.receiptImagePath),
        createdAt: createdAt,
      ),
    );
    switch (draft.payer) {
      case PaidByMe():
        for (final MapEntry(key: friend, value: share)
            in draft.friendShares.entries) {
          if (share == 0) continue;
          await into(splitEntries)
              .insert(_splitRow(id, friend, share, SplitDirection.owesMe));
        }
        await _adjustBankBalance(-draft.totalPaidMinor);
      case PaidByFriend(:final friend):
        await into(splitEntries).insert(
          _splitRow(id, friend, draft.myShareMinor, SplitDirection.iOwe),
        );
    }
  }

  Future<void> _deleteExpense(LedgerTransaction existing) async {
    final settled =
        await (select(splitEntries)..where(
              (s) =>
                  s.transactionId.equals(existing.id) &
                  s.isSettled.equals(true),
            ))
            .get();
    var reversal = existing.paidByMe ? Money.toMinor(existing.totalPaid) : 0;
    for (final entry in settled) {
      reversal -= _settlementCashDelta(entry);
    }
    // Explicit delete as well as the FK cascade: a connection opened without
    // `foreign_keys = ON` (e.g. a debugging tool) must not orphan IOUs.
    await (delete(
      splitEntries,
    )..where((s) => s.transactionId.equals(existing.id))).go();
    await (delete(transactions)..where((t) => t.id.equals(existing.id))).go();
    await _adjustBankBalance(reversal);
  }

  SplitEntriesCompanion _splitRow(
    String transactionId,
    FriendRef friend,
    int amountMinor,
    SplitDirection direction,
  ) {
    return SplitEntriesCompanion.insert(
      id: _uuid.v4(),
      transactionId: transactionId,
      friendId: friend.id,
      friendName: friend.name,
      friendPaymentHandle: Value(friend.paymentHandle),
      amount: Money.toMajor(amountMinor),
      direction: direction,
    );
  }

  /// Cash that moves when [entry] is settled.
  static int _settlementCashDelta(SplitEntry entry) {
    final amount = Money.toMinor(entry.amount);
    return switch (entry.direction) {
      SplitDirection.owesMe => amount,
      SplitDirection.iOwe => -amount,
    };
  }

  Future<void> _adjustBankBalance(int deltaMinor) async {
    if (deltaMinor == 0) return;
    await customUpdate(
      'UPDATE budget_config '
      'SET current_bank_balance = ROUND(current_bank_balance + ?, 2) '
      'WHERE id = 1',
      variables: [Variable.withReal(Money.toMajor(deltaMinor))],
      updates: {budgetConfig},
      updateKind: UpdateKind.update,
    );
  }

  Future<LedgerTransaction> _requireTransaction(String id) async {
    final row = await transactionById(id);
    if (row == null) throw StateError('No transaction with id $id');
    return row;
  }

  Future<SplitEntry> _requireSplit(String id) async {
    final row = await (select(
      splitEntries,
    )..where((s) => s.id.equals(id))).getSingleOrNull();
    if (row == null) throw StateError('No split entry with id $id');
    return row;
  }

  Expression<bool> _inRange(
    $TransactionsTable t,
    DateTime start,
    DateTime end,
  ) =>
      t.createdAt.isBiggerOrEqualValue(start) &
      t.createdAt.isSmallerThanValue(end);

  late final Expression<double> _myShareSum = transactions.myShare.sum();

  Selectable<TypedResult> _personalSpendQuery(DateTime start, DateTime end) {
    return selectOnly(transactions)
      ..addColumns([_myShareSum])
      ..where(_inRange(transactions, start, end));
  }

  int _readSum(TypedResult row) => Money.toMinor(row.read(_myShareSum) ?? 0);

  Selectable<TypedResult> _dailySpendQuery(DateTime start, DateTime end) {
    return selectOnly(transactions)
      ..addColumns([transactions.createdAt, transactions.myShare])
      ..where(_inRange(transactions, start, end));
  }

  List<DailySpend> _bucketByDay(
    List<TypedResult> rows,
    DateTime start,
    DateTime end,
  ) {
    final totals = <DateTime, int>{};
    for (final row in rows) {
      final at = row.read(transactions.createdAt)!.toLocal();
      final day = DateTime(at.year, at.month, at.day);
      totals[day] =
          (totals[day] ?? 0) + Money.toMinor(row.read(transactions.myShare)!);
    }
    final localStart = start.toLocal();
    final localEnd = end.toLocal();
    final days = <DailySpend>[];
    for (
      var day = DateTime(localStart.year, localStart.month, localStart.day);
      day.isBefore(localEnd);
      day = DateTime(day.year, day.month, day.day + 1)
    ) {
      days.add(DailySpend(day: day, personalSpendMinor: totals[day] ?? 0));
    }
    return days;
  }

  Selectable<QueryRow> _friendBalancesQuery() {
    return customSelect(
      '''
      SELECT
        s.friend_id AS friend_id,
        (SELECT s2.friend_name FROM split_entries s2
           JOIN transactions t2 ON t2.id = s2.transaction_id
          WHERE s2.friend_id = s.friend_id
          ORDER BY t2.created_at DESC, s2.id LIMIT 1) AS friend_name,
        (SELECT s3.friend_payment_handle FROM split_entries s3
           JOIN transactions t3 ON t3.id = s3.transaction_id
          WHERE s3.friend_id = s.friend_id AND s3.friend_payment_handle IS NOT NULL
          ORDER BY t3.created_at DESC, s3.id LIMIT 1) AS payment_handle,
        COALESCE(SUM(CASE WHEN s.direction = 'OWES_ME' AND s.is_settled = 0
                          THEN s.amount END), 0.0) AS owed_to_me,
        COALESCE(SUM(CASE WHEN s.direction = 'I_OWE' AND s.is_settled = 0
                          THEN s.amount END), 0.0) AS i_owe,
        SUM(CASE WHEN s.is_settled = 0 THEN 1 ELSE 0 END) AS open_count,
        MIN(CASE WHEN s.is_settled = 0 THEN t.created_at END) AS oldest_open_at,
        MAX(t.created_at) AS last_activity_at
      FROM split_entries s
      JOIN transactions t ON t.id = s.transaction_id
      GROUP BY s.friend_id
      ORDER BY ABS(owed_to_me - i_owe) DESC, friend_name COLLATE NOCASE
      ''',
      readsFrom: {splitEntries, transactions},
    );
  }

  List<FriendBalance> _mapFriendBalances(List<QueryRow> rows) {
    return [
      for (final row in rows)
        FriendBalance(
          friend: FriendRef(
            id: row.read<String>('friend_id'),
            name: row.read<String>('friend_name'),
            paymentHandle: row.readNullable<String>('payment_handle'),
          ),
          owedToMeMinor: Money.toMinor(row.read<double>('owed_to_me')),
          iOweMinor: Money.toMinor(row.read<double>('i_owe')),
          openSplitCount: row.read<int>('open_count'),
          oldestOpenAt: row.readNullable<DateTime>('oldest_open_at'),
          lastActivityAt: row.read<DateTime>('last_activity_at'),
        ),
    ];
  }

  JoinedSelectStatement<HasResultSet, dynamic> _openSplitsQuery(
    String? friendId,
  ) {
    final query =
        select(splitEntries).join([
            innerJoin(
              transactions,
              transactions.id.equalsExp(splitEntries.transactionId),
            ),
          ])
          ..where(splitEntries.isSettled.equals(false))
          ..orderBy([
            OrderingTerm.asc(transactions.createdAt),
            OrderingTerm.asc(splitEntries.id),
          ]);
    if (friendId != null) query.where(splitEntries.friendId.equals(friendId));
    return query;
  }

  List<OpenSplit> _mapOpenSplits(List<TypedResult> rows) {
    return rows.map((row) {
      final split = row.readTable(splitEntries);
      final txn = row.readTable(transactions);
      return OpenSplit(
        splitId: split.id,
        transactionId: txn.id,
        friend: FriendRef(
          id: split.friendId,
          name: split.friendName,
          paymentHandle: split.friendPaymentHandle,
        ),
        amountMinor: Money.toMinor(split.amount),
        direction: split.direction,
        merchant: txn.merchant,
        category: txn.category,
        loggedAt: txn.createdAt,
      );
    }).toList();
  }
}
