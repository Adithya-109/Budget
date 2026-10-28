import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../database/connection.dart';

/// Implemented by `MainActivity.kt`.
const captureChannel = MethodChannel('com.splitburn.app/capture');

/// Dart face of the native bridges. Every call is a safe no-op on platforms
/// that don't have the feature, so callers never branch on the platform.
class NativeBridge {
  /// [platform] overrides the detected platform (tests).
  const NativeBridge({
    this.storage = storageChannel,
    this.capture = captureChannel,
    TargetPlatform? platform,
  }) : _platformOverride = platform;

  final MethodChannel storage;
  final MethodChannel capture;
  final TargetPlatform? _platformOverride;

  TargetPlatform? get _platform =>
      _platformOverride ?? (kIsWeb ? null : defaultTargetPlatform);

  bool get supportsWidgets => _platform == TargetPlatform.iOS;

  /// Android reads UPI / bank notifications; iOS logs via App Intents instead.
  bool get supportsUpiCapture => _platform == TargetPlatform.android;

  /// Asks WidgetKit to re-read the ledger after the app writes to it.
  Future<void> reloadWidgets() async {
    if (!supportsWidgets) return;
    await storage.invokeMethod<void>('reloadWidgets');
  }

  /// Whether the user has granted notification access to the UPI listener.
  Future<bool> isUpiCaptureEnabled() async {
    if (!supportsUpiCapture) return false;
    return await capture.invokeMethod<bool>('isUpiCaptureEnabled') ?? false;
  }

  /// Opens the system screen where the user grants notification access.
  Future<void> openUpiCaptureSettings() async {
    if (!supportsUpiCapture) return;
    await capture.invokeMethod<void>('openUpiCaptureSettings');
  }
}
