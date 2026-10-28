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

/// Where `finance.sqlite` lives on this device.
///
/// * iOS: the shared App Group container, so `AppIntents` and `WidgetKit`
///   read the same file. Never falls back to the app sandbox: a silent
///   fallback would split the ledger into two databases.
/// * Android: `context.filesDir` (what `getApplicationSupportDirectory`
///   returns), the same path the Kotlin `NotificationListenerService` opens.
Future<String> resolveFinanceDatabasePath() async {
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
      throw const AppGroupUnavailableException();
    }
    return p.join(groupPath, kFinanceDatabaseFile);
  }
  final supportDir = await getApplicationSupportDirectory();
  return p.join(supportDir.path, kFinanceDatabaseFile);
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
