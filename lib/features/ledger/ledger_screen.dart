import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/ledger_models.dart';
import '../../core/money.dart';
import '../../core/providers/database_providers.dart';
import '../../core/providers/engine_providers.dart';
import '../../domain/debt_simplifier.dart';
import '../../ui/theme.dart';
import '../../ui/widgets.dart';
import 'friend_detail_screen.dart';
import 'group_settle_screen.dart';
import 'nudge_composer.dart';

/// Social ledger: who owes whom, simplified, with nudges one tap away.
class LedgerScreen extends ConsumerWidget {
  const LedgerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balances = ref.watch(friendBalancesProvider);
    final symbol = ref.watch(currencySymbolProvider);
    final today = ref.watch(currentDayProvider).value ?? DateTime.now();
    String fmt(int v) => Money.format(v, symbol: symbol);

    return Scaffold(
      appBar: AppBar(title: const Text('FRIENDS')),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('group-settle'),
        heroTag: 'fab-group-settle',
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const GroupSettleScreen()),
        ),
        icon: const Icon(Icons.hub_outlined),
        label: const Text(
          'GROUP SETTLE-UP',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: switch (balances.value) {
        null when balances.hasError => Center(child: Text('${balances.error}')),
        null => const Center(child: CircularProgressIndicator()),
        final list => ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
          children: [
            _Totals(balances: list, fmt: fmt),
            if (NudgeComposer.isDigestWindow(today) &&
                list.any((b) => b.owedToMeMinor > 0)) ...[
              const SizedBox(height: 14),
              const BrutalCard(
                color: SbColors.lime,
                shadowColor: SbColors.paper,
                child: Text(
                  'It\'s the start of the month: open a friend and send the Monthly digest '
                  'so it\'s one message, not ten.',
                  style: TextStyle(
                    color: SbColors.ink,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
            _SimplifiedSettlements(balances: list, fmt: fmt),
            const SectionHeader('Everyone'),
            if (list.isEmpty)
              const EmptyNote(
                'Split a bill with someone and they\'ll show up here.',
                icon: Icons.group_outlined,
              ),
            for (final b in list)
              _FriendTile(balance: b, today: today, fmt: fmt),
          ],
        ),
      },
    );
  }
}

class _Totals extends StatelessWidget {
  const _Totals({required this.balances, required this.fmt});

  final List<FriendBalance> balances;
  final String Function(int) fmt;

  @override
  Widget build(BuildContext context) {
    final owed = balances.fold(0, (s, b) => s + b.owedToMeMinor);
    final owe = balances.fold(0, (s, b) => s + b.iOweMinor);
    Widget tile(String label, int value, Color color, Key key) => Expanded(
      child: BrutalCard(
        key: key,
        shadowColor: color,
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SbLabel(label, color: color),
            const SizedBox(height: 6),
            FittedBox(
              child: Text(
                fmt(value),
                style: SbType.figure.copyWith(fontSize: 26),
              ),
            ),
          ],
        ),
      ),
    );
    return Row(
      children: [
        tile('Owed to you', owed, SbColors.owed, const Key('total-owed-to-me')),
        const SizedBox(width: 14),
        tile('You owe', owe, SbColors.magma, const Key('total-i-owe')),
      ],
    );
  }
}

/// Netted per friend: each pair settles in at most one transfer.
class _SimplifiedSettlements extends StatelessWidget {
  const _SimplifiedSettlements({required this.balances, required this.fmt});

  final List<FriendBalance> balances;
  final String Function(int) fmt;

  @override
  Widget build(BuildContext context) {
    final raw = [
      for (final b in balances) ...[
        if (b.owedToMeMinor > 0)
          Debt(from: b.friend.name, to: 'You', amountMinor: b.owedToMeMinor),
        if (b.iOweMinor > 0)
          Debt(from: 'You', to: b.friend.name, amountMinor: b.iOweMinor),
      ],
    ];
    if (raw.isEmpty) return const SizedBox.shrink();
    final transfers = DebtSimplifier.simplify(raw);
    final saved = raw.length - transfers.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          'To settle everything',
          trailing: saved > 0
              ? SbTag(
                  '$saved FEWER ${saved == 1 ? 'TRANSFER' : 'TRANSFERS'}',
                  color: SbColors.lime,
                )
              : null,
        ),
        for (final t in transfers)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: TransferLabel(from: t.from, to: t.to),
                ),
                Text(
                  fmt(t.amountMinor),
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: t.to == 'You' ? SbColors.owed : SbColors.magma,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _FriendTile extends StatelessWidget {
  const _FriendTile({
    required this.balance,
    required this.today,
    required this.fmt,
  });

  final FriendBalance balance;
  final DateTime today;
  final String Function(int) fmt;

  @override
  Widget build(BuildContext context) {
    final net = balance.netMinor;
    final oldest = balance.oldestOpenAt;
    final color = net > 0
        ? SbColors.owed
        : net < 0
        ? SbColors.magma
        : SbColors.muted;
    return InkWell(
      key: Key('friend-${balance.friend.name}'),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => FriendDetailScreen(friend: balance.friend),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: SbColors.raised, width: 1.5),
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color,
              foregroundColor: SbColors.ink,
              child: Text(
                balance.friend.name.characters.first.toUpperCase(),
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    balance.friend.name,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  Text(
                    balance.isSettledUp
                        ? 'All settled'
                        : '${balance.openSplitCount} open'
                              '${oldest == null ? '' : ' · oldest ${relativeDay(oldest, today)}'}',
                    style: const TextStyle(color: SbColors.muted, fontSize: 12),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  net == 0 ? '—' : fmt(net.abs()),
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    color: color,
                  ),
                ),
                if (net != 0)
                  Text(
                    net > 0 ? 'owes you' : 'you owe',
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
