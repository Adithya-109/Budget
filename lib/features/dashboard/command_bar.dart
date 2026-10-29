import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/enums.dart';
import '../../core/money.dart';
import '../../core/providers/database_providers.dart';
import '../../core/providers/engine_providers.dart';
import '../../domain/expense_draft.dart';
import '../../domain/expense_phrase_parser.dart';
import '../../ui/category_style.dart';
import '../../ui/theme.dart';
import '../../ui/widgets.dart';
import '../friends/friend_directory.dart';
import '../split/split_builder.dart';
import '../split/split_sheet.dart';

/// Builds an editable split form from a parsed phrase.
SplitForm splitFormFromPhrase(ParsedExpense parsed, FriendDirectory directory) {
  final friends = [
    for (final name in parsed.friends)
      FriendParticipant(directory.resolve(name)),
  ];
  final payer = parsed.payer == null
      ? const Me()
      : FriendParticipant(directory.resolve(parsed.payer!));
  return SplitForm(
    merchant: parsed.merchant,
    totalMinor: parsed.amountMinor,
    category: parsed.category,
    participants: [const Me(), ...friends],
    payer: payer,
  );
}

/// "Spent 450 on Domino's with Rahul and Priya" → one tap to log.
class CommandBar extends ConsumerStatefulWidget {
  const CommandBar({super.key});

  @override
  ConsumerState<CommandBar> createState() => _CommandBarState();
}

class _CommandBarState extends ConsumerState<CommandBar> {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  ParsedExpense? _parsed;
  bool _saving = false;

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  FriendDirectory get _directory =>
      ref.read(friendDirectoryProvider).value ?? FriendDirectory(const []);

  Future<void> _log() async {
    final parsed = _parsed;
    if (parsed == null || _saving) return;
    setState(() => _saving = true);
    try {
      final draft = parsed.toDraft(
        resolveFriend: _directory.resolve,
        createdAt: ref.read(clockProvider)(),
      );
      final dao = ref.read(ledgerDaoProvider);
      final id = await dao.logExpense(draft);
      if (!mounted) return;
      _controller.clear();
      _focus.unfocus();
      setState(() => _parsed = null);
      final symbol = ref.read(currencySymbolProvider);
      showSnack(
        context,
        'Logged ${Money.format(draft.totalPaidMinor, symbol: symbol)} at ${draft.merchant}'
        '${draft.myShareMinor != draft.totalPaidMinor ? ' (your share ${Money.format(draft.myShareMinor, symbol: symbol)})' : ''}',
        action: SnackBarAction(
          label: 'UNDO',
          onPressed: () => dao.deleteTransaction(id),
        ),
      );
    } on ArgumentError catch (e) {
      if (mounted) showSnack(context, '${e.message}');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _editSplit() async {
    final parsed = _parsed;
    if (parsed == null) return;
    final saved = await showSplitSheet(
      context,
      initial: splitFormFromPhrase(parsed, _directory),
    );
    if (saved && mounted) {
      _controller.clear();
      setState(() => _parsed = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sb = context.sb;
    final parsed = _parsed;
    final symbol = ref.watch(currencySymbolProvider);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          alignment: Alignment.bottomCenter,
          child: parsed == null
              ? const SizedBox(width: double.infinity)
              : Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _Preview(
                    parsed: parsed,
                    description: _describe(parsed, symbol),
                    symbol: symbol,
                    saving: _saving,
                    onLog: _log,
                    onEdit: _editSplit,
                  ),
                ),
        ),
        GlassCard(
          radius: SbRadius.pill,
          padding: const EdgeInsets.fromLTRB(16, 4, 6, 4),
          child: Row(
            children: [
              Icon(Icons.bolt_rounded, color: sb.safeMint),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  key: const Key('command-bar'),
                  controller: _controller,
                  focusNode: _focus,
                  textInputAction: TextInputAction.done,
                  style: SbType.body.copyWith(color: sb.textPrimary),
                  decoration: const InputDecoration(
                    hintText: "450 on Domino's with Rahul and Priya",
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 12),
                  ),
                  onChanged: (text) =>
                      setState(() => _parsed = ExpensePhraseParser.parse(text)),
                  onSubmitted: (_) => _log(),
                ),
              ),
              IconButton(
                key: const Key('command-scan'),
                tooltip: 'Scan a receipt',
                onPressed: () => showSplitSheet(
                  context,
                  initial: const SplitForm(mode: SplitMode.receipt),
                ),
                icon: Icon(
                  Icons.document_scanner_outlined,
                  color: sb.textSecondary,
                ),
              ),
              IconButton.filled(
                key: const Key('add-expense'),
                tooltip: 'Split a bill',
                onPressed: () => showSplitSheet(context),
                icon: const Icon(Icons.add_rounded),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _describe(ParsedExpense p, String symbol) {
    final category = p.category.code;
    if (p.friends.isEmpty) return '$category · just you';
    final ExpenseDraft draft;
    try {
      draft = p.toDraft(
        resolveFriend: (n) => FriendRef(id: n, name: n),
      );
    } on ArgumentError catch (e) {
      // e.g. "Rahul paid 0.01 with Priya": too small to give you a share.
      return '$category · ${e.message}';
    }
    final share = Money.format(draft.myShareMinor, symbol: symbol);
    if (p.payer != null) return '$category · ${p.payer} paid · you owe $share';
    return '$category · split ${p.friends.length + 1} ways · $share each · '
        '${p.friends.join(', ')} owe you';
  }
}

/// Category chips used by the split and bill sheets.
class CategoryPicker extends StatelessWidget {
  const CategoryPicker({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final TxnCategory value;
  final ValueChanged<TxnCategory> onChanged;

  @override
  Widget build(BuildContext context) {
    final sb = context.sb;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final c in TxnCategory.values)
          ChoiceChip(
            avatar: Icon(
              c.icon,
              size: 16,
              color: c == value ? sb.onAccent : c.colorIn(sb),
            ),
            label: Text(c.code),
            selected: c == value,
            onSelected: (_) => onChanged(c),
          ),
      ],
    );
  }
}

/// What the phrase will log, with Log it / Edit split.
class _Preview extends StatelessWidget {
  const _Preview({
    required this.parsed,
    required this.description,
    required this.symbol,
    required this.saving,
    required this.onLog,
    required this.onEdit,
  });

  final ParsedExpense parsed;
  final String description;
  final String symbol;
  final bool saving;
  final VoidCallback onLog;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final sb = context.sb;
    final color = parsed.category.colorIn(sb);
    return BentoCard(
      key: const Key('command-preview'),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(parsed.category.icon, color: color, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  parsed.merchant,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: SbType.body.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
              Text(
                Money.format(parsed.amountMinor, symbol: symbol),
                style: SbType.balance.copyWith(
                  fontSize: 20,
                  color: sb.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(description, style: TextStyle(color: sb.textSecondary)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  key: const Key('command-log'),
                  onPressed: saving ? null : onLog,
                  child: const Text('Log it'),
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton(
                onPressed: onEdit,
                child: const Text('Edit split'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
