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
    final parsed = _parsed;
    final symbol = ref.watch(currencySymbolProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          key: const Key('command-bar'),
          controller: _controller,
          focusNode: _focus,
          textInputAction: TextInputAction.done,
          decoration: const InputDecoration(
            hintText: 'Spent 450 on Domino\'s with Rahul and Priya',
            prefixIcon: Icon(Icons.bolt, color: SbColors.lime),
          ),
          onChanged: (text) =>
              setState(() => _parsed = ExpensePhraseParser.parse(text)),
          onSubmitted: (_) => _log(),
        ),
        if (parsed != null) ...[
          const SizedBox(height: 10),
          BrutalCard(
            key: const Key('command-preview'),
            shadowColor: parsed.category.color,
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(parsed.category.icon, color: parsed.category.color),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        parsed.merchant,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    Text(
                      Money.format(parsed.amountMinor, symbol: symbol),
                      style: SbType.figure,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  _describe(parsed, symbol),
                  style: const TextStyle(color: SbColors.muted),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton(
                        key: const Key('command-log'),
                        onPressed: _saving ? null : _log,
                        child: const Text('LOG IT'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    OutlinedButton(
                      onPressed: _editSplit,
                      child: const Text('EDIT SPLIT'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  String _describe(ParsedExpense p, String symbol) {
    final category = p.category.code;
    if (p.friends.isEmpty) return '$category · just you';
    final draft = p.toDraft(
      resolveFriend: (n) => FriendRef(id: n, name: n),
    );
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
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final c in TxnCategory.values)
          ChoiceChip(
            avatar: Icon(
              c.icon,
              size: 16,
              color: c == value ? SbColors.ink : c.color,
            ),
            label: Text(c.code),
            selected: c == value,
            showCheckmark: false,
            labelStyle: TextStyle(
              color: c == value ? SbColors.ink : SbColors.paper,
              fontWeight: FontWeight.w800,
            ),
            onSelected: (_) => onChanged(c),
          ),
      ],
    );
  }
}
