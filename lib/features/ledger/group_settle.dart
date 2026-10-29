import '../../domain/debt_simplifier.dart';
import '../../domain/split_calculator.dart';

/// One bill in a group outing: [payer] paid [amountMinor], split equally
/// between [sharedBy].
class GroupBill {
  const GroupBill({
    required this.label,
    required this.payer,
    required this.amountMinor,
    required this.sharedBy,
  });

  final String label;
  final String payer;
  final int amountMinor;
  final List<String> sharedBy;
}

/// Trip / flat settle-up: who paid what, who ate what, and the fewest
/// transfers that square everyone (graph-simplified min cash flow).
class GroupSettlement {
  GroupSettlement._(
    this.paidMinor,
    this.shareMinor,
    this.transfers,
    this.rawDebtCount,
  );

  /// People are keyed by name (the user is whatever key the caller picks).
  factory GroupSettlement.compute(List<GroupBill> bills) {
    final paid = <String, int>{};
    final share = <String, int>{};
    final expenses = <GroupExpense<String>>[];
    for (final bill in bills) {
      if (bill.amountMinor <= 0 || bill.sharedBy.isEmpty) continue;
      // Payer first so the payer absorbs rounding.
      final people = [
        if (bill.sharedBy.contains(bill.payer)) bill.payer,
        for (final p in bill.sharedBy)
          if (p != bill.payer) p,
      ];
      final shares = SplitCalculator.equal(bill.amountMinor, people);
      paid[bill.payer] = (paid[bill.payer] ?? 0) + bill.amountMinor;
      shares.forEach((p, v) => share[p] = (share[p] ?? 0) + v);
      expenses.add(GroupExpense(payer: bill.payer, sharesMinor: shares));
    }
    final debts = DebtSimplifier.debtsFromExpenses(expenses);
    return GroupSettlement._(
      paid,
      share,
      DebtSimplifier.simplify(debts),
      debts.length,
    );
  }

  final Map<String, int> paidMinor;
  final Map<String, int> shareMinor;
  final List<Debt<String>> transfers;

  int paidBy(String person) => paidMinor[person] ?? 0;
  int shareOf(String person) => shareMinor[person] ?? 0;

  /// Transfers that involve [person] (the only ones that go on their ledger).
  List<Debt<String>> transfersFor(String person) => [
    for (final t in transfers)
      if (t.from == person || t.to == person) t,
  ];

  /// "Who owes whom" edges before simplification (to show what was saved).
  final int rawDebtCount;
}
