import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:splitburn/core/database/app_database.dart';
import 'package:splitburn/core/database/connection_setup.dart';

/// In-memory ledger with the production connection pragmas.
AppDatabase openTestDatabase() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  return AppDatabase(NativeDatabase.memory(setup: configureFinanceConnection));
}

/// File-backed ledger (needed for WAL, which in-memory databases ignore).
AppDatabase openFileDatabase(File file) {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  return AppDatabase(NativeDatabase(file, setup: configureFinanceConnection));
}
