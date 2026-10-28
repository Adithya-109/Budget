import 'package:sqlite3/common.dart';

/// Drift's database name; the file on disk is [kFinanceDatabaseFile].
const kFinanceDatabaseName = 'finance';

/// Shared with Swift (App Group container) and Kotlin (`filesDir`).
const kFinanceDatabaseFile = 'finance.sqlite';

/// Runs on every raw connection before Drift touches it (CLAUDE.md §2 rule 2).
///
/// Must stay a top-level function: Drift sends it to its background isolate.
/// Swift's `SharedSQLiteManager` and the Kotlin listener issue the same
/// pragmas so a widget refresh, a background shortcut and the UI can all hold
/// the file at once without `SQLITE_BUSY`.
void configureFinanceConnection(CommonDatabase db) {
  db.execute('PRAGMA journal_mode = WAL;');
  db.execute('PRAGMA busy_timeout = 5000;');
  db.execute('PRAGMA foreign_keys = ON;');
  // Safe with WAL (no corruption on power loss) and avoids an fsync per write.
  db.execute('PRAGMA synchronous = NORMAL;');
}
