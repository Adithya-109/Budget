import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:splitburn/core/database/app_database.dart';
import 'package:splitburn/core/database/connection_setup.dart';
import 'package:sqlite3/sqlite3.dart';

import '../support/test_database.dart';

/// Simulates Swift (AppIntents) and Kotlin (UPI listener) writing to the
/// shared file with the generated schema, then checks Drift agrees.
void main() {
  late Directory dir;
  late File file;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('splitburn_native_');
    file = File('${dir.path}/$kFinanceDatabaseFile');
  });
  tearDown(() => dir.deleteSync(recursive: true));

  List<String> schemaStatements() {
    final sql = File('schema/finance_schema.sql').readAsStringSync();
    return [
      for (final statement in sql.split(RegExp(r';\s*\n')))
        if (statement.trim().startsWith(RegExp('CREATE|INSERT')))
          statement.trim(),
    ];
  }

  /// What a native writer does on first launch, before Flutter ever ran.
  Database openAsNative() {
    final raw = sqlite3.open(file.path);
    configureFinanceConnection(raw);
    for (final statement in schemaStatements()) {
      raw.execute(statement);
    }
    return raw;
  }

  test('Drift opens a file a native writer created first', () async {
    final raw = openAsNative();
    // Running the schema twice must be harmless (every native launch does).
    for (final statement in schemaStatements()) {
      raw.execute(statement);
    }
    raw.close();

    final db = openFileDatabase(file);
    addTearDown(db.close);
    final summary = await db.ledgerDao.financialSummary();
    expect(summary.bankBalanceMinor, 1500000);
    expect(
      await db.customSelect('PRAGMA user_version').getSingle(),
      isA<Object>(),
    );
  });

  test('a native split write follows the contract and reads back in Drift', () async {
    final raw = openAsNative();
    // "Spent 450 on Domino's with Rahul and Priya" from the iOS intent.
    raw.execute('BEGIN IMMEDIATE');
    raw.execute(
      'INSERT INTO transactions (id, merchant, total_paid, my_share, category, '
      'paid_by_me, source, receipt_image_path, created_at) '
      'VALUES (?, ?, ?, ?, ?, 1, ?, NULL, ?)',
      [
        't-1',
        "Domino's",
        450.0,
        150.0,
        'Food',
        'VOICE_INTENT',
        DateTime(2026, 10, 28, 20).millisecondsSinceEpoch ~/ 1000,
      ],
    );
    for (final (id, name) in [('f-r', 'Rahul'), ('f-p', 'Priya')]) {
      raw.execute(
        'INSERT INTO split_entries (id, transaction_id, friend_id, friend_name, '
        'friend_payment_handle, amount, direction, is_settled, settled_at) '
        "VALUES (?, 't-1', ?, ?, NULL, 150.0, 'OWES_ME', 0, NULL)",
        ['s-$id', id, name],
      );
    }
    raw.execute(
      'UPDATE budget_config SET current_bank_balance = '
      'ROUND(current_bank_balance + ?, 2) WHERE id = 1',
      [-450.0],
    );
    raw.execute('COMMIT');
    raw.close();

    final db = openFileDatabase(file);
    addTearDown(db.close);
    final txn = (await db.ledgerDao.transactionById('t-1'))!;
    expect(txn.source, TxnSource.voiceIntent);
    expect(txn.createdAt, DateTime(2026, 10, 28, 20));
    final summary = await db.ledgerDao.financialSummary();
    expect(summary.bankBalanceMinor, 1500000 - 45000);
    expect(summary.owedToMeMinor, 30000);
    expect(summary.totalPersonalSpendMinor, 15000);
    expect((await db.ledgerDao.findFriendByName('rahul'))?.id, 'f-r');
  });
}
