import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../database/app_database.dart';
import '../database/connection.dart';
import '../database/daos/budget_dao.dart';
import '../database/daos/ledger_dao.dart';
import '../database/daos/subscriptions_dao.dart';
import '../database/ledger_models.dart';

part 'database_providers.g.dart';

/// The one connection to `finance.sqlite`. Override in tests with an
/// in-memory `AppDatabase`.
@Riverpod(keepAlive: true)
AppDatabase appDatabase(Ref ref) {
  final db = AppDatabase(openFinanceConnection());
  ref.onDispose(db.close);
  return db;
}

@Riverpod(keepAlive: true)
LedgerDao ledgerDao(Ref ref) => ref.watch(appDatabaseProvider).ledgerDao;

@Riverpod(keepAlive: true)
BudgetDao budgetDao(Ref ref) => ref.watch(appDatabaseProvider).budgetDao;

@Riverpod(keepAlive: true)
SubscriptionsDao subscriptionsDao(Ref ref) =>
    ref.watch(appDatabaseProvider).subscriptionsDao;

@riverpod
Stream<FinancialSummaryViewData> financialSummary(Ref ref) =>
    ref.watch(ledgerDaoProvider).watchFinancialSummary();

@riverpod
Stream<BudgetConfigRow> budgetSettings(Ref ref) =>
    ref.watch(budgetDaoProvider).watchConfig();

@riverpod
Stream<List<FriendBalance>> friendBalances(Ref ref) =>
    ref.watch(ledgerDaoProvider).watchFriendBalances();
