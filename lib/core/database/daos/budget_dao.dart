import 'package:drift/drift.dart';

import '../../../domain/budget_cycle.dart';
import '../../money.dart';
import '../app_database.dart';
import '../tables.dart';

part 'budget_dao.drift.dart';

/// The singleton `budget_config` row (id = 1).
@DriftAccessor(tables: [BudgetConfig])
class BudgetDao extends DatabaseAccessor<AppDatabase> with _$BudgetDaoMixin {
  BudgetDao(super.attachedDatabase);

  SimpleSelectStatement<$BudgetConfigTable, BudgetConfigRow> get _row =>
      select(budgetConfig)..where((c) => c.id.equals(1));

  Stream<BudgetConfigRow> watchConfig() => _row.watchSingle();

  Future<BudgetConfigRow> config() => _row.getSingle();

  Future<BudgetCycle> currentCycle({DateTime? now}) async {
    final row = await config();
    return BudgetCycle.containing(
      now ?? DateTime.now(),
      resetDay: row.cycleResetDay,
    );
  }

  Future<void> updateSettings({
    int? monthlyAllowanceMinor,
    int? cycleResetDay,
    String? currencySymbol,
  }) async {
    if (monthlyAllowanceMinor != null && monthlyAllowanceMinor < 0) {
      throw ArgumentError.value(
        monthlyAllowanceMinor,
        'monthlyAllowanceMinor',
        'is negative',
      );
    }
    if (cycleResetDay != null && (cycleResetDay < 1 || cycleResetDay > 31)) {
      throw RangeError.range(cycleResetDay, 1, 31, 'cycleResetDay');
    }
    if (currencySymbol != null && currencySymbol.trim().isEmpty) {
      throw ArgumentError.value(currencySymbol, 'currencySymbol', 'is empty');
    }
    await (update(budgetConfig)..where((c) => c.id.equals(1))).write(
      BudgetConfigCompanion(
        monthlyAllowance: monthlyAllowanceMinor == null
            ? const Value.absent()
            : Value(Money.toMajor(monthlyAllowanceMinor)),
        cycleResetDay: Value.absentIfNull(cycleResetDay),
        currencySymbol: Value.absentIfNull(currencySymbol?.trim()),
      ),
    );
  }

  /// The user's name and UPI ID / Venmo handle for shared ledger links.
  /// Blank values clear them.
  Future<void> updateOwner({String? name, String? paymentHandle}) async {
    String? clean(String? v) =>
        (v == null || v.trim().isEmpty) ? null : v.trim();
    await (update(budgetConfig)..where((c) => c.id.equals(1))).write(
      BudgetConfigCompanion(
        ownerName: Value(clean(name)),
        ownerPaymentHandle: Value(clean(paymentHandle)),
      ),
    );
  }

  /// Overwrites the balance after the user checks their real bank app.
  Future<void> setBankBalance(int balanceMinor) async {
    await (update(budgetConfig)..where((c) => c.id.equals(1))).write(
      BudgetConfigCompanion(
        currentBankBalance: Value(Money.toMajor(balanceMinor)),
      ),
    );
  }

  /// Money arriving that is not a friend's repayment: the allowance, a
  /// stipend, pocket money from home. Relative so it can't clobber a
  /// concurrent native write.
  Future<void> recordIncome(int amountMinor) async {
    if (amountMinor <= 0) {
      throw ArgumentError.value(amountMinor, 'amountMinor', 'must be positive');
    }
    await customUpdate(
      'UPDATE budget_config '
      'SET current_bank_balance = ROUND(current_bank_balance + ?, 2) '
      'WHERE id = 1',
      variables: [Variable.withReal(Money.toMajor(amountMinor))],
      updates: {budgetConfig},
      updateKind: UpdateKind.update,
    );
  }
}
