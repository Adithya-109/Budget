// dart format width=80
// ignore_for_file: type=lint
part of 'budget_dao.dart';

mixin _$BudgetDaoMixin on DatabaseAccessor<AppDatabase> {
  $BudgetConfigTable get budgetConfig => attachedDatabase.budgetConfig;
  BudgetDaoManager get managers => BudgetDaoManager(this);
}

class BudgetDaoManager {
  final _$BudgetDaoMixin _db;
  BudgetDaoManager(this._db);
  $$BudgetConfigTableTableManager get budgetConfig =>
      $$BudgetConfigTableTableManager(_db.attachedDatabase, _db.budgetConfig);
}
