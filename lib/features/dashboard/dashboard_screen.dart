import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/app_database.dart';
import '../../core/money.dart';
import '../../core/providers/database_providers.dart';
import '../../core/providers/engine_providers.dart';
import '../../core/providers/native_providers.dart';
import '../../ui/category_style.dart';
import '../../ui/theme.dart';
import '../../ui/widgets.dart';
import '../ledger/nudge_composer.dart';
import '../split/split_sheet.dart';
import '../split/transaction_sheet.dart';
import 'burn_chart.dart';
import 'command_bar.dart';
import 'safe_to_spend_card.dart';
import 'survival_meter.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key, required this.onOpenFriends});

  /// Switches the shell to the Friends tab (digest reminder).
  final VoidCallback onOpenFriends;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final burn = ref.watch(burnRateProvider);
    final balance = ref.watch(trueLiquidBalanceProvider);
    final symbol = ref.watch(currencySymbolProvider);
    final metrics = burn.value;
    final liquid = balance.value;

    return Scaffold(
      appBar: AppBar(title: const Text('SPLITBURN')),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('add-expense'),
        // Every tab's FAB lives in one IndexedStack: tags must be unique.
        heroTag: 'fab-split',
        onPressed: () => showSplitSheet(context),
        icon: const Icon(Icons.add),
        label: const Text(
          'SPLIT A BILL',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: switch ((metrics, liquid)) {
        (final m?, final b?) => ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
          children: [
            const CommandBar(),
            const SizedBox(height: 18),
            SafeToSpendCard(metrics: m, symbol: symbol),
            const SizedBox(height: 14),
            LiquidBalancePill(balance: b, symbol: symbol),
            const SizedBox(height: 18),
            SurvivalMeter(metrics: m, symbol: symbol),
            _DigestReminder(onOpenFriends: onOpenFriends),
            const _UpiCaptureCard(),
            const SizedBox(height: 18),
            const _CycleChart(),
            const SectionHeader('Recent'),
            const _RecentActivity(),
          ],
        ),
        _ when burn.hasError || balance.hasError => _LedgerError(
          error: burn.error ?? balance.error!,
        ),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

class _LedgerError extends StatelessWidget {
  const _LedgerError({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'Could not open your ledger.\n$error',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _CycleChart extends ConsumerWidget {
  const _CycleChart();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final days = ref.watch(cycleDailySpendProvider).value;
    final snapshot = ref.watch(ledgerSnapshotProvider).value;
    if (days == null || snapshot == null || days.isEmpty) {
      return const SizedBox.shrink();
    }
    return BurnChart(
      days: days,
      today: snapshot.today,
      evenPaceMinor:
          snapshot.monthlyAllowanceMinor ~/ snapshot.cycle.lengthInDays,
      symbol: ref.watch(currencySymbolProvider),
    );
  }
}

/// On the 1st–3rd, suggest sending monthly digests instead of nagging for
/// each ₹40.
class _DigestReminder extends ConsumerWidget {
  const _DigestReminder({required this.onOpenFriends});

  final VoidCallback onOpenFriends;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = ref.watch(currentDayProvider).value;
    final balances = ref.watch(friendBalancesProvider).value ?? const [];
    final owing = balances.where((b) => b.owedToMeMinor > 0).toList();
    if (today == null ||
        owing.isEmpty ||
        !NudgeComposer.isDigestWindow(today)) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(top: 18),
      child: BrutalCard(
        color: SbColors.lime,
        shadowColor: SbColors.paper,
        onTap: onOpenFriends,
        child: Row(
          children: [
            const Icon(Icons.mark_email_unread_outlined, color: SbColors.ink),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'New month: send ${owing.length} ${owing.length == 1 ? 'friend' : 'friends'} '
                'one tidy digest instead of chasing every small amount.',
                style: const TextStyle(
                  color: SbColors.ink,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const Icon(Icons.chevron_right, color: SbColors.ink),
          ],
        ),
      ),
    );
  }
}

/// Android: nudge the user to turn on UPI auto-capture.
class _UpiCaptureCard extends ConsumerWidget {
  const _UpiCaptureCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bridge = ref.watch(nativeBridgeProvider);
    if (!bridge.supportsUpiCapture) return const SizedBox.shrink();
    final enabled = ref.watch(upiCaptureEnabledProvider).value;
    if (enabled != false) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 18),
      child: BrutalCard(
        shadowColor: SbColors.owed,
        onTap: () async {
          await bridge.openUpiCaptureSettings();
          ref.invalidate(upiCaptureEnabledProvider);
        },
        child: const Row(
          children: [
            Icon(Icons.notifications_active_outlined, color: SbColors.owed),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Turn on UPI auto-capture: GPay, PhonePe, Paytm and bank alerts '
                'get logged for you, even when the app is closed.',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentActivity extends ConsumerWidget {
  const _RecentActivity();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactions = ref.watch(recentTransactionsProvider).value;
    final today = ref.watch(currentDayProvider).value ?? DateTime.now();
    final symbol = ref.watch(currencySymbolProvider);
    if (transactions == null) return const SizedBox.shrink();
    if (transactions.isEmpty) {
      return const EmptyNote(
        'Nothing logged yet. Type what you spent above, or tap Split a bill.',
        icon: Icons.receipt_long_outlined,
      );
    }
    return Column(
      children: [
        for (final t in transactions)
          _TransactionTile(t: t, today: today, symbol: symbol),
      ],
    );
  }
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({
    required this.t,
    required this.today,
    required this.symbol,
  });

  final LedgerTransaction t;
  final DateTime today;
  final String symbol;

  @override
  Widget build(BuildContext context) {
    final tag = t.source.tag;
    final shared = Money.toMinor(t.totalPaid) != Money.toMinor(t.myShare);
    return InkWell(
      onTap: () => showTransactionSheet(context, t.id),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: SbColors.raised, width: 1.5),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: t.category.color,
                border: Border.all(color: SbColors.outline, width: 2),
              ),
              child: Icon(t.category.icon, color: SbColors.ink, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.merchant,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Text(
                        '${relativeDay(t.createdAt, today)}${t.paidByMe ? '' : ' · friend paid'}',
                        style: const TextStyle(
                          color: SbColors.muted,
                          fontSize: 12,
                        ),
                      ),
                      if (tag != null) ...[
                        const SizedBox(width: 8),
                        SbTag(
                          tag,
                          color: t.source == TxnSource.androidUpiAuto
                              ? SbColors.owed
                              : SbColors.paper,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  Money.format(Money.toMinor(t.myShare), symbol: symbol),
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
                if (shared)
                  Text(
                    'of ${Money.format(Money.toMinor(t.totalPaid), symbol: symbol)}',
                    style: const TextStyle(color: SbColors.muted, fontSize: 12),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
