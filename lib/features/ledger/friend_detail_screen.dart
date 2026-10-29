import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/database/app_database.dart';
import '../../core/database/ledger_models.dart';
import '../../core/money.dart';
import '../../core/providers/database_providers.dart';
import '../../core/providers/engine_providers.dart';
import '../../domain/expense_draft.dart';
import '../../ui/prompts.dart';
import '../../ui/theme.dart';
import '../../ui/widgets.dart';
import 'nudge_composer.dart';
import 'nudge_studio.dart';
import 'settle_links.dart';

/// One friend: open IOUs, settle actions, Pay Now and the Nudge Bot.
class FriendDetailScreen extends ConsumerWidget {
  const FriendDetailScreen({super.key, required this.friend});

  final FriendRef friend;

  Future<void> _editHandle(
    BuildContext context,
    WidgetRef ref,
    String? current,
  ) async {
    final handle = await promptText(
      context,
      title: '${friend.name}\'s UPI ID or Venmo',
      initial: current ?? '',
      hint: 'name@okaxis or @venmo-handle',
    );
    if (handle == null) return;
    if (handle.trim().isNotEmpty && SettleLinks.railOf(handle) == null) {
      if (context.mounted) {
        showSnack(context, 'That doesn\'t look like a UPI ID or Venmo handle.');
      }
      return;
    }
    await ref
        .read(ledgerDaoProvider)
        .updateFriendPaymentHandle(friend.id, handle);
  }

  Future<void> _settleAll(
    BuildContext context,
    WidgetRef ref,
    String Function(int) fmt,
  ) async {
    final result = await ref
        .read(ledgerDaoProvider)
        .settleAllWithFriend(friend.id, at: ref.read(clockProvider)());
    if (!context.mounted) return;
    final delta = result.bankDeltaMinor;
    showSnack(
      context,
      delta == 0
          ? 'All square with ${friend.name}.'
          : delta > 0
          ? '${fmt(delta)} back in your bank. Not income: it was your money.'
          : 'Paid ${friend.name} ${fmt(-delta)}.',
    );
  }

  Future<void> _payNow(
    BuildContext context,
    WidgetRef ref, {
    required String handle,
    required int amountMinor,
    required String Function(int) fmt,
  }) async {
    final link = SettleLinks.forHandle(
      handle: handle,
      payeeName: friend.name,
      amountMinor: amountMinor,
    );
    if (link == null) return;
    final opened = await launchUrl(link, mode: LaunchMode.externalApplication);
    if (!context.mounted) return;
    if (!opened) {
      showSnack(
        context,
        'No ${SettleLinks.railOf(handle) == PaymentRail.upi ? 'UPI' : 'Venmo'} app found.',
      );
      return;
    }
    final paid = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Did the payment go through?'),
        content: Text(
          'Mark everything with ${friend.name} as settled (${fmt(amountMinor)})?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Not yet'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes, settled'),
          ),
        ],
      ),
    );
    if (paid == true && context.mounted) await _settleAll(context, ref, fmt);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final symbol = ref.watch(currencySymbolProvider);
    final today = ref.watch(currentDayProvider).value ?? DateTime.now();
    String fmt(int v) => Money.format(v, symbol: symbol);
    final balance = ref
        .watch(friendBalancesProvider)
        .value
        ?.where((b) => b.friend.id == friend.id)
        .firstOrNull;
    final open = [
      for (final s
          in ref.watch(openSplitsProvider).value ?? const <OpenSplit>[])
        if (s.friend.id == friend.id) s,
    ];
    final handle = balance?.friend.paymentHandle;
    final net = balance?.netMinor ?? 0;
    final dao = ref.read(ledgerDaoProvider);
    final sb = context.sb;
    final netColor = net > 0
        ? sb.owedToMe
        : net < 0
        ? sb.iOwe
        : sb.textSecondary;

    return Scaffold(
      appBar: AppBar(title: Text(friend.name)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
        children: [
          BentoCard(
            child: Row(
              children: [
                FriendAvatar(friend.name, size: 56),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SbLabel(
                        net > 0
                            ? 'Owes you'
                            : net < 0
                            ? 'You owe'
                            : 'All square',
                        color: netColor,
                      ),
                      const SizedBox(height: 4),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          fmt(net.abs()),
                          key: const Key('friend-net'),
                          style: SbType.hero.copyWith(color: sb.textPrimary),
                        ),
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () => _editHandle(context, ref, handle),
                        child: Row(
                          children: [
                            Icon(
                              Icons.alternate_email_rounded,
                              size: 16,
                              color: sb.textMuted,
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                handle ?? 'Add UPI ID / Venmo',
                                overflow: TextOverflow.ellipsis,
                                style: SbType.receipt.copyWith(
                                  color: handle == null
                                      ? sb.accent
                                      : sb.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (net > 0) ...[
            FilledButton.icon(
              key: const Key('open-nudge'),
              onPressed: () => showNudgeStudio(
                context,
                friend: balance!.friend,
                openSplits: open,
                initialTone: NudgeComposer.isDigestWindow(today)
                    ? NudgeTone.digest
                    : NudgeTone.polite,
              ),
              icon: const Icon(Icons.mark_chat_unread_outlined),
              label: const Text('Nudge (nicely)'),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: () => _settleAll(context, ref, fmt),
              child: Text('They paid me ${fmt(net)}'),
            ),
          ],
          if (net < 0) ...[
            if (handle != null && SettleLinks.railOf(handle) != null)
              FilledButton.icon(
                key: const Key('pay-now'),
                onPressed: () => _payNow(
                  context,
                  ref,
                  handle: handle,
                  amountMinor: -net,
                  fmt: fmt,
                ),
                icon: const Icon(Icons.bolt),
                label: Text(
                  'Pay ${fmt(-net)} via ${SettleLinks.railOf(handle) == PaymentRail.upi ? 'UPI' : 'Venmo'}',
                ),
              )
            else
              Text(
                'Add their UPI ID or Venmo handle above to pay in one tap.',
                style: TextStyle(color: sb.textSecondary),
              ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: () => _settleAll(context, ref, fmt),
              child: Text('I paid ${fmt(-net)} already'),
            ),
          ],
          const SectionHeader('Open IOUs'),
          if (open.isEmpty)
            const EmptyNote(
              'Nothing open. Friendship intact.',
              icon: Icons.handshake_outlined,
            ),
          for (final s in open)
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              value: false,
              title: Text(
                s.merchant,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                '${relativeDay(s.loggedAt, today)} · '
                '${s.direction == SplitDirection.owesMe ? 'owes you' : 'you owe'}',
                style: TextStyle(color: sb.textSecondary),
              ),
              secondary: Text(
                fmt(s.amountMinor),
                style: SbType.amount.copyWith(
                  color: s.direction == SplitDirection.owesMe
                      ? sb.owedToMe
                      : sb.iOwe,
                ),
              ),
              onChanged: (_) =>
                  dao.settleSplit(s.splitId, at: ref.read(clockProvider)()),
            ),
        ],
      ),
    );
  }
}
