// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ledger_sync.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ledgerSync)
final ledgerSyncProvider = LedgerSyncProvider._();

final class LedgerSyncProvider
    extends $FunctionalProvider<LedgerSync, LedgerSync, LedgerSync>
    with $Provider<LedgerSync> {
  LedgerSyncProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'ledgerSyncProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$ledgerSyncHash();

  @$internal
  @override
  $ProviderElement<LedgerSync> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  LedgerSync create(Ref ref) {
    return ledgerSync(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LedgerSync value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LedgerSync>(value),
    );
  }
}

String _$ledgerSyncHash() => r'ceb1339a1161dcd0c4915c9a849b4c22a9ee55a6';

/// Reloads the iOS widgets shortly after the ledger changes (coalescing a
/// burst of writes into one reload). Watch it once from the root widget.

@ProviderFor(widgetRefresher)
final widgetRefresherProvider = WidgetRefresherProvider._();

/// Reloads the iOS widgets shortly after the ledger changes (coalescing a
/// burst of writes into one reload). Watch it once from the root widget.

final class WidgetRefresherProvider
    extends $FunctionalProvider<bool, bool, bool>
    with $Provider<bool> {
  /// Reloads the iOS widgets shortly after the ledger changes (coalescing a
  /// burst of writes into one reload). Watch it once from the root widget.
  WidgetRefresherProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'widgetRefresherProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$widgetRefresherHash();

  @$internal
  @override
  $ProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  bool create(Ref ref) {
    return widgetRefresher(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$widgetRefresherHash() => r'dbbaab3f361f5fcd586a6f339c143f4ade259367';
