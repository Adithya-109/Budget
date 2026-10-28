// dart format width=80
// ignore_for_file: type=lint
part of 'ledger_dao.dart';

mixin _$LedgerDaoMixin on DatabaseAccessor<AppDatabase> {
  $TransactionsTable get transactions => attachedDatabase.transactions;
  $SplitEntriesTable get splitEntries => attachedDatabase.splitEntries;
  $BudgetConfigTable get budgetConfig => attachedDatabase.budgetConfig;
  LedgerDaoManager get managers => LedgerDaoManager(this);
}

class LedgerDaoManager {
  final _$LedgerDaoMixin _db;
  LedgerDaoManager(this._db);
  $$TransactionsTableTableManager get transactions =>
      $$TransactionsTableTableManager(_db.attachedDatabase, _db.transactions);
  $$SplitEntriesTableTableManager get splitEntries =>
      $$SplitEntriesTableTableManager(_db.attachedDatabase, _db.splitEntries);
  $$BudgetConfigTableTableManager get budgetConfig =>
      $$BudgetConfigTableTableManager(_db.attachedDatabase, _db.budgetConfig);
}
