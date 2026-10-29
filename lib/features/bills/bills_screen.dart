import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/database/app_database.dart';
import '../../core/database/daos/subscriptions_dao.dart';
import '../../core/money.dart';
import '../../core/providers/database_providers.dart';
import '../../core/providers/engine_providers.dart';
import '../../ui/theme.dart';
import '../../ui/widgets.dart';
import 'add_bill_sheet.dart';
import 'trial_reminders.dart';
import 'trial_shield.dart';

part 'bills_screen.g.dart';

/// Ticks every minute so trial countdowns stay live.
@riverpod
Stream<DateTime> minuteTicker(Ref ref) {
  final now = ref.watch(clockProvider);
  final controller = StreamController<DateTime>()..add(now());
  final timer = Timer.periodic(
    const Duration(minutes: 1),
    (_) => controller.add(now()),
  );
  ref.onDispose(() {
    timer.cancel();
    controller.close();
  });
  return controller.stream;
}

/// "01d:18h:42m" for the Trial Graveyard countdowns.
String trialClock(Duration left) {
  if (left <= Duration.zero) return '00d:00h:00m';
  String two(int v) => v.toString().padLeft(2, '0');
  return '${two(left.inDays)}d:${two(left.inHours % 24)}h:'
      '${two(left.inMinutes % 60)}m';
}

/// Free Trial Graveyard & Flatmate Recurring Hub (DESIGN_SYSTEM §3 Page 5).
class BillsScreen extends ConsumerWidget {
  const BillsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sb = context.sb;
    final active = ref.watch(activeSubscriptionsProvider).value;
    final graveyard =
        ref.watch(subscriptionGraveyardProvider).value ?? const [];
    final now =
        ref.watch(minuteTickerProvider).value ?? ref.watch(clockProvider)();
    final symbol = ref.watch(currencySymbolProvider);
    final trials = [
      for (final s in active ?? const <Subscription>[])
        if (s.isFreeTrial) s,
    ];
    bool urgent(Subscription t) =>
        t.billingDate.difference(now) < const Duration(hours: 48);
    final recurring = [
      for (final s in active ?? const <Subscription>[])
        if (!s.isFreeTrial) s,
    ];
    // Trials buried before they could charge.
    final savedMinor = graveyard
        .where((g) => g.isFreeTrial)
        .fold(0, (sum, g) => sum + Money.toMinor(g.amount));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bills & trials'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: SbTag(
              'Saved so far ${Money.format(savedMinor, symbol: symbol)}',
              key: const Key('saved-so-far'),
              color: sb.owedToMe,
              icon: Icons.savings_outlined,
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('add-bill'),
        heroTag: 'fab-add-bill',
        onPressed: () => showAddBillSheet(context),
        icon: const Icon(Icons.add),
        label: const Text('Add'),
      ),
      body: active == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
              children: [
                for (final t in trials.where(urgent))
                  _ShieldBanner(trial: t, now: now, symbol: symbol),
                const SectionHeader('Free trial shield'),
                if (trials.isEmpty)
                  const EmptyNote(
                    'Log a free trial and we\'ll warn you 48h and 12h before it charges.',
                    icon: Icons.shield_outlined,
                  )
                else
                  LayoutBuilder(
                    builder: (context, box) => Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        for (final t in trials.where((t) => !urgent(t)))
                          SizedBox(
                            width: (box.maxWidth - 12) / 2,
                            child: _TrialTile(
                              trial: t,
                              now: now,
                              symbol: symbol,
                            ),
                          ),
                      ],
                    ),
                  ),
                const SectionHeader('Flatmate recurring bills'),
                if (recurring.isEmpty)
                  const EmptyNote(
                    'Wi-Fi, electricity, the cook, shared Netflix: add them once and '
                    'everyone gets billed automatically each month.',
                    icon: Icons.home_work_outlined,
                  ),
                for (final r in recurring)
                  _RecurringCard(bill: r, symbol: symbol),
                if (graveyard.isNotEmpty) ...[
                  const SectionHeader('Graveyard'),
                  BentoCard(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Column(
                      children: [
                        for (final g in graveyard)
                          _Tombstone(sub: g, symbol: symbol),
                      ],
                    ),
                  ),
                ],
              ],
            ),
    );
  }
}

Future<void> _bury(
  BuildContext context,
  WidgetRef ref,
  Subscription trial,
) async {
  HapticFeedback.mediumImpact();
  await ref.read(subscriptionsDaoProvider).cancel(trial.id);
  await ref.read(trialReminderSchedulerProvider).cancel(trial.id);
  if (context.mounted) showSnack(context, '${trial.name} buried. Card safe.');
}

void _openCancel(String url) =>
    launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);

/// The 48-hour Trial Shield alert: a breathing amber border, the live
/// countdown and one-tap Cancel & Bury. Swipe it away to bury it too.
class _ShieldBanner extends ConsumerStatefulWidget {
  const _ShieldBanner({
    required this.trial,
    required this.now,
    required this.symbol,
  });

  final Subscription trial;
  final DateTime now;
  final String symbol;

  @override
  ConsumerState<_ShieldBanner> createState() => _ShieldBannerState();
}

class _ShieldBannerState extends ConsumerState<_ShieldBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _breath = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
      _breath.value = 0.5;
    } else if (!_breath.isAnimating) {
      _breath.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _breath.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sb = context.sb;
    final trial = widget.trial;
    final cancelUrl = trial.cancelUrl;
    final amber = sb.trialAmber;
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 6),
      child: Dismissible(
        key: Key('shield-${trial.id}'),
        direction: DismissDirection.endToStart,
        onDismissed: (_) => _bury(context, ref, trial),
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 24),
          child: Icon(Icons.delete_sweep_outlined, color: sb.textSecondary),
        ),
        child: AnimatedBuilder(
          animation: _breath,
          builder: (context, child) => DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(SbRadius.card),
              boxShadow: [
                BoxShadow(
                  color: amber.withValues(alpha: 0.18 + 0.32 * _breath.value),
                  blurRadius: 10 + 14 * _breath.value,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: child,
          ),
          child: BentoCard(
            key: Key('trial-${trial.name}'),
            gradient: LinearGradient(
              colors: [amber, Color.lerp(amber, sb.survivalMagmaEnd, 0.35)!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderColor: amber,
            child: DefaultTextStyle.merge(
              style: const TextStyle(color: SplitBurnTokens.thermalInk),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '48-hour shield alert',
                          style: SbType.section.copyWith(
                            color: SplitBurnTokens.thermalInk,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${trial.name} charges ${Money.format(Money.toMinor(trial.amount), symbol: widget.symbol)}',
                          style: SbType.body.copyWith(
                            fontWeight: FontWeight.w700,
                            color: SplitBurnTokens.thermalInk,
                          ),
                        ),
                        Text(
                          'Charges in ${TrialShield.countdown(trial.billingDate, widget.now)}',
                          key: Key('countdown-${trial.name}'),
                          style: SbType.countdown.copyWith(
                            color: SplitBurnTokens.thermalInk,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  FilledButton(
                    key: Key('buried-${trial.name}'),
                    style: FilledButton.styleFrom(
                      backgroundColor: SplitBurnTokens.thermalInk,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                    ),
                    onPressed: () async {
                      if (cancelUrl != null) _openCancel(cancelUrl);
                      await _bury(context, ref, trial);
                    },
                    child: const Text('Cancel & bury'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A trial with time left: name, mono countdown, cancel link, bury.
class _TrialTile extends ConsumerWidget {
  const _TrialTile({
    required this.trial,
    required this.now,
    required this.symbol,
  });

  final Subscription trial;
  final DateTime now;
  final String symbol;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sb = context.sb;
    final left = trial.billingDate.difference(now);
    final urgent = left < const Duration(hours: 48);
    final soon = left < const Duration(days: 7);
    final cancelUrl = trial.cancelUrl;
    return BentoCard(
      key: Key('trial-${trial.name}'),
      padding: const EdgeInsets.fromLTRB(14, 14, 6, 6),
      borderColor: urgent ? sb.trialAmber : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            trial.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: SbType.body.copyWith(
              fontWeight: FontWeight.w700,
              color: sb.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              trialClock(left),
              style: SbType.countdown.copyWith(
                fontSize: 20,
                color: soon ? sb.survivalMagma : sb.trialAmber,
              ),
            ),
          ),
          Text(
            'Charges in ${TrialShield.countdown(trial.billingDate, now)}',
            key: Key('countdown-${trial.name}'),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: sb.textSecondary, fontSize: 12),
          ),
          Text(
            '${Money.format(Money.toMinor(trial.amount), symbol: symbol)} on '
            '${DateFormat('d MMM').format(trial.billingDate)}',
            style: TextStyle(color: sb.textMuted, fontSize: 12),
          ),
          Row(
            children: [
              if (cancelUrl != null)
                Expanded(
                  child: TextButton(
                    onPressed: () => _openCancel(cancelUrl),
                    style: TextButton.styleFrom(
                      foregroundColor: sb.survivalMagma,
                      padding: EdgeInsets.zero,
                      alignment: Alignment.centerLeft,
                    ),
                    child: const Text('Cancel now'),
                  ),
                )
              else
                const Spacer(),
              IconButton(
                key: Key('buried-${trial.name}'),
                tooltip: 'Bury in the graveyard',
                onPressed: () => _bury(context, ref, trial),
                icon: Icon(
                  Icons.delete_outline_rounded,
                  color: sb.textSecondary,
                  size: 20,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// A shared bill with tappable flatmates: tap someone to mark them away on
/// semester break; their share moves to whoever is home.
class _RecurringCard extends ConsumerWidget {
  const _RecurringCard({required this.bill, required this.symbol});

  final Subscription bill;
  final String symbol;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sb = context.sb;
    final members = bill.autoSplitGroupJson ?? const [];
    String fmt(int minor) => Money.format(minor, symbol: symbol);
    final split = SubscriptionsDao.chargeSplitFor(bill);
    final shareById = {
      for (final e in split.friendShares.entries) e.key.id: e.value,
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: BentoCard(
        key: Key('bill-${bill.name}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    bill.name,
                    style: SbType.body.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 17,
                      color: sb.textPrimary,
                    ),
                  ),
                ),
                Text(
                  '${fmt(Money.toMinor(bill.amount))}/mo',
                  style: SbType.balance.copyWith(
                    fontSize: 20,
                    color: sb.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Your share ${fmt(split.myShareMinor)} · next ${DateFormat('d MMM').format(bill.billingDate)}',
              style: TextStyle(color: sb.textSecondary),
            ),
            if (members.isNotEmpty) ...[
              const SizedBox(height: 12),
              const SbLabel('Split with · tap if away'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 14,
                runSpacing: 10,
                children: [
                  for (final m in members)
                    GestureDetector(
                      key: Key('member-${bill.name}-${m.friendName}'),
                      onTap: () {
                        HapticFeedback.selectionClick();
                        ref
                            .read(subscriptionsDaoProvider)
                            .setMemberAway(bill.id, m.friendId, away: !m.away);
                      },
                      child: Column(
                        children: [
                          FriendAvatar(m.friendName, size: 42, dimmed: m.away),
                          const SizedBox(height: 4),
                          Text(
                            m.friendName,
                            style: SbType.chip.copyWith(
                              color: m.away ? sb.textMuted : sb.textPrimary,
                            ),
                          ),
                          Text(
                            m.away ? 'away' : fmt(shareById[m.friendId] ?? 0),
                            style: SbType.chip.copyWith(
                              fontSize: 11,
                              color: m.away ? sb.textMuted : sb.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () =>
                    ref.read(subscriptionsDaoProvider).cancel(bill.id),
                child: const Text('Stop'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Tombstone extends ConsumerWidget {
  const _Tombstone({required this.sub, required this.symbol});

  final Subscription sub;
  final String symbol;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sb = context.sb;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 38,
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: sb.surfaceElevated,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(19),
            bottom: Radius.circular(4),
          ),
        ),
        child: Text(
          'RIP',
          style: SbType.receipt.copyWith(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: sb.textSecondary,
          ),
        ),
      ),
      title: Text(
        'R.I.P. ${sub.name}',
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        sub.isFreeTrial
            ? 'Killed before it charged · saved ${Money.format(Money.toMinor(sub.amount), symbol: symbol)}'
            : 'Stopped',
        style: TextStyle(color: sb.textSecondary),
      ),
      trailing: TextButton(
        onPressed: () async {
          final next = await showDatePicker(
            context: context,
            firstDate: DateTime.now(),
            lastDate: DateTime.now().add(const Duration(days: 730)),
            helpText: 'Next charge date',
          );
          if (next == null) return;
          final at = DateTime(next.year, next.month, next.day, 9);
          await ref
              .read(subscriptionsDaoProvider)
              .reactivate(sub.id, nextBillingDate: at);
          final revived = await ref.read(subscriptionsDaoProvider).byId(sub.id);
          if (revived != null) {
            await ref
                .read(trialReminderSchedulerProvider)
                .schedule(
                  revived,
                  now: ref.read(clockProvider)(),
                  symbol: symbol,
                );
          }
        },
        child: const Text('Revive'),
      ),
    );
  }
}
