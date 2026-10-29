import 'dart:io';

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
    final empty = Directory.systemTemp.createTempSync('splitburn-sandbox');
    addTearDown(() => empty.deleteSync(recursive: true));
    expect(
      await resolveFinanceDatabasePath(sandboxDir: () async => empty.path),
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

  test('free-Apple-ID builds keep the ledger in the sandbox', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    messenger.setMockMethodCallHandler(storageChannel, (_) async => null);
    expect(
      await resolveFinanceDatabasePath(
        allowSandbox: true,
        sandboxDir: () async => '/sandbox/Library/Application Support',
      ),
      '/sandbox/Library/Application Support/finance.sqlite',
    );
  });

  test('a sandbox ledger moves into the App Group once it exists', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    final root = Directory.systemTemp.createTempSync('splitburn-adopt');
    addTearDown(() => root.deleteSync(recursive: true));
    final sandbox = Directory('${root.path}/sandbox')..createSync();
    final group = '${root.path}/group';
    File('${sandbox.path}/finance.sqlite').writeAsStringSync('ledger');
    File('${sandbox.path}/finance.sqlite-wal').writeAsStringSync('wal');
    messenger.setMockMethodCallHandler(storageChannel, (_) async => group);

    final path = await resolveFinanceDatabasePath(
      sandboxDir: () async => sandbox.path,
    );
    expect(path, '$group/finance.sqlite');
    expect(File(path).readAsStringSync(), 'ledger');
    expect(File('$path-wal').readAsStringSync(), 'wal');
    expect(File('${sandbox.path}/finance.sqlite').existsSync(), isFalse);

    // A ledger already in the group is never overwritten.
    File('${sandbox.path}/finance.sqlite').writeAsStringSync('stale');
    await resolveFinanceDatabasePath(sandboxDir: () async => sandbox.path);
    expect(File(path).readAsStringSync(), 'ledger');
  });
}
