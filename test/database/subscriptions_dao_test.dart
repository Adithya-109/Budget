import 'package:flutter_test/flutter_test.dart';
import 'package:splitburn/core/database/app_database.dart';
import 'package:splitburn/core/database/daos/subscriptions_dao.dart';
import 'package:splitburn/domain/split_calculator.dart';

import '../support/test_database.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = openTestDatabase());
  tearDown(() => db.close());

  const flatmates = [
    SplitGroupMember(
      friendId: 'f-1',
      friendName: 'Kabir',
      paymentHandle: 'kabir@okhdfc',
    ),
    SplitGroupMember(friendId: 'f-2', friendName: 'Meera'),
  ];

  test('Wi-Fi bill charges once per month and bills flatmates', () async {
    final subs = db.subscriptionsDao;
    await subs.addSubscription(
      name: 'Wi-Fi',
      amountMinor: 90000,
      myShareMinor: 30000,
      billingDate: DateTime(2026, 9, 1, 9),
      splitGroup: flatmates,
    );

    final created = await subs.chargeDue(now: DateTime(2026, 10, 15));
    expect(created, hasLength(2), reason: 'Sep 1 and Oct 1 were both missed');

    final active = await subs.watchActive().first;
    expect(active.single.billingDate, DateTime(2026, 11, 1, 9));

    final s = await db.ledgerDao.financialSummary();
    expect(s.bankBalanceMinor, 1500000 - 2 * 90000);
    expect(s.totalPersonalSpendMinor, 2 * 30000);
    expect(s.owedToMeMinor, 2 * 60000);

    final kabir = await db.ledgerDao.openSplits(friendId: 'f-1');
    expect(kabir.map((e) => e.amountMinor), [30000, 30000]);
    expect(kabir.first.friend.paymentHandle, 'kabir@okhdfc');
    expect(kabir.first.category, TxnCategory.utilities);

    expect(await subs.chargeDue(now: DateTime(2026, 10, 20)), isEmpty);
  });

  test('away flatmate: their share is spread over everyone home', () async {
    final subs = db.subscriptionsDao;
    // ₹1,000 Wi-Fi: me ₹250, Kabir, Meera and Zoya ₹250 each.
    final id = await subs.addSubscription(
      name: 'Wi-Fi',
      amountMinor: 100000,
      myShareMinor: 25000,
      billingDate: DateTime(2026, 11, 1, 9),
      splitGroup: const [
        ...flatmates,
        SplitGroupMember(friendId: 'f-3', friendName: 'Zoya'),
      ],
    );
    await subs.setMemberAway(id, 'f-2', away: true);
    final sub = (await subs.byId(id))!;
    expect(
      sub.autoSplitGroupJson!.singleWhere((m) => m.friendId == 'f-2').away,
      isTrue,
      reason: 'persisted in the JSON',
    );

    // Meera's ₹250 split 3 ways: ₹83.34 for me (rounding), ₹83.33 each.
    final split = SubscriptionsDao.chargeSplitFor(sub);
    expect(split.myShareMinor, 25000 + 8334);
    expect(
      {for (final e in split.friendShares.entries) e.key.name: e.value},
      {'Kabir': 25000 + 8333, 'Zoya': 25000 + 8333},
    );

    await subs.chargeDue(now: DateTime(2026, 11, 1, 10));
    final s = await db.ledgerDao.financialSummary();
    expect(s.totalPersonalSpendMinor, 33334);
    expect(s.owedToMeMinor, 100000 - 33334);
    expect(
      (await db.ledgerDao.openSplits()).map((o) => o.friend.name).toSet(),
      {'Kabir', 'Zoya'},
      reason: 'nobody bills the away flatmate',
    );

    // Back from break: equal shares again.
    await subs.setMemberAway(id, 'f-2', away: false);
    final back = SubscriptionsDao.chargeSplitFor((await subs.byId(id))!);
    expect(back.myShareMinor, 25000);
    expect(back.friendShares.values, everyElement(25000));
  });

  test('everyone away: the user covers the whole bill', () async {
    final subs = db.subscriptionsDao;
    final id = await subs.addSubscription(
      name: 'Cook',
      amountMinor: 30000,
      myShareMinor: 10000,
      billingDate: DateTime(2026, 11, 1, 9),
      splitGroup: flatmates,
    );
    await subs.setMemberAway(id, 'f-1', away: true);
    await subs.setMemberAway(id, 'f-2', away: true);
    final split = SubscriptionsDao.chargeSplitFor((await subs.byId(id))!);
    expect(split.myShareMinor, 30000);
    expect(split.friendShares, isEmpty);
  });

  test('cancelled trial goes to the graveyard and never charges', () async {
    final subs = db.subscriptionsDao;
    final id = await subs.addSubscription(
      name: 'Apple Music Free Trial',
      amountMinor: 11900,
      myShareMinor: 11900,
      billingDate: DateTime(2026, 11, 2),
      isFreeTrial: true,
      cancelUrl: 'https://apps.apple.com/account/subscriptions',
    );
    expect((await subs.watchActiveFreeTrials().first).single.id, id);

    await subs.cancel(id);
    expect(await subs.chargeDue(now: DateTime(2026, 12, 1)), isEmpty);
    expect(
      (await subs.watchGraveyard().first).single.cancelUrl,
      'https://apps.apple.com/account/subscriptions',
    );
  });

  test('a trial still active at its charge date converts to paid', () async {
    final subs = db.subscriptionsDao;
    final id = await subs.addSubscription(
      name: 'Notion Plus trial',
      amountMinor: 80000,
      myShareMinor: 80000,
      billingDate: DateTime(2026, 10, 10),
      isFreeTrial: true,
    );
    await subs.chargeDue(now: DateTime(2026, 10, 10, 12));
    final sub = (await subs.byId(id))!;
    expect(sub.isFreeTrial, isFalse);
    expect(sub.billingDate, DateTime(2026, 11, 10));
  });

  test('fixed and equal shares combine; bad splits are rejected up front', () {
    final shares = SubscriptionsDao.friendSharesFor(
      amountMinor: 100000,
      myShareMinor: 40000,
      group: const [
        SplitGroupMember(friendId: 'a', friendName: 'A', share: 200.0),
        SplitGroupMember(friendId: 'b', friendName: 'B'),
        SplitGroupMember(friendId: 'c', friendName: 'C'),
      ],
    );
    expect(shares.map((f, v) => MapEntry(f.id, v)), {
      'a': 20000,
      'b': 20000,
      'c': 20000,
    });

    expect(
      () => SubscriptionsDao.friendSharesFor(
        amountMinor: 100000,
        myShareMinor: 40000,
        group: const [
          SplitGroupMember(friendId: 'a', friendName: 'A', share: 100.0),
        ],
      ),
      throwsA(isA<SplitMismatchError>()),
    );
  });

  test('billing date rolls forward with month-end clamping', () {
    expect(
      SubscriptionsDao.addOneMonth(DateTime(2026, 1, 31)),
      DateTime(2026, 2, 28),
    );
    expect(
      SubscriptionsDao.addOneMonth(DateTime(2026, 12, 15, 8)),
      DateTime(2027, 1, 15, 8),
    );
  });
}
