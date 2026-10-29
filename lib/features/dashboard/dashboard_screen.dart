import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/app_database.dart';
import '../../core/money.dart';
import '../../core/providers/database_providers.dart';
import '../../core/providers/engine_providers.dart';
import '../../core/providers/native_providers.dart';
import '../../ui/category_style.dart';
import '../../ui/theme.dart';
import '../../ui/theme_mode.dart';
import '../../ui/theme_reveal.dart';
import '../../ui/widgets.dart';
import '../ledger/nudge_composer.dart';
import '../split/transaction_sheet.dart';
import 'burn_chart.dart';
import 'command_bar.dart';
import 'safe_to_spend_card.dart';
import 'survival_meter.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key, required this.onOpenFriends});

  /// Switches the shell to the Friends tab (owed pill, digest reminder).
  final VoidCallback onOpenFriends;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final burn = ref.watch(burnRateProvider);
    final balance = ref.watch(trueLiquidBalanceProvider);
    final symbol = ref.watch(currencySymbolProvider);
    final metrics = burn.value;
    final liquid = balance.value;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: switch ((metrics, liquid)) {
          (final m?, final b?) => Stack(
            children: [
              ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                children: [
                  _Header(daysLeft: m.daysRemaining),
                  const SizedBox(height: 16),
                  LiquidBalanceCard(
                    balance: b,
                    symbol: symbol,
                    onOpenFriends: onOpenFriends,
                  ),
                  const SizedBox(height: 14),
                  SafeToSpendCard(metrics: m, symbol: symbol),
                  const SizedBox(height: 14),
                  SurvivalMeter(metrics: m, symbol: symbol),
                  _DigestReminder(onOpenFriends: onOpenFriends),
                  const _UpiCaptureCard(),
                  const SizedBox(height: 14),
                  const _CycleChart(),
                  const SectionHeader('Recent'),
                  const _RecentActivity(),
                ],
              ),
              const Positioned(
                left: 12,
                right: 12,
                bottom: 12,
                child: CommandBar(),
              ),
            ],
          ),
          _ when burn.hasError || balance.hasError => _LedgerError(
            error: burn.error ?? balance.error!,
          ),
          _ => const Center(child: CircularProgressIndicator()),
        },
      ),
    );
  }
}

/// Greeting, cycle badge and the circular-reveal theme toggle.
class _Header extends ConsumerWidget {
  const _Header({required this.daysLeft});

  final int daysLeft;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sb = context.sb;
    final owner = ref.watch(budgetSettingsProvider).value?.ownerName?.trim();
    final hasName = owner != null && owner.isNotEmpty;
    return Row(
      children: [
        FriendAvatar(hasName ? owner : 'SplitBurn', size: 40),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                hasName ? 'Hi, ${owner.split(' ').first}' : 'SplitBurn',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: SbType.title.copyWith(color: sb.textPrimary),
              ),
              Text(
                'Net-share budget',
                style: SbType.chip.copyWith(
                  fontSize: 13,
                  color: sb.textSecondary,
                ),
              ),
            ],
          ),
        ),
        SbTag(
          '${daysLeft}d left',
          key: const Key('cycle-badge'),
          color: sb.safeMint,
        ),
        const SizedBox(width: 6),
        const ThemeToggleButton(),
      ],
    );
  }
}

/// Sun / moon button: flips the theme with a circular reveal from itself.
class ThemeToggleButton extends ConsumerWidget {
  const ThemeToggleButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dark = context.isDark;
    return IconButton(
      key: const Key('theme-toggle'),
      tooltip: dark ? 'Light mode' : 'Dark mode',
      onPressed: () {
        final box = context.findRenderObject()! as RenderBox;
        final center = box.localToGlobal(box.size.center(Offset.zero));
        ThemeReveal.of(context).run(
          center,
          () => ref
              .read(appThemeModeProvider.notifier)
              .toggleFrom(Theme.of(context).brightness),
        );
      },
      icon: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        transitionBuilder: (child, a) =>
            RotationTransition(turns: a, child: child),
        child: Icon(
          dark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
          key: ValueKey(dark),
          color: context.sb.textSecondary,
        ),
      ),
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
      child: BentoCard(
        onTap: onOpenFriends,
        borderColor: context.sb.owedToMe.withValues(alpha: 0.35),
        child: Row(
          children: [
            Icon(Icons.mark_email_unread_outlined, color: context.sb.owedToMe),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'New month: send ${owing.length} ${owing.length == 1 ? 'friend' : 'friends'} '
                'one tidy digest instead of chasing every small amount.',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: context.sb.textMuted),
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
      child: BentoCard(
        onTap: () async {
          await bridge.openUpiCaptureSettings();
          ref.invalidate(upiCaptureEnabledProvider);
        },
        child: Row(
          children: [
            Icon(
              Icons.notifications_active_outlined,
              color: context.sb.safeMint,
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Turn on UPI auto-capture: GPay, PhonePe, Paytm and bank alerts '
                'get logged for you, even when the app is closed.',
                style: TextStyle(fontWeight: FontWeight.w600),
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
    return BentoCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: Column(
        children: [
          for (var i = 0; i < transactions.length; i++)
            _TransactionTile(
              t: transactions[i],
              today: today,
              symbol: symbol,
              last: i == transactions.length - 1,
            ),
        ],
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({
    required this.t,
    required this.today,
    required this.symbol,
    required this.last,
  });

  final LedgerTransaction t;
  final DateTime today;
  final String symbol;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final sb = context.sb;
    final tag = t.source.tag;
    final shared = Money.toMinor(t.totalPaid) != Money.toMinor(t.myShare);
    final color = t.category.colorIn(sb);
    return InkWell(
      onTap: () => showTransactionSheet(context, t.id),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: last
              ? null
              : Border(bottom: BorderSide(color: sb.hairlineBorder)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(t.category.icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.merchant,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: SbType.body.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          '${relativeDay(t.createdAt, today)}${t.paidByMe ? '' : ' · friend paid'}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: sb.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      if (tag != null) ...[
                        const SizedBox(width: 8),
                        SbTag(
                          tag,
                          color: t.source == TxnSource.androidUpiAuto
                              ? sb.safeMint
                              : sb.info,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  Money.format(Money.toMinor(t.myShare), symbol: symbol),
                  style: SbType.amount.copyWith(color: sb.textPrimary),
                ),
                if (shared)
                  Text(
                    'of ${Money.format(Money.toMinor(t.totalPaid), symbol: symbol)}',
                    style: TextStyle(color: sb.textMuted, fontSize: 12),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
