import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../domain/expense_draft.dart';
import '../../../domain/split_calculator.dart';
import '../../money.dart';
import '../app_database.dart';
import '../tables.dart';

part 'subscriptions_dao.drift.dart';

/// Recurring flatmate bills and the Free Trial Graveyard.
@DriftAccessor(tables: [Subscriptions])
class SubscriptionsDao extends DatabaseAccessor<AppDatabase>
    with _$SubscriptionsDaoMixin {
  SubscriptionsDao(super.attachedDatabase);

  static const _uuid = Uuid();

  /// Adds a recurring bill the user pays and splits with [splitGroup].
  ///
  /// Flatmates with a fixed `share` pay exactly that; the rest split whatever
  /// is left after [myShareMinor] and the fixed shares, equally.
  Future<String> addSubscription({
    required String name,
    required int amountMinor,
    required int myShareMinor,
    required DateTime billingDate,
    bool isFreeTrial = false,
    List<SplitGroupMember> splitGroup = const [],
    String? cancelUrl,
  }) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) throw ArgumentError.value(name, 'name', 'is empty');
    // Validates the split up front so the 1st-of-month run can't fail later.
    friendSharesFor(
      amountMinor: amountMinor,
      myShareMinor: myShareMinor,
      group: splitGroup,
    );
    final id = _uuid.v4();
    await into(subscriptions).insert(
      SubscriptionsCompanion.insert(
        id: id,
        name: trimmed,
        amount: Money.toMajor(amountMinor),
        myShare: Money.toMajor(myShareMinor),
        billingDate: billingDate,
        isFreeTrial: Value(isFreeTrial),
        autoSplitGroupJson: Value(splitGroup.isEmpty ? null : splitGroup),
        cancelUrl: Value(cancelUrl),
      ),
    );
    return id;
  }

  Stream<List<Subscription>> watchActive() {
    return (select(subscriptions)
          ..where((s) => s.isActive.equals(true))
          ..orderBy([(s) => OrderingTerm.asc(s.billingDate)]))
        .watch();
  }

  /// Active free trials, soonest conversion first.
  Stream<List<Subscription>> watchActiveFreeTrials() {
    return (select(subscriptions)
          ..where((s) => s.isActive.equals(true) & s.isFreeTrial.equals(true))
          ..orderBy([(s) => OrderingTerm.asc(s.billingDate)]))
        .watch();
  }

  /// Cancelled bills and buried trials.
  Stream<List<Subscription>> watchGraveyard() {
    return (select(subscriptions)
          ..where((s) => s.isActive.equals(false))
          ..orderBy([(s) => OrderingTerm.desc(s.billingDate)]))
        .watch();
  }

  Future<Subscription?> byId(String id) =>
      (select(subscriptions)..where((s) => s.id.equals(id))).getSingleOrNull();

  /// Cancelled before it could charge: into the graveyard.
  Future<void> cancel(String id) async {
    await (update(subscriptions)..where((s) => s.id.equals(id))).write(
      const SubscriptionsCompanion(isActive: Value(false)),
    );
  }

  Future<void> reactivate(
    String id, {
    required DateTime nextBillingDate,
  }) async {
    await (update(subscriptions)..where((s) => s.id.equals(id))).write(
      SubscriptionsCompanion(
        isActive: const Value(true),
        billingDate: Value(nextBillingDate),
      ),
    );
  }

  /// Logs every active bill whose charge date has passed as a transaction the
  /// user paid (with flatmate receivables), then rolls its billing date
  /// forward a month. Missed months are caught up one charge each. A free
  /// trial that is still active at its charge date has converted to paid, so
  /// it is charged and stops being a trial.
  ///
  /// Returns the ids of the transactions created.
  Future<List<String>> chargeDue({DateTime? now}) {
    final at = now ?? DateTime.now();
    return transaction(() async {
      final due =
          await (select(subscriptions)
                ..where(
                  (s) =>
                      s.isActive.equals(true) &
                      s.billingDate.isSmallerOrEqualValue(at),
                )
                ..orderBy([(s) => OrderingTerm.asc(s.billingDate)]))
              .get();
      final created = <String>[];
      for (final sub in due) {
        var chargeDate = sub.billingDate;
        while (!chargeDate.isAfter(at)) {
          created.add(await _logCharge(sub, chargeDate));
          chargeDate = addOneMonth(chargeDate);
        }
        await (update(subscriptions)..where((s) => s.id.equals(sub.id))).write(
          SubscriptionsCompanion(
            billingDate: Value(chargeDate),
            isFreeTrial: const Value(false),
          ),
        );
      }
      return created;
    });
  }

  Future<String> _logCharge(Subscription sub, DateTime chargeDate) {
    final amountMinor = Money.toMinor(sub.amount);
    final myShareMinor = Money.toMinor(sub.myShare);
    final shares = friendSharesFor(
      amountMinor: amountMinor,
      myShareMinor: myShareMinor,
      group: sub.autoSplitGroupJson ?? const [],
    );
    return attachedDatabase.ledgerDao.logExpense(
      ExpenseDraft(
        merchant: sub.name,
        totalPaidMinor: amountMinor,
        myShareMinor: myShareMinor,
        payer: const PaidByMe(),
        category: TxnCategory.utilities,
        friendShares: shares,
        source: TxnSource.subscription,
        createdAt: chargeDate,
      ),
    );
  }

  /// Each flatmate's share of one charge. Throws if the bill does not add up.
  static Map<FriendRef, int> friendSharesFor({
    required int amountMinor,
    required int myShareMinor,
    required List<SplitGroupMember> group,
  }) {
    if (amountMinor <= 0) {
      throw ArgumentError.value(amountMinor, 'amountMinor', 'must be positive');
    }
    if (myShareMinor < 0 || myShareMinor > amountMinor) {
      throw ArgumentError.value(
        myShareMinor,
        'myShareMinor',
        'must be within the bill',
      );
    }
    final shares = <FriendRef, int>{};
    final flexible = <FriendRef>[];
    var fixedTotal = 0;
    for (final member in group) {
      final friend = FriendRef(
        id: member.friendId,
        name: member.friendName,
        paymentHandle: member.paymentHandle,
      );
      if (member.share case final share?) {
        final minor = Money.toMinor(share);
        if (minor < 0) {
          throw ArgumentError.value(share, member.friendName, 'negative share');
        }
        shares[friend] = minor;
        fixedTotal += minor;
      } else {
        flexible.add(friend);
      }
    }
    final remainder = amountMinor - myShareMinor - fixedTotal;
    if (remainder < 0 || (remainder > 0 && flexible.isEmpty)) {
      throw SplitMismatchError(
        expectedMinor: amountMinor,
        actualMinor: myShareMinor + fixedTotal,
      );
    }
    if (flexible.isNotEmpty) {
      shares.addAll(SplitCalculator.equal(remainder, flexible));
    }
    return shares;
  }

  /// Same day next month, clamped to that month's length (Jan 31 → Feb 28).
  static DateTime addOneMonth(DateTime date) {
    final local = date.toLocal();
    final firstOfNext = DateTime(local.year, local.month + 1);
    final lastDay = DateTime(firstOfNext.year, firstOfNext.month + 1, 0).day;
    return DateTime(
      firstOfNext.year,
      firstOfNext.month,
      local.day > lastDay ? lastDay : local.day,
      local.hour,
      local.minute,
      local.second,
    );
  }
}
