import 'package:drift/drift.dart';

import '../money.dart';
import 'converters.dart';
import 'daos/budget_dao.dart';
import 'daos/ledger_dao.dart';
import 'daos/subscriptions_dao.dart';
import 'enums.dart';
import 'tables.dart';

export 'converters.dart' show SplitGroupMember;
export 'enums.dart';

part 'app_database.drift.dart';

@DriftDatabase(
  tables: [BudgetConfig, Transactions, SplitEntries, Subscriptions],
  daos: [LedgerDao, BudgetDao, SubscriptionsDao],
  include: {'financial_summary.drift'},
)
class AppDatabase extends _$AppDatabase {
  /// Use `openFinanceConnection()` in the app and an in-memory or temp-file
  /// `NativeDatabase` (with `configureFinanceConnection`) in tests.
  AppDatabase(super.executor);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      // Not `m.createAll()`: an iOS intent or the Android listener may have
      // created the schema before Flutter's first launch, and Drift's index
      // DDL has no IF NOT EXISTS. Tables and views already use it.
      for (final entity in allSchemaEntities) {
        if (entity is Index) {
          await customStatement(
            entity.createStatementsByDialect[SqlDialect.sqlite]!.replaceFirst(
              RegExp(r'^CREATE INDEX (?!IF NOT EXISTS)'),
              'CREATE INDEX IF NOT EXISTS ',
            ),
          );
        } else {
          await m.create(entity);
        }
      }
      await _ensureBudgetConfigRow();
    },
    beforeOpen: (details) async {
      // The connection setup already enables this; repeating it here keeps
      // cascades working for executors opened without that setup.
      await customStatement('PRAGMA foreign_keys = ON');
      // A native writer may have created the tables before the first Flutter
      // launch, so the singleton row is not guaranteed by onCreate alone.
      await _ensureBudgetConfigRow();
    },
  );

  Future<void> _ensureBudgetConfigRow() => into(budgetConfig).insert(
    const BudgetConfigCompanion(id: Value(1)),
    mode: InsertMode.insertOrIgnore,
  );

  /// Re-runs every Drift stream after another process (an iOS AppIntent, the
  /// Android notification listener) wrote to the shared file. Drift only sees
  /// its own writes, so the root widget calls this on
  /// `AppLifecycleState.resumed` (CLAUDE.md §2 rule 3).
  void syncExternalWrites() {
    markTablesUpdated([
      transactions,
      splitEntries,
      subscriptions,
      budgetConfig,
    ]);
  }
}

/// The True Liquid Balance math on top of `financial_summary_view`.
extension FinancialSummaryMath on FinancialSummaryViewData {
  int get monthlyAllowanceMinor => Money.toMinor(monthlyAllowance ?? 0);
  int get bankBalanceMinor => Money.toMinor(bankBalance ?? 0);
  int get totalPersonalSpendMinor => Money.toMinor(totalPersonalSpend);
  int get owedToMeMinor => Money.toMinor(totalOwedToMe);
  int get iOweMinor => Money.toMinor(totalIOwe);

  /// `Actual Bank Balance − Money I Owe Friends`: what is really mine to spend.
  int get trueSpendableCashMinor => bankBalanceMinor - iOweMinor;

  /// Fronted cash still floating with friends (the green "+ owed" badge).
  int get floatingReceivablesMinor => owedToMeMinor;

  /// Where the user lands once every IOU in both directions is settled.
  int get settledUpBalanceMinor => bankBalanceMinor - iOweMinor + owedToMeMinor;
}
