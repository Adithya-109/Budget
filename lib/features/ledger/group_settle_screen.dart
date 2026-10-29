import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/database/enums.dart';
import '../../core/money.dart';
import '../../core/providers/database_providers.dart';
import '../../core/providers/engine_providers.dart';
import '../../domain/expense_draft.dart';
import '../../ui/prompts.dart';
import '../../ui/theme.dart';
import '../../ui/widgets.dart';
import '../friends/friend_directory.dart';
import 'group_settle.dart';

const _you = 'You';

class _BillDraft {
  _BillDraft({required this.payer, required this.sharedBy});

  final label = TextEditingController();
  final amount = TextEditingController();
  String payer;
  Set<String> sharedBy;

  void dispose() {
    label.dispose();
    amount.dispose();
  }
}

/// Trip / party settle-up when several people paid: enter who paid what,
/// get the fewest transfers that square the whole group.
class GroupSettleScreen extends ConsumerStatefulWidget {
  const GroupSettleScreen({super.key});

  @override
  ConsumerState<GroupSettleScreen> createState() => _GroupSettleScreenState();
}

class _GroupSettleScreenState extends ConsumerState<GroupSettleScreen> {
  final _name = TextEditingController();
  final _people = <String>[_you];
  final _bills = <_BillDraft>[];
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _bills.add(_BillDraft(payer: _you, sharedBy: {_you}));
  }

  @override
  void dispose() {
    _name.dispose();
    for (final b in _bills) {
      b.dispose();
    }
    super.dispose();
  }

  Future<void> _addPerson() async {
    final directory =
        ref.read(friendDirectoryProvider).value ?? FriendDirectory(const []);
    final name = await promptFriendName(
      context,
      directory: directory,
      title: 'Who else was there?',
    );
    final trimmed = name?.trim() ?? '';
    if (trimmed.isEmpty ||
        _people.any((p) => p.toLowerCase() == trimmed.toLowerCase())) {
      return;
    }
    setState(() {
      _people.add(trimmed);
      for (final b in _bills) {
        b.sharedBy = {...b.sharedBy, trimmed};
      }
    });
  }

  GroupSettlement _compute() => GroupSettlement.compute([
    for (final b in _bills)
      GroupBill(
        label: b.label.text.trim().isEmpty ? 'Bill' : b.label.text.trim(),
        payer: b.payer,
        amountMinor: parseMoneyInput(b.amount.text) ?? 0,
        sharedBy: [
          for (final p in _people)
            if (b.sharedBy.contains(p)) p,
        ],
      ),
  ]);

  String _summary(GroupSettlement s, String Function(int) fmt) {
    final title = _name.text.trim().isEmpty ? 'Our trip' : _name.text.trim();
    final lines = s.transfers
        .map((t) => '• ${t.from} → ${t.to}: ${fmt(t.amountMinor)}')
        .join('\n');
    return '$title settle-up (via SplitBurn)\n$lines\n'
        '${s.transfers.length} ${s.transfers.length == 1 ? 'transfer' : 'transfers'} squares everyone.';
  }

  Future<void> _record(GroupSettlement s) async {
    final directory =
        ref.read(friendDirectoryProvider).value ?? FriendDirectory(const []);
    final owedToMe = <FriendRef, int>{};
    final iOwe = <FriendRef, int>{};
    for (final t in s.transfersFor(_you)) {
      if (t.to == _you) {
        final f = directory.resolve(t.from);
        owedToMe[f] = (owedToMe[f] ?? 0) + t.amountMinor;
      } else {
        final f = directory.resolve(t.to);
        iOwe[f] = (iOwe[f] ?? 0) + t.amountMinor;
      }
    }
    setState(() => _saving = true);
    try {
      await ref
          .read(ledgerDaoProvider)
          .logGroupSettlement(
            label: _name.text.trim().isEmpty
                ? 'Group settle-up'
                : _name.text.trim(),
            paidMinor: s.paidBy(_you),
            shareMinor: s.shareOf(_you),
            category: TxnCategory.fun,
            owedToMe: owedToMe,
            iOwe: iOwe,
            at: ref.read(clockProvider)(),
          );
      if (!mounted) return;
      showSnack(
        context,
        'Added to your ledger: your share counts, the rest is IOUs.',
      );
      Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final symbol = ref.watch(currencySymbolProvider);
    String fmt(int v) => Money.format(v, symbol: symbol);
    final settlement = _compute();
    final involvesMe =
        settlement.paidBy(_you) > 0 || settlement.shareOf(_you) > 0;

    return Scaffold(
      appBar: AppBar(title: const Text('GROUP SETTLE-UP')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
        children: [
          TextField(
            controller: _name,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'What was it? (Goa trip, flat party…)',
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SectionHeader('People'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final p in _people)
                // A plain Chip for "You": an InputChip with no actions
                // renders as disabled.
                if (p == _you)
                  Chip(label: Text(p))
                else
                  InputChip(
                    label: Text(p),
                    onDeleted: () => setState(() {
                      _people.remove(p);
                      for (final b in _bills) {
                        b.sharedBy = {...b.sharedBy}..remove(p);
                        if (b.payer == p) b.payer = _you;
                      }
                    }),
                  ),
              ActionChip(
                avatar: const Icon(Icons.person_add_alt_1, size: 16),
                label: const Text('Add'),
                onPressed: _addPerson,
              ),
            ],
          ),
          const SectionHeader('Bills'),
          for (var i = 0; i < _bills.length; i++) _billCard(i, symbol),
          OutlinedButton.icon(
            onPressed: () => setState(
              () => _bills.add(_BillDraft(payer: _you, sharedBy: {..._people})),
            ),
            icon: const Icon(Icons.add),
            label: const Text('ADD BILL'),
          ),
          const SectionHeader('Settle like this'),
          if (settlement.transfers.isEmpty)
            const EmptyNote(
              'Add amounts and who paid to see the transfers.',
              icon: Icons.hub_outlined,
            )
          else
            BrutalCard(
              key: const Key('group-transfers'),
              shadowColor: SbColors.owed,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final t in settlement.transfers)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Expanded(
                            child: TransferLabel(from: t.from, to: t.to),
                          ),
                          Text(
                            fmt(t.amountMinor),
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 8),
                  Text(
                    '${settlement.rawDebtCount} IOUs squashed into ${settlement.transfers.length} '
                    '${settlement.transfers.length == 1 ? 'transfer' : 'transfers'}.',
                    style: const TextStyle(color: SbColors.muted),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: settlement.transfers.isEmpty
                      ? null
                      : () => SharePlus.instance.share(
                          ShareParams(text: _summary(settlement, fmt)),
                        ),
                  icon: const Icon(Icons.ios_share),
                  label: const Text('SHARE'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  onPressed: !involvesMe || _saving
                      ? null
                      : () => _record(settlement),
                  child: const Text('ADD MY PART'),
                ),
              ),
            ],
          ),
          if (involvesMe)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'You paid ${fmt(settlement.paidBy(_you))}; your share is ${fmt(settlement.shareOf(_you))}. '
                'Only your share counts as spending.',
                style: const TextStyle(color: SbColors.muted),
              ),
            ),
        ],
      ),
    );
  }

  Widget _billCard(int i, String symbol) {
    final b = _bills[i];
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: BrutalCard(
        shadowColor: SbColors.sky,
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: b.label,
                    decoration: const InputDecoration(
                      labelText: 'Bill',
                      isDense: true,
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: b.amount,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: moneyInputFormatters,
                    decoration: InputDecoration(
                      labelText: 'Amount',
                      prefixText: '$symbol ',
                      isDense: true,
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                if (_bills.length > 1)
                  IconButton(
                    onPressed: () =>
                        setState(() => _bills.removeAt(i).dispose()),
                    icon: const Icon(Icons.close),
                    tooltip: 'Remove bill',
                  ),
              ],
            ),
            const SizedBox(height: 10),
            const SbLabel('Paid by'),
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final p in _people)
                  ChoiceChip(
                    label: Text(p),
                    selected: b.payer == p,
                    showCheckmark: false,
                    labelStyle: TextStyle(
                      color: b.payer == p ? SbColors.ink : SbColors.paper,
                    ),
                    onSelected: (_) => setState(() => b.payer = p),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            const SbLabel('Shared by'),
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final p in _people)
                  FilterChip(
                    label: Text(p),
                    selected: b.sharedBy.contains(p),
                    labelStyle: TextStyle(
                      color: b.sharedBy.contains(p)
                          ? SbColors.ink
                          : SbColors.paper,
                    ),
                    onSelected: (on) => setState(
                      () => b.sharedBy = on
                          ? {...b.sharedBy, p}
                          : ({...b.sharedBy}..remove(p)),
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
