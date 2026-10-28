import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/database/app_database.dart';
import 'core/money.dart';
import 'core/providers/database_providers.dart';

class SplitBurnApp extends StatelessWidget {
  const SplitBurnApp({super.key});

  @override
  Widget build(BuildContext context) {
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

/// Live read of `financial_summary_view`: the shared ledger's headline numbers.
class LedgerOverviewScreen extends ConsumerWidget {
  const LedgerOverviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(financialSummaryProvider);
    final symbol =
        ref.watch(budgetSettingsProvider).value?.currencySymbol ?? '₹';
    return Scaffold(
      appBar: AppBar(title: const Text('SplitBurn')),
      body: switch (summary) {
        AsyncData(:final value) => _SummaryList(summary: value, symbol: symbol),
        AsyncError(:final error) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Could not open your ledger.\n$error',
              textAlign: TextAlign.center,
            ),
          ),
        ),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

class _SummaryList extends StatelessWidget {
  const _SummaryList({required this.summary, required this.symbol});

  final FinancialSummaryViewData summary;
  final String symbol;

  @override
  Widget build(BuildContext context) {
    String fmt(int minor) => Money.format(minor, symbol: symbol);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ListTile(
          title: const Text('True spendable cash'),
          subtitle: const Text('Bank balance − money you owe friends'),
          trailing: Text(
            fmt(summary.trueSpendableCashMinor),
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        ListTile(
          title: const Text('Friends owe you'),
          trailing: Text('+ ${fmt(summary.owedToMeMinor)}'),
        ),
        ListTile(
          title: const Text('You owe friends'),
          trailing: Text(fmt(summary.iOweMinor)),
        ),
        ListTile(
          title: const Text('Bank balance'),
          trailing: Text(fmt(summary.bankBalanceMinor)),
        ),
        ListTile(
          title: const Text('Personal spend (all time)'),
          trailing: Text(fmt(summary.totalPersonalSpendMinor)),
        ),
      ],
    );
  }
}
