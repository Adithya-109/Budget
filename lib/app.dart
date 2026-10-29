import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/providers/database_providers.dart';
import 'core/providers/engine_providers.dart';
import 'core/sync/ledger_sync.dart';
import 'features/bills/trial_reminders.dart';
import 'ui/home_shell.dart';
import 'ui/theme.dart';
import 'ui/theme_mode.dart';
import 'ui/theme_reveal.dart';

/// Root widget. Owns the foreground resume sync (CLAUDE.md §2 rule 3).
class SplitBurnApp extends ConsumerStatefulWidget {
  const SplitBurnApp({super.key});

  @override
  ConsumerState<SplitBurnApp> createState() => _SplitBurnAppState();
}

class _SplitBurnAppState extends ConsumerState<SplitBurnApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Launch counts as coming to the foreground.
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncLedger());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _syncLedger();
  }

  Future<void> _syncLedger() async {
    await _guarded('while syncing the ledger on resume', () async {
      await ref.read(ledgerSyncProvider).onForeground();
    });
    // Separate guard: a notification hiccup must never block the ledger.
    await _guarded('while rescheduling Free Trial Shield reminders', () async {
      final subscriptions = await ref
          .read(subscriptionsDaoProvider)
          .watchActive()
          .first;
      await ref
          .read(trialReminderSchedulerProvider)
          .resync(
            subscriptions,
            now: ref.read(clockProvider)(),
            symbol: ref.read(currencySymbolProvider),
          );
    });
  }

  Future<void> _guarded(String what, Future<void> Function() body) async {
    try {
      await body();
    } catch (error, stack) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stack,
          library: 'splitburn',
          context: ErrorDescription(what),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(widgetRefresherProvider);
    return MaterialApp(
      title: 'SplitBurn',
      debugShowCheckedModeBanner: false,
      theme: buildSplitBurnTheme(Brightness.light),
      darkTheme: buildSplitBurnTheme(Brightness.dark),
      themeMode: ref.watch(appThemeModeProvider),
      // ThemeReveal animates switches; a cross-fade underneath would smear.
      themeAnimationDuration: Duration.zero,
      builder: (context, child) => ThemeReveal(child: child!),
      home: const HomeShell(),
    );
  }
}
