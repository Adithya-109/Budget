// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bills_screen.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Ticks every minute so trial countdowns stay live.

@ProviderFor(minuteTicker)
final minuteTickerProvider = MinuteTickerProvider._();

/// Ticks every minute so trial countdowns stay live.

final class MinuteTickerProvider
    extends
        $FunctionalProvider<AsyncValue<DateTime>, DateTime, Stream<DateTime>>
    with $FutureModifier<DateTime>, $StreamProvider<DateTime> {
  /// Ticks every minute so trial countdowns stay live.
  MinuteTickerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'minuteTickerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$minuteTickerHash();

  @$internal
  @override
  $StreamProviderElement<DateTime> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<DateTime> create(Ref ref) {
    return minuteTicker(ref);
  }
}

String _$minuteTickerHash() => r'f6b8b0dbc6e2a47b68abaee6d149ce2201919439';
