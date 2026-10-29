import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'features/web_ledger/web_ledger_app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) {
    // The web build is only the zero-install tab viewer for friends.
    runApp(const WebLedgerApp());
    return;
  }
  runApp(const ProviderScope(child: SplitBurnApp()));
}
