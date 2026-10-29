import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'features/web_ledger/web_ledger_app.dart';
import 'ui/theme_mode.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  _registerFontLicences();
  if (kIsWeb) {
    // The web build is only the zero-install tab viewer for friends.
    runApp(const WebLedgerApp());
    return;
  }
  SharedPreferences? prefs;
  try {
    prefs = await SharedPreferences.getInstance();
  } on Object catch (error, stack) {
    // The theme choice is cosmetic: never block launch on it.
    FlutterError.reportError(
      FlutterErrorDetails(exception: error, stack: stack, library: 'splitburn'),
    );
  }
  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const SplitBurnApp(),
    ),
  );
}

/// Bundled fonts are SIL OFL 1.1, which asks for the licence to travel along.
void _registerFontLicences() {
  const fonts = {
    'Inter': 'assets/fonts/OFL-Inter.txt',
    'Plus Jakarta Sans': 'assets/fonts/OFL-PlusJakartaSans.txt',
    'JetBrains Mono': 'assets/fonts/OFL-JetBrainsMono.txt',
  };
  LicenseRegistry.addLicense(() async* {
    for (final MapEntry(key: name, value: asset) in fonts.entries) {
      yield LicenseEntryWithLineBreaks([
        name,
      ], await rootBundle.loadString(asset));
    }
  });
}
