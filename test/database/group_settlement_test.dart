import 'package:flutter_test/flutter_test.dart';
import 'package:splitburn/core/database/app_database.dart';
import 'package:splitburn/domain/expense_draft.dart';

import '../support/test_database.dart';

const rahul = FriendRef(id: 'r', name: 'Rahul');
const priya = FriendRef(id: 'p', name: 'Priya');

void main() {
  late AppDatabase db;
  setUp(() => db = openTestDatabase());
  tearDown(() => db.close());

  test(
    'trip where I paid ₹9,000 of a ₹4,000 share: friends owe me ₹5,000',
    () async {
      final id = await db.ledgerDao.logGroupSettlement(
        label: 'Goa trip',
        paidMinor: 900000,
        shareMinor: 400000,
        category: TxnCategory.fun,
        owedToMe: {rahul: 160000, priya: 340000},
      );
      var s = await db.ledgerDao.financialSummary();
      expect(s.bankBalanceMinor, 1500000 - 900000);
      expect(s.totalPersonalSpendMinor, 400000);
      expect(s.owedToMeMinor, 500000);

      await db.ledgerDao.deleteTransaction(id);
      s = await db.ledgerDao.financialSummary();
      expect(s.bankBalanceMinor, 1500000);
      expect(s.owedToMeMinor, 0);
    },
  );

  test('paid nothing: only payables, bank untouched', () async {
    await db.ledgerDao.logGroupSettlement(
      label: 'Flat party',
      paidMinor: 0,
      shareMinor: 120000,
      category: TxnCategory.fun,
      iOwe: {rahul: 70000, priya: 50000},
    );
    final s = await db.ledgerDao.financialSummary();
    expect(s.bankBalanceMinor, 1500000);
    expect(s.iOweMinor, 120000);
    expect(s.trueSpendableCashMinor, 1500000 - 120000);
  });

  test('rejects transfers that do not net to paid − share', () {
    expect(
      () => db.ledgerDao.logGroupSettlement(
        label: 'Oops',
        paidMinor: 1000,
        shareMinor: 500,
        category: TxnCategory.fun,
        owedToMe: {rahul: 100},
      ),
      throwsArgumentError,
    );
  });
}
