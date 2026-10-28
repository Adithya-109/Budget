import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/money.dart';
import 'core/providers/database_providers.dart';
import 'core/providers/engine_providers.dart';
import 'core/sync/ledger_sync.dart';
import 'domain/burn_rate.dart';

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
    try {
      await ref.read(ledgerSyncProvider).onForeground();
    } catch (error, stack) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stack,
          library: 'splitburn',
          context: ErrorDescription('while syncing the ledger on resume'),
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
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        colorSchemeSeed: const Color(0xFFFF5A1F),
        useMaterial3: true,
      ),
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFFFF5A1F),
        useMaterial3: true,
      ),
      home: const LedgerOverviewScreen(),
    );
  }
}

/// Live engine output: safe-to-spend, recalibration, Days-Until-Broke and the
/// True Liquid Balance.
class LedgerOverviewScreen extends ConsumerWidget {
  const LedgerOverviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final burn = ref.watch(burnRateProvider);
    final balance = ref.watch(trueLiquidBalanceProvider);
    final symbol =
        ref.watch(budgetSettingsProvider).value?.currencySymbol ?? '₹';
    return Scaffold(
      appBar: AppBar(title: const Text('SplitBurn')),
      // Keep showing the last numbers while a provider refreshes (e.g. the
      // resume sync re-reads the day); only fall back to a spinner or an
      // error when there is nothing to show yet.
      body: switch ((burn.value, balance.value)) {
        (final m?, final b?) => _Overview(
          metrics: m,
          balance: b,
          symbol: symbol,
        ),
        _ when burn.hasError || balance.hasError => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Could not open your ledger.\n${burn.error ?? balance.error}',
              textAlign: TextAlign.center,
            ),
          ),
        ),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

class _Overview extends StatelessWidget {
  const _Overview({
    required this.metrics,
    required this.balance,
    required this.symbol,
  });

  final BurnRateMetrics metrics;
  final TrueLiquidBalance balance;
  final String symbol;

  @override
  Widget build(BuildContext context) {
    String fmt(int minor) => Money.format(minor, symbol: symbol);
    final brokeDate = metrics.brokeDate;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ListTile(
          title: Text(
            metrics.isSurvivalMode ? 'Survival mode' : 'Safe to spend today',
          ),
          subtitle: Text('of ${fmt(metrics.dailyLimitMinor)} daily limit'),
          trailing: Text(
            fmt(metrics.leftTodayMinor),
            key: const Key('safe-today'),
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        if (metrics.tomorrowLimitMinor case final tomorrow?)
          ListTile(
            title: const Text("Tomorrow's limit"),
            trailing: Text(fmt(tomorrow)),
          ),
        ListTile(
          title: const Text('True spendable cash'),
          subtitle: const Text('Bank balance − money you owe friends'),
          trailing: Text(
            fmt(balance.trueSpendableMinor),
            key: const Key('true-spendable'),
          ),
        ),
        ListTile(
          title: const Text('Friends owe you'),
          trailing: Text('+ ${fmt(balance.owedToMeMinor)}'),
        ),
        ListTile(
          title: const Text('Days until broke'),
          subtitle: Text(
            'At ${fmt(metrics.avgDailyBurnMinor)}/day over the last 7 days',
          ),
          trailing: Text(
            brokeDate == null
                ? '—'
                : '${metrics.daysUntilBroke} '
                      '(${brokeDate.day}/${brokeDate.month})',
          ),
        ),
        ListTile(
          title: const Text('Days left in cycle'),
          trailing: Text('${metrics.daysRemaining}'),
        ),
      ],
    );
  }
}
