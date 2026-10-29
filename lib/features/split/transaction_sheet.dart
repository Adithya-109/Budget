import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/database/app_database.dart';
import '../../core/money.dart';
import '../../core/providers/database_providers.dart';
import '../../domain/expense_draft.dart';
import '../../ui/category_style.dart';
import '../../ui/theme.dart';
import '../../ui/widgets.dart';
import 'split_builder.dart';
import 'split_sheet.dart';

Future<void> showTransactionSheet(BuildContext context, String transactionId) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => TransactionSheet(transactionId: transactionId),
  );
}

/// The split form that reproduces an existing transaction (for re-splitting).
SplitForm splitFormFromTransaction(
  LedgerTransaction t,
  List<SplitEntry> splits,
) {
  final friends = <FriendParticipant>[
    for (final s in splits)
      FriendParticipant(
        FriendRef(
          id: s.friendId,
          name: s.friendName,
          paymentHandle: s.friendPaymentHandle,
        ),
      ),
  ];
  return SplitForm(
    merchant: t.merchant,
    totalMinor: Money.toMinor(t.totalPaid),
    category: t.category,
    participants: [const Me(), ...friends],
    payer: t.paidByMe || friends.isEmpty ? const Me() : friends.first,
    source: t.source,
  );
}

class TransactionSheet extends ConsumerWidget {
  const TransactionSheet({super.key, required this.transactionId});

  final String transactionId;

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    LedgerTransaction t,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this expense?'),
        content: const Text(
          'Its IOUs go too, and your bank balance is put back as if it never happened.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(ledgerDaoProvider).deleteTransaction(t.id);
    if (context.mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(transactionByIdProvider(transactionId)).value;
    final splits =
        ref.watch(transactionSplitsProvider(transactionId)).value ?? const [];
    final symbol = ref.watch(currencySymbolProvider);
    String fmt(int v) => Money.format(v, symbol: symbol);
    if (t == null) {
      return const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    final dao = ref.read(ledgerDaoProvider);
    final tag = t.source.tag;
    final sb = context.sb;
    final color = t.category.colorIn(sb);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(t.category.icon, color: color, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  t.merchant,
                  style: SbType.title.copyWith(color: sb.textPrimary),
                ),
              ),
              if (tag != null) SbTag(tag, color: sb.info),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${t.category.code} · ${DateFormat('EEE d MMM, h:mm a').format(t.createdAt)}',
            style: TextStyle(color: sb.textSecondary),
          ),
          const SizedBox(height: 16),
          BentoCard(
            child: Column(
              children: [
                _Line(
                  'Your share',
                  fmt(Money.toMinor(t.myShare)),
                  strong: true,
                ),
                _Line(
                  t.paidByMe ? 'You paid' : 'Bill (a friend paid)',
                  fmt(Money.toMinor(t.totalPaid)),
                ),
                if (t.paidByMe &&
                    Money.toMinor(t.totalPaid) > Money.toMinor(t.myShare))
                  _Line(
                    'Fronted for friends',
                    fmt(Money.toMinor(t.totalPaid) - Money.toMinor(t.myShare)),
                  ),
              ],
            ),
          ),
          if (splits.isNotEmpty) ...[
            const SectionHeader('IOUs'),
            for (final s in splits)
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  s.direction == SplitDirection.owesMe
                      ? '${s.friendName} owes you ${fmt(Money.toMinor(s.amount))}'
                      : 'You owe ${s.friendName} ${fmt(Money.toMinor(s.amount))}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                secondary: FriendAvatar(
                  s.friendName,
                  size: 34,
                  dimmed: s.isSettled,
                ),
                subtitle: Text(
                  s.isSettled ? 'Settled' : 'Open',
                  style: TextStyle(
                    color: s.isSettled ? sb.owedToMe : sb.textSecondary,
                  ),
                ),
                value: s.isSettled,
                onChanged: (settled) =>
                    settled ? dao.settleSplit(s.id) : dao.unsettleSplit(s.id),
              ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  icon: const Icon(Icons.call_split),
                  label: Text(splits.isEmpty ? 'Split it' : 'Re-split'),
                  onPressed: () async {
                    final saved = await showSplitSheet(
                      context,
                      initial: splitFormFromTransaction(t, splits),
                      resplitTransactionId: t.id,
                    );
                    if (saved && context.mounted) Navigator.pop(context);
                  },
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton.icon(
                icon: const Icon(Icons.delete_outline),
                label: const Text('Delete'),
                onPressed: () => _delete(context, ref, t),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line(this.label, this.value, {this.strong = false});

  final String label;
  final String value;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(color: context.sb.textSecondary),
            ),
          ),
          Text(
            value,
            style: strong
                ? SbType.balance.copyWith(
                    fontSize: 22,
                    color: context.sb.textPrimary,
                  )
                : SbType.amount.copyWith(color: context.sb.textPrimary),
          ),
        ],
      ),
    );
  }
}
