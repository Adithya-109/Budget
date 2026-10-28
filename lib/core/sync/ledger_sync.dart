import 'dart:async';

import 'package:flutter/services.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../providers/database_providers.dart';
import '../providers/engine_providers.dart';
import '../providers/native_providers.dart';

part 'ledger_sync.g.dart';

/// Keeps Flutter's view of `finance.sqlite` in step with the native writers.
class LedgerSync {
  LedgerSync(this._ref);

  final Ref _ref;

  /// Runs on launch and on every `AppLifecycleState.resumed`:
  ///
  /// 1. Re-runs every Drift stream, because rows an iOS App Intent or the
  ///    Android UPI listener wrote while we were away are invisible to
  ///    Drift's own change tracking (CLAUDE.md §2 rule 3).
  /// 2. Re-reads the date: midnight may have passed while suspended.
  /// 3. Charges recurring bills that fell due while the app was closed.
  /// 4. Re-checks whether UPI capture is still allowed.
  Future<void> onForeground() async {
    _ref.read(appDatabaseProvider).syncExternalWrites();
    _ref.invalidate(currentDayProvider);
    _ref.invalidate(upiCaptureEnabledProvider);
    await _ref
        .read(subscriptionsDaoProvider)
        .chargeDue(now: _ref.read(clockProvider)());
  }
}

@Riverpod(keepAlive: true)
LedgerSync ledgerSync(Ref ref) => LedgerSync(ref);

/// Reloads the iOS widgets shortly after the ledger changes (coalescing a
/// burst of writes into one reload). Watch it once from the root widget.
@Riverpod(keepAlive: true)
bool widgetRefresher(Ref ref) {
  Timer? pending;
  ref.listen(financialSummaryProvider, (previous, next) {
    if (!next.hasValue || previous?.value == next.value) return;
    pending?.cancel();
    pending = Timer(const Duration(milliseconds: 300), () async {
      try {
        await ref.read(nativeBridgeProvider).reloadWidgets();
      } on PlatformException {
        // Widgets are a nicety; never let a reload failure surface.
      } on MissingPluginException {
        // Same: e.g. a build without the widget extension.
      }
    });
  });
  ref.onDispose(() => pending?.cancel());
  return true;
}
