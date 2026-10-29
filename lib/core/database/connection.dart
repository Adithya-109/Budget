import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'connection_setup.dart';

/// Implemented by `AppDelegate.swift`; returns the App Group container path.
const storageChannel = MethodChannel('com.splitburn.app/storage');

class AppGroupUnavailableException implements Exception {
  const AppGroupUnavailableException();

  @override
  String toString() =>
      'AppGroupUnavailableException: the App Group container '
      'group.com.splitburn.app is not available. Enable the App Groups '
      'capability on the Runner and BalanceWidgetExtension targets.';
}

/// Free-Apple-ID builds: `flutter run --dart-define=SPLITBURN_SANDBOX_LEDGER=true`.
///
/// Personal (free) signing teams may not get the App Groups capability, so
/// this build keeps the ledger in the app's own sandbox. The app works; the
/// widget and App Intents can't see the data. Release builds never set it.
const kSandboxLedger = bool.fromEnvironment('SPLITBURN_SANDBOX_LEDGER');

Future<String> _supportDir() async =>
    (await getApplicationSupportDirectory()).path;

/// Where `finance.sqlite` lives on this device.
///
/// * iOS: the shared App Group container, so `AppIntents` and `WidgetKit`
///   read the same file. Without the group it fails loudly (a silent
///   fallback would split the ledger in two) unless [allowSandbox] is set
///   ([kSandboxLedger] builds). A ledger left in the sandbox by such a build
///   moves into the group the first time the group is available.
/// * Android: `context.filesDir` (what `getApplicationSupportDirectory`
///   returns), the same path the Kotlin `NotificationListenerService` opens.
Future<String> resolveFinanceDatabasePath({
  bool allowSandbox = kSandboxLedger,
  Future<String> Function() sandboxDir = _supportDir,
}) async {
  if (kIsWeb) {
    throw UnsupportedError(
      'The web build is the zero-install ledger viewer and has no local ledger',
    );
  }
  if (defaultTargetPlatform == TargetPlatform.iOS) {
    final groupPath = await storageChannel.invokeMethod<String>(
      'getAppGroupPath',
    );
    if (groupPath == null || groupPath.isEmpty) {
      if (!allowSandbox) throw const AppGroupUnavailableException();
      return p.join(await sandboxDir(), kFinanceDatabaseFile);
    }
    final shared = p.join(groupPath, kFinanceDatabaseFile);
    await _adoptSandboxLedger(
      from: p.join(await sandboxDir(), kFinanceDatabaseFile),
      to: shared,
    );
    return shared;
  }
  return p.join(await sandboxDir(), kFinanceDatabaseFile);
}

/// Moves a sandbox ledger (and its WAL / shared-memory files) into the App
/// Group, unless the group already has one. Runs before the database opens.
Future<void> _adoptSandboxLedger({
  required String from,
  required String to,
}) async {
  if (!File(from).existsSync() || File(to).existsSync()) return;
  Directory(p.dirname(to)).createSync(recursive: true);
  for (final suffix in ['', '-wal', '-shm']) {
    final source = File('$from$suffix');
    if (source.existsSync()) {
      try {
        await source.rename('$to$suffix');
      } on FileSystemException {
        // Different volume: copy, then remove the original.
        await source.copy('$to$suffix');
        await source.delete();
      }
    }
  }
}

/// The app's connection to the shared ledger, opened lazily on first query.
QueryExecutor openFinanceConnection() {
  return driftDatabase(
    name: kFinanceDatabaseName,
    native: const DriftNativeOptions(
      databasePath: resolveFinanceDatabasePath,
      setup: configureFinanceConnection,
      // Lets notification / background isolates reuse the UI's connection
      // instead of opening a second writer.
      shareAcrossIsolates: true,
    ),
  );
}
