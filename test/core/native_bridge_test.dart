import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:splitburn/core/database/connection.dart';
import 'package:splitburn/core/native/native_bridge.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  final calls = <String>[];

  setUp(() {
    calls.clear();
    for (final channel in [storageChannel, captureChannel]) {
      messenger.setMockMethodCallHandler(channel, (call) async {
        calls.add('${channel.name}#${call.method}');
        return switch (call.method) {
          'isUpiCaptureEnabled' => true,
          'getAppGroupPath' =>
            '/private/var/mobile/Containers/Shared/AppGroup/X',
          _ => null,
        };
      });
    }
  });

  tearDown(() {
    messenger.setMockMethodCallHandler(storageChannel, null);
    messenger.setMockMethodCallHandler(captureChannel, null);
  });

  test('iOS reloads widgets and never touches the capture channel', () async {
    const bridge = NativeBridge(platform: TargetPlatform.iOS);
    await bridge.reloadWidgets();
    expect(await bridge.isUpiCaptureEnabled(), isFalse);
    await bridge.openUpiCaptureSettings();
    expect(calls, ['com.splitburn.app/storage#reloadWidgets']);
  });

  test('Android exposes UPI capture and skips widget reloads', () async {
    const bridge = NativeBridge(platform: TargetPlatform.android);
    await bridge.reloadWidgets();
    expect(await bridge.isUpiCaptureEnabled(), isTrue);
    await bridge.openUpiCaptureSettings();
    expect(calls, [
      'com.splitburn.app/capture#isUpiCaptureEnabled',
      'com.splitburn.app/capture#openUpiCaptureSettings',
    ]);
  });

  test('iOS database path lives in the App Group container', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    expect(
      await resolveFinanceDatabasePath(),
      '/private/var/mobile/Containers/Shared/AppGroup/X/finance.sqlite',
    );
  });

  test('missing App Group fails loudly instead of using the sandbox', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    messenger.setMockMethodCallHandler(storageChannel, (_) async => null);
    await expectLater(
      resolveFinanceDatabasePath(),
      throwsA(isA<AppGroupUnavailableException>()),
    );
  });
}
