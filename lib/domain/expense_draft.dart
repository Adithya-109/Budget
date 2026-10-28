import '../core/database/enums.dart';
import 'split_calculator.dart';

/// A friend as the ledger knows them. Friends are denormalized onto each
/// split row (CLAUDE.md §3), so this is just the identity carried along.
class FriendRef {
  const FriendRef({required this.id, required this.name, this.paymentHandle});

  final String id;
  final String name;

  /// UPI ID or Venmo / Cash App handle, if known.
  final String? paymentHandle;

  @override
  bool operator ==(Object other) => other is FriendRef && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'FriendRef($id, $name)';
}

/// A participant key for [SplitCalculator]: the user or one friend.
sealed class Participant {
  const Participant();
}

final class Me extends Participant {
  const Me();

  @override
  bool operator ==(Object other) => other is Me;

  @override
  int get hashCode => 0;

  @override
  String toString() => 'Me';
}

final class FriendParticipant extends Participant {
  const FriendParticipant(this.friend);

  final FriendRef friend;

  @override
  bool operator ==(Object other) =>
      other is FriendParticipant && other.friend == friend;

  @override
  int get hashCode => friend.hashCode;

  @override
  String toString() => 'FriendParticipant(${friend.name})';
}

/// Who fronted the cash.
sealed class Payer {
  const Payer();
}

final class PaidByMe extends Payer {
  const PaidByMe();
}

final class PaidByFriend extends Payer {
  const PaidByFriend(this.friend);

  final FriendRef friend;
}

/// A fully allocated expense, ready for `LedgerDao.logExpense`.
///
/// The net-share rule: only [myShareMinor] is personal spending. When the user
/// paid, every friend's share becomes a receivable; when a friend paid, the
/// user's share becomes a payable to that friend. Shares between other
/// friends are not the user's debt and are not recorded.
class ExpenseDraft {
  ExpenseDraft({
    required this.merchant,
    required this.totalPaidMinor,
    required this.myShareMinor,
    required this.payer,
    required this.category,
    this.friendShares = const {},
    this.source = TxnSource.app,
    this.createdAt,
    this.receiptImagePath,
  }) {
    if (merchant.trim().isEmpty) {
      throw ArgumentError.value(merchant, 'merchant', 'is empty');
    }
    if (totalPaidMinor <= 0) {
      throw ArgumentError.value(
        totalPaidMinor,
        'totalPaidMinor',
        'must be positive',
      );
    }
    if (myShareMinor < 0 || friendShares.values.any((s) => s < 0)) {
      throw ArgumentError('Shares cannot be negative');
    }
    final allocated =
        myShareMinor + friendShares.values.fold<int>(0, (a, b) => a + b);
    if (allocated != totalPaidMinor) {
      throw SplitMismatchError(
        expectedMinor: totalPaidMinor,
        actualMinor: allocated,
      );
    }
    if (payer case PaidByFriend(:final friend)) {
      if (!friendShares.containsKey(friend)) {
        throw ArgumentError.value(
          friend,
          'payer',
          'must be one of the friends on the bill',
        );
      }
      if (myShareMinor == 0) {
        throw ArgumentError(
          'A bill a friend paid with no share for you is not on your ledger',
        );
      }
    }
  }

  /// Builds a draft from any [SplitCalculator] result keyed by [Participant].
  factory ExpenseDraft.fromAllocation({
    required String merchant,
    required Map<Participant, int> allocation,
    required Payer payer,
    required TxnCategory category,
    TxnSource source = TxnSource.app,
    DateTime? createdAt,
    String? receiptImagePath,
  }) {
    var mine = 0;
    final friends = <FriendRef, int>{};
    allocation.forEach((participant, share) {
      switch (participant) {
        case Me():
          mine += share;
        case FriendParticipant(:final friend):
          friends[friend] = (friends[friend] ?? 0) + share;
      }
    });
    return ExpenseDraft(
      merchant: merchant,
      totalPaidMinor: mine + friends.values.fold<int>(0, (a, b) => a + b),
      myShareMinor: mine,
      payer: payer,
      category: category,
      friendShares: friends,
      source: source,
      createdAt: createdAt,
      receiptImagePath: receiptImagePath,
    );
  }

  /// Equal split between the user and [friends], user first so they absorb
  /// rounding when they paid. "450 with Rahul and Priya" → 150 each.
  factory ExpenseDraft.equalSplit({
    required String merchant,
    required int totalMinor,
    required List<FriendRef> friends,
    required TxnCategory category,
    Payer payer = const PaidByMe(),
    TxnSource source = TxnSource.app,
    DateTime? createdAt,
    String? receiptImagePath,
  }) {
    final payingFriend = switch (payer) {
      PaidByFriend(:final friend) => friend,
      PaidByMe() => null,
    };
    final participants = <Participant>[
      if (payingFriend != null) FriendParticipant(payingFriend),
      const Me(),
      for (final f in friends)
        if (f != payingFriend) FriendParticipant(f),
    ];
    return ExpenseDraft.fromAllocation(
      merchant: merchant,
      allocation: SplitCalculator.equal(totalMinor, participants),
      payer: payer,
      category: category,
      source: source,
      createdAt: createdAt,
      receiptImagePath: receiptImagePath,
    );
  }

  final String merchant;
  final int totalPaidMinor;
  final int myShareMinor;
  final Payer payer;
  final TxnCategory category;

  /// Every friend's share of the bill (including a paying friend's own share).
  final Map<FriendRef, int> friendShares;
  final TxnSource source;
  final DateTime? createdAt;
  final String? receiptImagePath;

  bool get paidByMe => payer is PaidByMe;

  /// Cash the user fronted for others (the "floating receivables" bucket).
  int get frontedForOthersMinor => paidByMe ? totalPaidMinor - myShareMinor : 0;
}
