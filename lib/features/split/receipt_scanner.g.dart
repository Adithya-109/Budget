// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'receipt_scanner.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(receiptScanner)
final receiptScannerProvider = ReceiptScannerProvider._();

final class ReceiptScannerProvider
    extends $FunctionalProvider<ReceiptScanner, ReceiptScanner, ReceiptScanner>
    with $Provider<ReceiptScanner> {
  ReceiptScannerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'receiptScannerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$receiptScannerHash();

  @$internal
  @override
  $ProviderElement<ReceiptScanner> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ReceiptScanner create(Ref ref) {
    return receiptScanner(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ReceiptScanner value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ReceiptScanner>(value),
    );
  }
}

String _$receiptScannerHash() => r'99051895896bf42ae9f4621d93e844775eff6735';
