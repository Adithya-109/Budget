import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:splitburn/core/database/app_database.dart';
import 'package:splitburn/domain/expense_draft.dart';

import '../support/test_database.dart';

void main() {
  late Directory dir;

  setUp(() => dir = Directory.systemTemp.createTempSync('splitburn_wal_'));
  tearDown(() => dir.deleteSync(recursive: true));

  test('every connection runs WAL, busy_timeout and foreign_keys', () async {
    final db = openFileDatabase(File('${dir.path}/finance.sqlite'));
    addTearDown(db.close);

    Future<Object?> pragma(String name) async =>
        (await db.customSelect('PRAGMA $name').getSingle()).data.values.single;

    expect(await pragma('journal_mode'), 'wal');
    expect(await pragma('busy_timeout'), 5000);
    expect(await pragma('foreign_keys'), 1);
  });

  test(
    'a second connection (like a widget or intent) sees committed writes',
    () async {
      final file = File('${dir.path}/finance.sqlite');
      final app = openFileDatabase(file);
      final other = openFileDatabase(file);
      addTearDown(() async {
        await app.close();
        await other.close();
      });

      await app.ledgerDao.logExpense(
        ExpenseDraft(
          merchant: 'Canteen',
          totalPaidMinor: 6000,
          myShareMinor: 6000,
          payer: const PaidByMe(),
          category: TxnCategory.food,
        ),
      );
      final seen = await other.ledgerDao.financialSummary();
      expect(seen.bankBalanceMinor, 1500000 - 6000);
      expect(seen.totalPersonalSpendMinor, 6000);
    },
  );
}
