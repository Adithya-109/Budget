import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../native/native_bridge.dart';

part 'native_providers.g.dart';

@Riverpod(keepAlive: true)
NativeBridge nativeBridge(Ref ref) => const NativeBridge();

/// Re-read with `ref.invalidate` after returning from the settings screen.
@riverpod
Future<bool> upiCaptureEnabled(Ref ref) =>
    ref.watch(nativeBridgeProvider).isUpiCaptureEnabled();
