import 'package:flutter_test/flutter_test.dart';
import 'package:splitburn/core/database/enums.dart';
import 'package:splitburn/core/database/ledger_models.dart';
import 'package:splitburn/domain/debt_simplifier.dart';
import 'package:splitburn/domain/expense_draft.dart';
import 'package:splitburn/features/bills/trial_shield.dart';
import 'package:splitburn/features/ledger/group_settle.dart';
import 'package:splitburn/features/ledger/nudge_composer.dart';
import 'package:splitburn/features/ledger/settle_links.dart';
import 'package:splitburn/features/ledger/shared_ledger.dart';
import 'package:splitburn/features/split/receipt_parser.dart';
import 'package:splitburn/features/split/split_builder.dart';

const rahul = FriendRef(id: 'r', name: 'Rahul', paymentHandle: 'rahul@okaxis');
const priya = FriendRef(id: 'p', name: 'Priya');
const r = FriendParticipant(rahul);
const p = FriendParticipant(priya);

OpenSplit owes(String merchant, int minor, DateTime at) => OpenSplit(
  splitId: 's-$merchant',
  transactionId: 't-$merchant',
  friend: rahul,
  amountMinor: minor,
  direction: SplitDirection.owesMe,
  merchant: merchant,
  category: TxnCategory.food,
  loggedAt: at,
);

void main() {
  group('SettleLinks', () {
    test('UPI link matches the spec format exactly', () {
      final uri = SettleLinks.upi(
        payeeVpa: 'adi@okaxis',
        payeeName: 'Adithya B',
        amountMinor: 15000,
      );
      expect(
        uri.toString(),
        'upi://pay?pa=adi@okaxis&pn=Adithya%20B&am=150.00&cu=INR'
        '&tn=SplitBurn%20Settlement',
      );
      expect(uri.queryParameters['am'], '150.00');
    });

    test('Venmo link matches the spec format and strips the @', () {
      expect(
        SettleLinks.venmo(handle: '@alex-doe', amountMinor: 4050).toString(),
        'venmo://paycharge?txn=pay&recipients=alex-doe&amount=40.50&note=SplitBurn',
      );
    });

    test('detects the payment rail from a handle', () {
      expect(SettleLinks.railOf('name@okaxis'), PaymentRail.upi);
      expect(SettleLinks.railOf('9876543210@ybl'), PaymentRail.upi);
      expect(SettleLinks.railOf('@alex-doe'), PaymentRail.venmo);
      expect(SettleLinks.railOf('not a handle!'), isNull);
      expect(
        SettleLinks.forHandle(handle: null, payeeName: 'x', amountMinor: 1),
        isNull,
      );
      expect(
        () => SettleLinks.upi(payeeVpa: 'a@b', payeeName: 'x', amountMinor: 0),
        throwsArgumentError,
      );
    });
  });

  group('SharedLedger', () {
    final ledger = SharedLedger(
      title: "Rahul's tab",
      payeeName: 'Adithya',
      payeeHandle: 'adi@okaxis',
      currencySymbol: '₹',
      lines: [
        SharedLedgerLine(
          label: "Domino's",
          amountMinor: 15000,
          date: DateTime(2026, 10, 3),
        ),
        SharedLedgerLine(
          label: 'Chai ☕',
          amountMinor: 4000,
          date: DateTime(2026, 10, 28),
        ),
      ],
    );

    test('round-trips through a URL fragment', () {
      final uri = ledger.toUri(baseUrl: 'https://example.github.io/Budget/');
      expect(
        uri.toString(),
        startsWith('https://example.github.io/Budget/#/l/'),
      );
      final payload = SharedLedger.payloadFromFragment(uri.fragment)!;
      final decoded = SharedLedger.decode(payload);
      expect(decoded.title, "Rahul's tab");
      expect(decoded.payeeHandle, 'adi@okaxis');
      expect(decoded.lines, ledger.lines);
      expect(decoded.totalMinor, 19000);
    });

    test('FNV-1a matches the reference vectors (and is web-safe)', () {
      expect(fnv1a32(''.codeUnits), 0x811c9dc5);
      expect(fnv1a32('a'.codeUnits), 0xe40c292c);
      expect(fnv1a32('foobar'.codeUnits), 0xbf9cf968);
    });

    test('rejects truncated or tampered links', () {
      final payload = ledger.encode();
      expect(
        () => SharedLedger.decode(payload.substring(0, payload.length - 6)),
        throwsA(isA<SharedLedgerFormatException>()),
      );
      expect(
        () => SharedLedger.decode('not-a-ledger'),
        throwsA(isA<SharedLedgerFormatException>()),
      );
      expect(SharedLedger.payloadFromFragment('/somewhere'), isNull);
    });
  });

  group('ReceiptParser', () {
    test('reads items, GST, service charge and the printed total', () {
      final receipt = ReceiptParser.parse([
        'THE BOMBAY CANTEEN',
        'GSTIN 29ABCDE1234F1Z5',
        'Date: 28/10/2026  Time 21:14',
        'Item Qty Amount',
        'Paneer Tikka 2 x 150.00 300.00',
        'Butter Naan 4 x 50 200.00',
        'Mango Lassi',
        '120.00',
        'Sub Total 620.00',
        'CGST 2.5% 15.50',
        'SGST 2.5% 15.50',
        'Service Charge 31.00',
        'Discount -20.00',
        'Round Off -0.00',
        'Grand Total ₹662.00',
        'Thank you! Visit again',
      ]);
      expect(receipt.merchant, 'THE BOMBAY CANTEEN');
      expect(receipt.items, const [
        ReceiptItem(label: 'Paneer Tikka', priceMinor: 30000),
        ReceiptItem(label: 'Butter Naan', priceMinor: 20000),
        ReceiptItem(label: 'Mango Lassi', priceMinor: 12000),
      ]);
      expect(receipt.subtotalMinor, 62000);
      expect(receipt.taxMinor, 3100);
      expect(receipt.tipMinor, 3100);
      expect(receipt.discountMinor, 2000);
      expect(receipt.totalMinor, 66200);
      expect(receipt.extrasMinor, 4200);
      expect(receipt.billTotalMinor, 66200);
    });

    test('without a readable total, extras come from the labelled lines', () {
      final receipt = ReceiptParser.parse([
        'Cafe Mocha 180',
        'Croissant 140',
        'GST 16',
        'Tip 30',
      ]);
      expect(receipt.itemsMinor, 32000);
      expect(receipt.extrasMinor, 4600);
    });
  });

  group('SplitForm', () {
    const base = SplitForm(
      merchant: 'Pizza',
      totalMinor: 90000,
      participants: [Me(), r, p],
    );

    test('equal split, I paid', () {
      final outcome = base.build() as SplitReady;
      expect(outcome.draft.myShareMinor, 30000);
      expect(outcome.draft.friendShares, {rahul: 30000, priya: 30000});
      expect(outcome.draft.paidByMe, isTrue);
    });

    test('exact split reports what is left to assign', () {
      final partial = base.copyWith(
        mode: SplitMode.exact,
        exactMinor: {const Me(): 20000, r: 40000},
      );
      final invalid = partial.build() as SplitInvalid;
      expect(invalid.remainingMinor, 30000);
      final done = partial.copyWith(
        exactMinor: {const Me(): 20000, r: 40000, p: 30000},
      );
      expect((done.build() as SplitReady).draft.myShareMinor, 20000);
    });

    test('percentage split, Rahul paid', () {
      final form = base.copyWith(
        mode: SplitMode.percentage,
        payer: r,
        basisPoints: {const Me(): 5000, r: 2500, p: 2500},
      );
      final ready = form.build() as SplitReady;
      expect(ready.draft.payer, isA<PaidByFriend>());
      expect(ready.draft.myShareMinor, 45000);
    });

    test('receipt mode: tapped items plus proportional extras', () {
      final form = base.copyWith(
        mode: SplitMode.receipt,
        claimedItems: [
          ClaimedItem(
            item: const ReceiptItem(label: 'Pizza', priceMinor: 60000),
            claimedBy: {const Me(), r},
          ),
          ClaimedItem(
            item: const ReceiptItem(label: 'Coke', priceMinor: 6000),
            claimedBy: {p},
          ),
        ],
        receiptExtrasMinor: 6600,
      );
      expect(form.effectiveTotalMinor, 72600);
      final ready = form.build() as SplitReady;
      expect(ready.allocation, {const Me(): 33000, r: 33000, p: 6600});
      expect(ready.draft.source, TxnSource.ocr);

      final unclaimed = form.copyWith(
        claimedItems: [
          const ClaimedItem(
            item: ReceiptItem(label: 'Fries', priceMinor: 100),
            claimedBy: {},
          ),
        ],
      );
      expect((unclaimed.build() as SplitInvalid).message, contains('Fries'));
    });

    test('removing the paying friend falls back to me', () {
      final form = base
          .copyWith(payer: r)
          .copyWith(participants: [const Me(), p]);
      expect(form.payer, const Me());
    });
  });

  group('NudgeComposer', () {
    final splits = [
      owes('Auto', 4000, DateTime(2026, 10, 2)),
      owes('Coffee', 12000, DateTime(2026, 10, 9)),
      owes('Pizza', 30000, DateTime(2026, 10, 30)),
    ];

    test('polite tone mentions the total and items', () {
      final nudge = NudgeComposer.compose(
        tone: NudgeTone.polite,
        friendName: 'Rahul Sharma',
        openSplits: splits,
        currencySymbol: '₹',
        ownerName: 'Adi',
        settleLink: Uri.parse('https://x.io/#/l/abc'),
      );
      expect(nudge.text, startsWith('Hey Rahul!'));
      expect(nudge.text, contains('₹460'));
      expect(nudge.text, contains('https://x.io/#/l/abc'));
      expect(nudge.totalMinor, 46000);
    });

    test('monthly digest bundles every micro-debt', () {
      final nudge = NudgeComposer.compose(
        tone: NudgeTone.digest,
        friendName: 'Rahul',
        openSplits: splits,
        currencySymbol: '₹',
      );
      expect(nudge.headline, 'October tab');
      expect(nudge.text, contains('• Auto — ₹40'));
      expect(nudge.text, contains('Total: ₹460'));
      expect(NudgeComposer.isDigestWindow(DateTime(2026, 11, 1)), isTrue);
      expect(NudgeComposer.isDigestWindow(DateTime(2026, 11, 4)), isFalse);
    });

    test('meme tone is dramatic, never rude', () {
      final nudge = NudgeComposer.compose(
        tone: NudgeTone.meme,
        friendName: 'Rahul',
        openSplits: splits,
        currencySymbol: '₹',
      );
      expect(nudge.headline, 'SURVIVAL FUND NOTICE');
      expect(nudge.text, contains('Maggi'));
    });
  });

  group('TrialShield', () {
    test('reminds 48h and 12h before the charge, skipping past times', () {
      final billing = DateTime(2026, 11, 3, 10);
      final reminders = TrialShield.remindersFor(
        subscriptionId: 'sub-1',
        billingDate: billing,
        now: DateTime(2026, 10, 28),
      );
      expect(reminders.map((r) => r.fireAt), [
        DateTime(2026, 11, 1, 10),
        DateTime(2026, 11, 2, 22),
      ]);
      final late = TrialShield.remindersFor(
        subscriptionId: 'sub-1',
        billingDate: billing,
        now: DateTime(2026, 11, 2),
      );
      expect(late.single.hoursBefore, 12);
      expect(late.single.notificationId, reminders.last.notificationId);
    });

    test('ids are stable, distinct per subscription and in range', () {
      final a = TrialShield.notificationIds('sub-1');
      expect(TrialShield.notificationIds('sub-1'), a);
      expect(TrialShield.notificationIds('sub-2'), isNot(a));
      expect(a.every((id) => id >= 0 && id < 0x7fffffff), isTrue);
    });

    test('countdown text', () {
      final now = DateTime(2026, 10, 28, 9);
      expect(TrialShield.countdown(DateTime(2026, 10, 30, 13), now), '2d 4h');
      expect(
        TrialShield.countdown(DateTime(2026, 10, 28, 14, 12), now),
        '5h 12m',
      );
      expect(TrialShield.countdown(DateTime(2026, 10, 28, 9, 18), now), '18m');
      expect(TrialShield.countdown(now, now), 'now');
    });
  });

  group('GroupSettlement', () {
    test('Goa trip: three payers settle in two transfers', () {
      final s = GroupSettlement.compute(const [
        GroupBill(
          label: 'Stay',
          payer: 'Me',
          amountMinor: 900000,
          sharedBy: ['Me', 'Rahul', 'Priya'],
        ),
        GroupBill(
          label: 'Scooters',
          payer: 'Rahul',
          amountMinor: 300000,
          sharedBy: ['Me', 'Rahul', 'Priya'],
        ),
        GroupBill(
          label: 'Seafood',
          payer: 'Priya',
          amountMinor: 120000,
          sharedBy: ['Rahul', 'Priya'],
        ),
      ]);
      expect(s.paidBy('Me'), 900000);
      expect(s.shareOf('Me'), 400000);
      expect(s.rawDebtCount, 5);
      expect(s.transfers, hasLength(2));
      final mine = s.transfersFor('Me');
      final incoming = mine
          .where((t) => t.to == 'Me')
          .fold(0, (a, t) => a + t.amountMinor);
      expect(incoming, 900000 - 400000);
      expect(s.transfers.toSet(), {
        const Debt(from: 'Rahul', to: 'Me', amountMinor: 160000),
        const Debt(from: 'Priya', to: 'Me', amountMinor: 340000),
      });
    });
  });
}
