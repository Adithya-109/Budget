import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/ledger_models.dart';
import '../../core/money.dart';
import '../../core/providers/database_providers.dart';
import '../../core/providers/engine_providers.dart';
import '../../domain/debt_simplifier.dart';
import '../../ui/theme.dart';
import '../../ui/widgets.dart';
import 'debt_graph.dart';
import 'friend_detail_screen.dart';
import 'group_settle_screen.dart';
import 'nudge_composer.dart';
import 'nudge_studio.dart';

const _you = 'You';

/// Social ledger (DESIGN_SYSTEM §3 Page 3): totals, the spatial debt graph
/// with the Simplify switch, a settle-up queue and every friend.
class LedgerScreen extends ConsumerStatefulWidget {
  const LedgerScreen({super.key});

  @override
  ConsumerState<LedgerScreen> createState() => _LedgerScreenState();
}

class _LedgerScreenState extends ConsumerState<LedgerScreen> {
  bool _simplify = true;

  @override
  Widget build(BuildContext context) {
    final sb = context.sb;
    final balances = ref.watch(friendBalancesProvider);
    final symbol = ref.watch(currencySymbolProvider);
    final today = ref.watch(currentDayProvider).value ?? DateTime.now();
    String fmt(int v) => Money.format(v, symbol: symbol);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Friends'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: _SimplifySwitch(
              value: _simplify,
              onChanged: (v) => setState(() => _simplify = v),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('group-settle'),
        heroTag: 'fab-group-settle',
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const GroupSettleScreen()),
        ),
        icon: const Icon(Icons.hub_outlined),
        label: const Text('Group settle-up'),
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
              BentoCard(
                borderColor: sb.owedToMe.withValues(alpha: 0.35),
                child: const Text(
                  'It\'s the start of the month: open a friend and send the Monthly digest '
                  'so it\'s one message, not ten.',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
            _GraphSection(balances: list, simplify: _simplify, symbol: symbol),
            _SettleQueue(balances: list, today: today, fmt: fmt),
            const SectionHeader('Everyone'),
            if (list.isEmpty)
              const EmptyNote(
                'Split a bill with someone and they\'ll show up here.',
                icon: Icons.group_outlined,
              )
            else
              BentoCard(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Column(
                  children: [
                    for (var i = 0; i < list.length; i++)
                      _FriendTile(
                        balance: list[i],
                        today: today,
                        fmt: fmt,
                        last: i == list.length - 1,
                      ),
                  ],
                ),
              ),
          ],
        ),
      },
    );
  }
}

class _SimplifySwitch extends StatelessWidget {
  const _SimplifySwitch({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final sb = context.sb;
    return Semantics(
      toggled: value,
      label: 'Simplify debts',
      child: GestureDetector(
        key: const Key('simplify-toggle'),
        onTap: () => onChanged(!value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.fromLTRB(12, 6, 6, 6),
          decoration: BoxDecoration(
            color: value
                ? sb.safeMint.withValues(alpha: 0.14)
                : sb.surfaceElevated,
            borderRadius: BorderRadius.circular(SbRadius.pill),
            border: Border.all(
              color: value
                  ? sb.safeMint.withValues(alpha: 0.4)
                  : sb.hairlineBorder,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Simplify',
                style: SbType.chip.copyWith(
                  fontSize: 13,
                  color: sb.textPrimary,
                ),
              ),
              const SizedBox(width: 8),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: value ? sb.safeMint : sb.surfacePrimary,
                  borderRadius: BorderRadius.circular(SbRadius.pill),
                ),
                child: Text(
                  value ? 'ON' : 'OFF',
                  style: SbType.chip.copyWith(
                    color: value ? sb.onAccent : sb.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Totals extends StatelessWidget {
  const _Totals({required this.balances, required this.fmt});

  final List<FriendBalance> balances;
  final String Function(int) fmt;

  @override
  Widget build(BuildContext context) {
    final sb = context.sb;
    final owed = balances.fold(0, (s, b) => s + b.owedToMeMinor);
    final owe = balances.fold(0, (s, b) => s + b.iOweMinor);
    Widget tile(String label, int value, Color color, Key key) => Expanded(
      child: BentoCard(
        key: key,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SbLabel(label, color: color),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                fmt(value),
                style: SbType.balance.copyWith(color: sb.textPrimary),
              ),
            ),
          ],
        ),
      ),
    );
    return Row(
      children: [
        tile('Owed to you', owed, sb.owedToMe, const Key('total-owed-to-me')),
        const SizedBox(width: 12),
        tile('You owe', owe, sb.iOwe, const Key('total-i-owe')),
      ],
    );
  }
}

/// Your IOUs as a graph. You only know your own debts, so simplifying nets
/// each friend's two directions into one transfer.
class _GraphSection extends StatelessWidget {
  const _GraphSection({
    required this.balances,
    required this.simplify,
    required this.symbol,
  });

  final List<FriendBalance> balances;
  final bool simplify;
  final String symbol;

  @override
  Widget build(BuildContext context) {
    final sb = context.sb;
    // Biggest balances first; the circle stays readable up to 7 friends.
    final active = [
      for (final b in balances)
        if (b.owedToMeMinor > 0 || b.iOweMinor > 0) b,
    ]..sort((a, b) => b.netMinor.abs().compareTo(a.netMinor.abs()));
    if (active.isEmpty) return const SizedBox.shrink();
    final shown = active.take(7).toList();
    final raw = [
      for (final b in shown) ...[
        if (b.owedToMeMinor > 0)
          Debt(from: b.friend.name, to: _you, amountMinor: b.owedToMeMinor),
        if (b.iOweMinor > 0)
          Debt(from: _you, to: b.friend.name, amountMinor: b.iOweMinor),
      ],
    ];
    final simplified = DebtSimplifier.simplify(raw);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeader('Debt graph'),
        BentoCard(
          padding: const EdgeInsets.fromLTRB(8, 12, 8, 12),
          child: Column(
            children: [
              DebtGraphView(
                people: [_you, for (final b in shown) b.friend.name],
                rawDebts: raw,
                simplifiedDebts: simplified,
                simplified: simplify,
                symbol: symbol,
                self: _you,
                height: shown.length <= 2 ? 220 : 300,
              ),
              const SizedBox(height: 8),
              _CollapsePill(
                raw: raw.length,
                transfers: simplified.length,
                simplified: simplify,
              ),
            ],
          ),
        ),
        if (active.length > shown.length)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              '+${active.length - shown.length} more below',
              textAlign: TextAlign.center,
              style: TextStyle(color: sb.textMuted, fontSize: 12),
            ),
          ),
      ],
    );
  }
}

/// "Collapsing 6 raw IOUs into 3 direct transfers".
class _CollapsePill extends StatelessWidget {
  const _CollapsePill({
    required this.raw,
    required this.transfers,
    required this.simplified,
  });

  final int raw;
  final int transfers;
  final bool simplified;

  @override
  Widget build(BuildContext context) {
    final sb = context.sb;
    String plural(int n, String word) => '$n $word${n == 1 ? '' : 's'}';
    final text = !simplified
        ? '${plural(raw, 'raw IOU')}. Switch on Simplify to net them.'
        : raw == transfers
        ? '${plural(raw, 'IOU')}, already as direct as it gets.'
        : 'Collapsing ${plural(raw, 'raw IOU')} into ${plural(transfers, 'direct transfer')}';
    return Container(
      key: const Key('collapse-summary'),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: sb.surfaceElevated,
        borderRadius: BorderRadius.circular(SbRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.hub_outlined, size: 18, color: sb.textSecondary),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              text,
              style: SbType.chip.copyWith(fontSize: 13, color: sb.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}

/// Direct settlement queue: one card per net transfer with the next action.
class _SettleQueue extends ConsumerWidget {
  const _SettleQueue({
    required this.balances,
    required this.today,
    required this.fmt,
  });

  final List<FriendBalance> balances;
  final DateTime today;
  final String Function(int) fmt;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sb = context.sb;
    final open = [
      for (final b in balances)
        if (b.netMinor != 0) b,
    ]..sort((a, b) => b.netMinor.abs().compareTo(a.netMinor.abs()));
    if (open.isEmpty) return const SizedBox.shrink();
    final splits = ref.watch(openSplitsProvider).value ?? const <OpenSplit>[];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          'Settle up',
          trailing: SbTag('${open.length} to go', color: sb.textSecondary),
        ),
        for (final b in open)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: BentoCard(
              key: Key('settle-${b.friend.name}'),
              padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
              onTap: () => _openFriend(context, b),
              child: Row(
                children: [
                  FriendAvatar(b.friend.name, size: 38),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TransferLabel(
                          from: b.netMinor > 0 ? b.friend.name : _you,
                          to: b.netMinor > 0 ? _you : b.friend.name,
                        ),
                        Text(
                          fmt(b.netMinor.abs()),
                          style: SbType.amount.copyWith(
                            color: b.netMinor > 0 ? sb.owedToMe : sb.iOwe,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (b.netMinor > 0)
                    TextButton.icon(
                      onPressed: () => showNudgeStudio(
                        context,
                        friend: b.friend,
                        openSplits: [
                          for (final s in splits)
                            if (s.friend.id == b.friend.id) s,
                        ],
                        initialTone: NudgeComposer.isDigestWindow(today)
                            ? NudgeTone.digest
                            : NudgeTone.polite,
                      ),
                      icon: const Icon(Icons.mark_chat_unread_outlined),
                      label: const Text('Nudge'),
                    )
                  else
                    TextButton.icon(
                      onPressed: () => _openFriend(context, b),
                      icon: const Icon(Icons.bolt_rounded),
                      label: const Text('Pay'),
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  void _openFriend(BuildContext context, FriendBalance b) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => FriendDetailScreen(friend: b.friend),
      ),
    );
  }
}

class _FriendTile extends StatelessWidget {
  const _FriendTile({
    required this.balance,
    required this.today,
    required this.fmt,
    required this.last,
  });

  final FriendBalance balance;
  final DateTime today;
  final String Function(int) fmt;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final sb = context.sb;
    final net = balance.netMinor;
    final oldest = balance.oldestOpenAt;
    final color = net > 0
        ? sb.owedToMe
        : net < 0
        ? sb.iOwe
        : sb.textMuted;
    return InkWell(
      key: Key('friend-${balance.friend.name}'),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => FriendDetailScreen(friend: balance.friend),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: last
              ? null
              : Border(bottom: BorderSide(color: sb.hairlineBorder)),
        ),
        child: Row(
          children: [
            FriendAvatar(
              balance.friend.name,
              size: 40,
              dimmed: balance.isSettledUp,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    balance.friend.name,
                    style: SbType.body.copyWith(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    balance.isSettledUp
                        ? 'All settled'
                        : '${balance.openSplitCount} open'
                              '${oldest == null ? '' : ' · oldest ${relativeDay(oldest, today)}'}',
                    style: TextStyle(color: sb.textSecondary, fontSize: 12),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  net == 0 ? '—' : fmt(net.abs()),
                  style: SbType.amount.copyWith(fontSize: 16, color: color),
                ),
                if (net != 0)
                  Text(
                    net > 0 ? 'owes you' : 'you owe',
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
