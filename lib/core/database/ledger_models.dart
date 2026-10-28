import '../../domain/expense_draft.dart';
import 'enums.dart';

/// Net position with one friend across all of their splits.
class FriendBalance {
  const FriendBalance({
    required this.friend,
    required this.owedToMeMinor,
    required this.iOweMinor,
    required this.openSplitCount,
    required this.oldestOpenAt,
    required this.lastActivityAt,
  });

  final FriendRef friend;

  /// Unsettled receivables from this friend.
  final int owedToMeMinor;

  /// Unsettled payables to this friend.
  final int iOweMinor;
  final int openSplitCount;

  /// When the oldest unsettled split was logged (drives nudges).
  final DateTime? oldestOpenAt;
  final DateTime lastActivityAt;

  /// Positive: they owe the user. Negative: the user owes them.
  int get netMinor => owedToMeMinor - iOweMinor;

  bool get isSettledUp => openSplitCount == 0;
}

/// An unsettled split with the context a nudge or digest needs.
class OpenSplit {
  const OpenSplit({
    required this.splitId,
    required this.transactionId,
    required this.friend,
    required this.amountMinor,
    required this.direction,
    required this.merchant,
    required this.category,
    required this.loggedAt,
  });

  final String splitId;
  final String transactionId;
  final FriendRef friend;
  final int amountMinor;
  final SplitDirection direction;
  final String merchant;
  final TxnCategory category;
  final DateTime loggedAt;
}

/// Personal (net-share) spending on one local calendar day.
class DailySpend {
  const DailySpend({required this.day, required this.personalSpendMinor});

  /// Local midnight.
  final DateTime day;
  final int personalSpendMinor;

  @override
  bool operator ==(Object other) =>
      other is DailySpend &&
      other.day == day &&
      other.personalSpendMinor == personalSpendMinor;

  @override
  int get hashCode => Object.hash(day, personalSpendMinor);

  @override
  String toString() => 'DailySpend($day: $personalSpendMinor)';
}

/// What settling up with a friend did to the bank balance.
class SettlementResult {
  const SettlementResult({
    required this.settledCount,
    required this.bankDeltaMinor,
  });

  final int settledCount;

  /// Positive when cash came in (they paid the user back).
  final int bankDeltaMinor;
}

/// Outcome of `LedgerDao.reconcileBankBalance`.
class ReconciliationResult {
  const ReconciliationResult({
    required this.previousMinor,
    required this.actualMinor,
    this.untrackedSpendTransactionId,
  });

  /// What the ledger thought the balance was.
  final int previousMinor;

  /// What the bank app shows (the ledger's balance now).
  final int actualMinor;

  /// Set when the shortfall was logged as an "Untracked spending" expense.
  final String? untrackedSpendTransactionId;

  /// Positive: more money than tracked. Negative: unlogged spending.
  int get deltaMinor => actualMinor - previousMinor;
}
