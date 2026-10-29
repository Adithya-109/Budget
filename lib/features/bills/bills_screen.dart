import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/database/app_database.dart';
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

/// Trial Graveyard & Flatmate Recurring Hub.
class BillsScreen extends ConsumerWidget {
  const BillsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
    final recurring = [
      for (final s in active ?? const <Subscription>[])
        if (!s.isFreeTrial) s,
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('BILLS & TRIALS')),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('add-bill'),
        heroTag: 'fab-add-bill',
        onPressed: () => showAddBillSheet(context),
        icon: const Icon(Icons.add),
        label: const Text('ADD', style: TextStyle(fontWeight: FontWeight.w900)),
      ),
      body: active == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
              children: [
                const SectionHeader('Free Trial Shield'),
                if (trials.isEmpty)
                  const EmptyNote(
                    'Log a free trial and we\'ll warn you 48h and 12h before it charges.',
                    icon: Icons.shield_outlined,
                  ),
                for (final t in trials)
                  _TrialCard(trial: t, now: now, symbol: symbol),
                const SectionHeader('Flatmate bills'),
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
                  for (final g in graveyard) _Tombstone(sub: g, symbol: symbol),
                ],
              ],
            ),
    );
  }
}

class _TrialCard extends ConsumerWidget {
  const _TrialCard({
    required this.trial,
    required this.now,
    required this.symbol,
  });

  final Subscription trial;
  final DateTime now;
  final String symbol;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final left = trial.billingDate.difference(now);
    final urgent = left < const Duration(hours: 48);
    final cancelUrl = trial.cancelUrl;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: BrutalCard(
        key: Key('trial-${trial.name}'),
        color: urgent ? SbColors.survival : SbColors.surface,
        shadowColor: urgent ? SbColors.paper : SbColors.magma,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    trial.name,
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 17,
                      color: urgent ? SbColors.ink : SbColors.paper,
                    ),
                  ),
                ),
                SbTag(
                  'CHARGES IN ${TrialShield.countdown(trial.billingDate, now).toUpperCase()}',
                  key: Key('countdown-${trial.name}'),
                  color: urgent ? SbColors.paper : SbColors.magma,
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '${Money.format(Money.toMinor(trial.amount), symbol: symbol)} on '
              '${DateFormat('EEE d MMM, h:mm a').format(trial.billingDate)}',
              style: TextStyle(
                color: urgent ? SbColors.ink : SbColors.muted,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                if (cancelUrl != null)
                  Expanded(
                    child: FilledButton(
                      onPressed: () => launchUrl(
                        Uri.parse(cancelUrl),
                        mode: LaunchMode.externalApplication,
                      ),
                      child: const Text('CANCEL IT NOW'),
                    ),
                  ),
                if (cancelUrl != null) const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    key: Key('buried-${trial.name}'),
                    onPressed: () async {
                      await ref.read(subscriptionsDaoProvider).cancel(trial.id);
                      await ref
                          .read(trialReminderSchedulerProvider)
                          .cancel(trial.id);
                      if (context.mounted) {
                        showSnack(
                          context,
                          '${trial.name} buried. Card safe. 🪦',
                        );
                      }
                    },
                    style: urgent
                        ? OutlinedButton.styleFrom(
                            foregroundColor: SbColors.ink,
                            side: const BorderSide(
                              color: SbColors.ink,
                              width: 2,
                            ),
                          )
                        : null,
                    child: const Text('I CANCELLED IT'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RecurringCard extends ConsumerWidget {
  const _RecurringCard({required this.bill, required this.symbol});

  final Subscription bill;
  final String symbol;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final members = bill.autoSplitGroupJson ?? const [];
    String fmt(double major) =>
        Money.format(Money.toMinor(major), symbol: symbol);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: BrutalCard(
        shadowColor: SbColors.sky,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    bill.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 17,
                    ),
                  ),
                ),
                Text(fmt(bill.amount), style: SbType.figure),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Your share ${fmt(bill.myShare)} · next ${DateFormat('d MMM').format(bill.billingDate)}',
              style: const TextStyle(color: SbColors.muted),
            ),
            if (members.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final m in members)
                    SbTag(m.friendName.toUpperCase(), color: SbColors.sky),
                ],
              ),
            ],
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () =>
                    ref.read(subscriptionsDaoProvider).cancel(bill.id),
                child: const Text('STOP'),
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
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Text('🪦', style: TextStyle(fontSize: 26)),
      title: Text(
        'R.I.P. ${sub.name}',
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
      subtitle: Text(
        sub.isFreeTrial
            ? 'Killed before it charged · saved ${Money.format(Money.toMinor(sub.amount), symbol: symbol)}'
            : 'Stopped',
        style: const TextStyle(color: SbColors.muted),
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
        child: const Text('REVIVE'),
      ),
    );
  }
}
