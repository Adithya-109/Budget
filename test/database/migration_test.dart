import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:splitburn/core/database/connection_setup.dart';
import 'package:sqlite3/sqlite3.dart';

import '../support/test_database.dart';

/// Opens a file created by the shipped v1 schema and checks Drift upgrades it
/// in place without losing data.
void main() {
  test('v1 → v2 adds the owner columns and keeps the ledger', () async {
    final dir = Directory.systemTemp.createTempSync('splitburn_migrate_');
    addTearDown(() => dir.deleteSync(recursive: true));
    final file = File('${dir.path}/$kFinanceDatabaseFile');

    final raw = sqlite3.open(file.path);
    configureFinanceConnection(raw);
    final v1 = File('test/fixtures/finance_schema_v1.sql').readAsStringSync();
    for (final statement in v1.split(RegExp(r';\s*\n'))) {
      if (statement.trim().startsWith(RegExp('CREATE|INSERT'))) {
        raw.execute(statement.trim());
      }
    }
    raw.execute(
      'UPDATE budget_config SET current_bank_balance = 4321.5 WHERE id = 1',
    );
    raw.execute('PRAGMA user_version = 1');
    raw.close();

    final db = openFileDatabase(file);
    addTearDown(db.close);
    final config = await db.budgetDao.config();
    expect(config.currentBankBalance, 4321.5);
    expect(config.ownerName, isNull);

    await db.budgetDao.updateOwner(name: ' Adi ', paymentHandle: 'adi@okaxis');
    final updated = await db.budgetDao.config();
    expect(updated.ownerName, 'Adi');
    expect(updated.ownerPaymentHandle, 'adi@okaxis');
    final version = await db.customSelect('PRAGMA user_version').getSingle();
    expect(version.data.values.single, 2);
  });
}
