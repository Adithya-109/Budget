import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../support/test_database.dart';

/// `schema/finance_schema.sql` is the DDL Swift's SharedSQLiteManager embeds.
/// This test fails whenever the Drift schema changes without the snapshot
/// being refreshed: run `UPDATE_SCHEMA=1 flutter test <this file>`.
void main() {
  test('Drift schema matches schema/finance_schema.sql', () async {
    final db = openTestDatabase();
    addTearDown(db.close);

    final rows = await db
        .customSelect(
          "SELECT type, name, sql FROM sqlite_master "
          "WHERE sql IS NOT NULL AND name NOT LIKE 'sqlite_%' "
          "ORDER BY CASE type WHEN 'table' THEN 0 WHEN 'index' THEN 1 ELSE 2 END, name",
        )
        .get();

    final buffer = StringBuffer()
      ..writeln('-- GENERATED from the Drift schema by')
      ..writeln(
        '-- test/database/schema_snapshot_test.dart. Do not edit by hand.',
      )
      ..writeln(
        '-- Native writers run these with IF NOT EXISTS semantics; Drift',
      )
      ..writeln('-- owns PRAGMA user_version and migrations.')
      ..writeln()
      ..writeln('PRAGMA journal_mode = WAL;')
      ..writeln('PRAGMA busy_timeout = 5000;')
      ..writeln('PRAGMA foreign_keys = ON;');
    for (final row in rows) {
      final sql = _ifNotExists(row.read<String>('sql'));
      buffer
        ..writeln()
        ..writeln('$sql;');
    }
    buffer
      ..writeln()
      ..writeln('INSERT OR IGNORE INTO budget_config (id) VALUES (1);');
    final generated = buffer.toString();

    final snapshot = File('schema/finance_schema.sql');
    if (Platform.environment['UPDATE_SCHEMA'] == '1') {
      snapshot.writeAsStringSync(generated);
    }
    expect(snapshot.existsSync(), isTrue, reason: 'run with UPDATE_SCHEMA=1');
    expect(snapshot.readAsStringSync(), generated);
  });
}

String _ifNotExists(String sql) => sql.replaceFirstMapped(
  RegExp(r'^CREATE (TABLE|INDEX|VIEW|TRIGGER) (?!IF NOT EXISTS)'),
  (m) => 'CREATE ${m[1]} IF NOT EXISTS ',
);
