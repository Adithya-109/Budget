// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'native_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(nativeBridge)
final nativeBridgeProvider = NativeBridgeProvider._();

final class NativeBridgeProvider
    extends $FunctionalProvider<NativeBridge, NativeBridge, NativeBridge>
    with $Provider<NativeBridge> {
  NativeBridgeProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'nativeBridgeProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$nativeBridgeHash();

  @$internal
  @override
  $ProviderElement<NativeBridge> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  NativeBridge create(Ref ref) {
    return nativeBridge(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(NativeBridge value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<NativeBridge>(value),
    );
  }
}

String _$nativeBridgeHash() => r'8cf76c1160b8f8621f06699cfdcf95f6f4a52866';

/// Re-read with `ref.invalidate` after returning from the settings screen.

@ProviderFor(upiCaptureEnabled)
final upiCaptureEnabledProvider = UpiCaptureEnabledProvider._();

/// Re-read with `ref.invalidate` after returning from the settings screen.

final class UpiCaptureEnabledProvider
    extends $FunctionalProvider<AsyncValue<bool>, bool, FutureOr<bool>>
    with $FutureModifier<bool>, $FutureProvider<bool> {
  /// Re-read with `ref.invalidate` after returning from the settings screen.
  UpiCaptureEnabledProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'upiCaptureEnabledProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$upiCaptureEnabledHash();

  @$internal
  @override
  $FutureProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<bool> create(Ref ref) {
    return upiCaptureEnabled(ref);
  }
}

String _$upiCaptureEnabledHash() => r'1bd978bfe8ce79364ca957a8509365022b8da273';
