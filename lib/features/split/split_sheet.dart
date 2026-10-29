import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/money.dart';
import '../../core/providers/database_providers.dart';
import '../../core/providers/engine_providers.dart';
import '../../domain/category_classifier.dart';
import '../../domain/expense_draft.dart';
import '../../ui/prompts.dart';
import '../../ui/theme.dart';
import '../../ui/widgets.dart';
import '../dashboard/command_bar.dart';
import '../friends/friend_directory.dart';
import 'receipt_parser.dart';
import 'receipt_scanner.dart';
import 'split_builder.dart';

/// Opens the split & receipt scanner modal. Resolves to true when saved.
/// With [resplitTransactionId] it replaces that transaction's split.
Future<bool> showSplitSheet(
  BuildContext context, {
  SplitForm? initial,
  String? resplitTransactionId,
}) async {
  final saved = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => SplitSheet(
      initial: initial ?? const SplitForm(),
      resplitTransactionId: resplitTransactionId,
    ),
  );
  return saved ?? false;
}

String participantName(Participant p) => switch (p) {
  Me() => 'You',
  FriendParticipant(:final friend) => friend.name,
};

class SplitSheet extends ConsumerStatefulWidget {
  const SplitSheet({
    super.key,
    required this.initial,
    this.resplitTransactionId,
  });

  final SplitForm initial;
  final String? resplitTransactionId;

  @override
  ConsumerState<SplitSheet> createState() => _SplitSheetState();
}

class _SplitSheetState extends ConsumerState<SplitSheet> {
  late SplitForm _form = widget.initial;
  late final _amount = TextEditingController(
    text: moneyFieldText(widget.initial.totalMinor),
  );
  late final _merchant = TextEditingController(text: widget.initial.merchant);
  late final _extras = TextEditingController(
    text: moneyFieldText(widget.initial.receiptExtrasMinor),
  );
  final _exact = <Participant, TextEditingController>{};
  final _percent = <Participant, TextEditingController>{};
  String? _receiptImagePath;
  bool _scanning = false;
  bool _saving = false;
  bool _categoryTouched = false;

  @override
  void dispose() {
    for (final c in [
      _amount,
      _merchant,
      _extras,
      ..._exact.values,
      ..._percent.values,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _update(SplitForm form) => setState(() => _form = form);

  TextEditingController _exactFor(Participant p) => _exact.putIfAbsent(
    p,
    () => TextEditingController(text: moneyFieldText(_form.exactMinor[p] ?? 0)),
  );

  TextEditingController _percentFor(Participant p) => _percent.putIfAbsent(
    p,
    () {
      final bp = _form.basisPoints[p];
      return TextEditingController(text: bp == null ? '' : _formatPercent(bp));
    },
  );

  static String _formatPercent(int bp) =>
      bp % 100 == 0 ? '${bp ~/ 100}' : (bp / 100).toStringAsFixed(2);

  static int? _parsePercent(String text) {
    final match = RegExp(r'^(\d{1,3})(?:\.(\d{0,2}))?$')
        .firstMatch(text.trim());
    if (match == null) return null;
    return int.parse(match[1]!) * 100 +
        int.parse((match[2] ?? '').padRight(2, '0'));
  }

  void _fillEvenPercent() {
    final people = _form.participants;
    final each = 10000 ~/ people.length;
    final extra = 10000 - each * people.length;
    final bps = <Participant, int>{
      for (var i = 0; i < people.length; i++)
        people[i]: each + (i < extra ? 1 : 0),
    };
    for (final MapEntry(key: p, value: bp) in bps.entries) {
      _percentFor(p).text = _formatPercent(bp);
    }
    _update(_form.copyWith(basisPoints: bps));
  }

  Future<void> _addFriend() async {
    final directory =
        ref.read(friendDirectoryProvider).value ?? FriendDirectory(const []);
    final name = await promptFriendName(context, directory: directory);
    if (name == null || name.trim().isEmpty) return;
    final friend = FriendParticipant(directory.resolve(name));
    if (_form.participants.contains(friend)) return;
    _update(_form.copyWith(participants: [..._form.participants, friend]));
  }

  Future<void> _scan({required bool fromCamera}) async {
    setState(() => _scanning = true);
    try {
      final scanned = await ref
          .read(receiptScannerProvider)
          .scan(fromCamera: fromCamera);
      if (scanned == null || !mounted) return;
      final receipt = scanned.receipt;
      if (receipt.items.isEmpty) {
        showSnack(
          context,
          'Couldn\'t read any items. Try a flatter, brighter photo.',
        );
        return;
      }
      _receiptImagePath = scanned.imagePath;
      if (_merchant.text.trim().isEmpty && receipt.merchant != null) {
        _merchant.text = receipt.merchant!;
      }
      _extras.text = moneyFieldText(receipt.extrasMinor);
      _update(
        _form.copyWith(
          merchant: _merchant.text,
          claimedItems: [
            for (final item in receipt.items)
              ClaimedItem(item: item, claimedBy: {..._form.participants}),
          ],
          receiptExtrasMinor: receipt.extrasMinor,
        ),
      );
    } on PlatformException catch (e) {
      if (mounted) {
        showSnack(context, 'Scanner unavailable: ${e.message ?? e.code}');
      }
    } finally {
      if (mounted) setState(() => _scanning = false);
    }
  }

  Future<void> _addItem() async {
    final item = await showDialog<ReceiptItem>(
      context: context,
      builder: (context) => const _AddItemDialog(),
    );
    if (item == null) return;
    _update(
      _form.copyWith(
        claimedItems: [
          ..._form.claimedItems,
          ClaimedItem(item: item, claimedBy: {..._form.participants}),
        ],
      ),
    );
  }

  Future<void> _save(SplitReady ready) async {
    setState(() => _saving = true);
    try {
      final dao = ref.read(ledgerDaoProvider);
      final id = widget.resplitTransactionId;
      if (id != null) {
        await dao.resplitTransaction(id, ready.draft);
      } else {
        final outcome = _form.build(
          createdAt: ref.read(clockProvider)(),
          receiptImagePath: _receiptImagePath,
        );
        await dao.logExpense((outcome as SplitReady).draft);
      }
      if (mounted) Navigator.pop(context, true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final symbol = ref.watch(currencySymbolProvider);
    final outcome = _form.build();
    String fmt(int v) => Money.format(v, symbol: symbol);

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.resplitTransactionId == null ? 'SPLIT A BILL' : 'RE-SPLIT',
              style: Theme.of(context).appBarTheme.titleTextStyle,
            ),
            const SizedBox(height: 14),
            SegmentedButton<SplitMode>(
              key: const Key('split-mode'),
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: SplitMode.equal, label: Text('Equal')),
                ButtonSegment(value: SplitMode.exact, label: Text('Exact')),
                ButtonSegment(value: SplitMode.percentage, label: Text('%')),
                ButtonSegment(value: SplitMode.receipt, label: Text('Receipt')),
              ],
              selected: {_form.mode},
              onSelectionChanged: (s) =>
                  _update(_form.copyWith(mode: s.single)),
            ),
            const SizedBox(height: 14),
            if (_form.mode != SplitMode.receipt) ...[
              TextField(
                key: const Key('split-amount'),
                controller: _amount,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: moneyInputFormatters,
                style: SbType.figure,
                decoration: InputDecoration(
                  labelText: 'Total bill',
                  prefixText: '$symbol ',
                ),
                onChanged: (t) => _update(
                  _form.copyWith(totalMinor: parseMoneyInput(t) ?? 0),
                ),
              ),
              const SizedBox(height: 10),
            ],
            TextField(
              key: const Key('split-merchant'),
              controller: _merchant,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'What was it?'),
              onChanged: (t) {
                var next = _form.copyWith(merchant: t);
                if (!_categoryTouched) {
                  final guess = CategoryClassifier.classify(t);
                  next = next.copyWith(category: guess);
                }
                _update(next);
              },
            ),
            const SizedBox(height: 12),
            CategoryPicker(
              value: _form.category,
              onChanged: (c) {
                _categoryTouched = true;
                _update(_form.copyWith(category: c));
              },
            ),
            const SectionHeader('Who\'s in'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final p in _form.participants)
                  if (p is Me)
                    const Chip(label: Text('You'))
                  else
                    InputChip(
                      label: Text(participantName(p)),
                      onDeleted: () => _update(
                        _form.copyWith(
                          participants: [..._form.participants]..remove(p),
                        ),
                      ),
                    ),
                ActionChip(
                  key: const Key('add-friend'),
                  avatar: const Icon(Icons.person_add_alt_1, size: 16),
                  label: const Text('Add friend'),
                  onPressed: _addFriend,
                ),
              ],
            ),
            if (_form.participants.length > 1) ...[
              const SectionHeader('Who paid'),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final p in _form.participants)
                    ChoiceChip(
                      label: Text(participantName(p)),
                      selected: _form.payer == p,
                      showCheckmark: false,
                      labelStyle: TextStyle(
                        color: _form.payer == p ? SbColors.ink : SbColors.paper,
                        fontWeight: FontWeight.w800,
                      ),
                      onSelected: (_) => _update(_form.copyWith(payer: p)),
                    ),
                ],
              ),
            ],
            const SectionHeader('Shares'),
            ..._modeBody(outcome, fmt, symbol),
            const SizedBox(height: 16),
            if (outcome is SplitInvalid)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  outcome.remainingMinor == null
                      ? outcome.message
                      : '${outcome.message} '
                            '(${_form.mode == SplitMode.percentage ? '${_formatPercent(outcome.remainingMinor!.abs())}%' : fmt(outcome.remainingMinor!.abs())} '
                            '${outcome.remainingMinor! > 0 ? 'left' : 'over'})',
                  key: const Key('split-error'),
                  style: const TextStyle(
                    color: SbColors.magma,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            if (outcome is SplitReady) _Summary(ready: outcome, fmt: fmt),
            const SizedBox(height: 12),
            FilledButton(
              key: const Key('split-save'),
              onPressed: outcome is SplitReady && !_saving
                  ? () => _save(outcome)
                  : null,
              child: Text(
                widget.resplitTransactionId == null
                    ? 'SAVE SPLIT'
                    : 'UPDATE SPLIT',
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _modeBody(
    SplitOutcome outcome,
    String Function(int) fmt,
    String symbol,
  ) {
    final allocation = outcome is SplitReady
        ? outcome.allocation
        : const <Participant, int>{};
    switch (_form.mode) {
      case SplitMode.equal:
        return [
          for (final p in _form.participants)
            _ShareRow(
              name: participantName(p),
              value: allocation[p] == null ? '—' : fmt(allocation[p]!),
            ),
        ];
      case SplitMode.exact:
        return [
          for (final p in _form.participants)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: TextField(
                key: Key('exact-${participantName(p)}'),
                controller: _exactFor(p),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: moneyInputFormatters,
                decoration: InputDecoration(
                  labelText: participantName(p),
                  prefixText: '$symbol ',
                ),
                onChanged: (t) => _update(
                  _form.copyWith(
                    exactMinor: {
                      ..._form.exactMinor,
                      p: parseMoneyInput(t) ?? 0,
                    },
                  ),
                ),
              ),
            ),
        ];
      case SplitMode.percentage:
        return [
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _fillEvenPercent,
              child: const Text('EVEN SPLIT'),
            ),
          ),
          for (final p in _form.participants)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: TextField(
                controller: _percentFor(p),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                ],
                decoration: InputDecoration(
                  labelText: participantName(p),
                  suffixText: allocation[p] == null
                      ? '%'
                      : '%  ·  ${fmt(allocation[p]!)}',
                ),
                onChanged: (t) => _update(
                  _form.copyWith(
                    basisPoints: {
                      ..._form.basisPoints,
                      p: _parsePercent(t) ?? 0,
                    },
                  ),
                ),
              ),
            ),
        ];
      case SplitMode.receipt:
        return [
          Row(
            children: [
              if (!kIsWeb) ...[
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _scanning ? null : () => _scan(fromCamera: true),
                    icon: const Icon(Icons.document_scanner_outlined),
                    label: Text(_scanning ? 'READING…' : 'SCAN'),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: _scanning ? null : () => _scan(fromCamera: false),
                  child: const Icon(Icons.photo_library_outlined),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _addItem,
                  icon: const Icon(Icons.add),
                  label: const Text('ITEM'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_form.claimedItems.isEmpty)
            const EmptyNote(
              'Scan the bill, then tap who had what.',
              icon: Icons.receipt_outlined,
            ),
          for (var i = 0; i < _form.claimedItems.length; i++)
            _ClaimRow(
              claim: _form.claimedItems[i],
              people: _form.participants,
              price: fmt(_form.claimedItems[i].item.priceMinor),
              onToggle: (p) {
                final items = [..._form.claimedItems];
                items[i] = items[i].toggle(p);
                _update(_form.copyWith(claimedItems: items));
              },
              onRemove: () => _update(
                _form.copyWith(
                  claimedItems: [..._form.claimedItems]..removeAt(i),
                ),
              ),
            ),
          if (_form.claimedItems.isNotEmpty) ...[
            const SizedBox(height: 8),
            TextField(
              controller: _extras,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
                signed: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,-]')),
              ],
              decoration: InputDecoration(
                labelText: 'Tax + tip + service − discount',
                helperText: 'Spread in proportion to what each person had',
                prefixText: '$symbol ',
              ),
              onChanged: (t) {
                final negative = t.trim().startsWith('-');
                final value = parseMoneyInput(t.replaceAll('-', '')) ?? 0;
                _update(
                  _form.copyWith(receiptExtrasMinor: negative ? -value : value),
                );
              },
            ),
            const SizedBox(height: 8),
            _ShareRow(
              name: 'Bill total',
              value: fmt(_form.receiptTotalMinor),
              bold: true,
            ),
            for (final p in _form.participants)
              _ShareRow(
                name: participantName(p),
                value: allocation[p] == null ? '—' : fmt(allocation[p]!),
              ),
          ],
        ];
    }
  }
}

class _ShareRow extends StatelessWidget {
  const _ShareRow({required this.name, required this.value, this.bold = false});

  final String name;
  final String value;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontWeight: bold ? FontWeight.w900 : FontWeight.w600,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(name, style: style)),
          Text(
            value,
            style: style.copyWith(
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _ClaimRow extends StatelessWidget {
  const _ClaimRow({
    required this.claim,
    required this.people,
    required this.price,
    required this.onToggle,
    required this.onRemove,
  });

  final ClaimedItem claim;
  final List<Participant> people;
  final String price;
  final ValueChanged<Participant> onToggle;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border.all(
          color: claim.claimedBy.isEmpty ? SbColors.magma : SbColors.raised,
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  claim.item.label,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              Text(price, style: const TextStyle(fontWeight: FontWeight.w800)),
              IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: onRemove,
                icon: const Icon(Icons.close, size: 18),
                tooltip: 'Remove item',
              ),
            ],
          ),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final p in people)
                FilterChip(
                  label: Text(participantName(p)),
                  selected: claim.claimedBy.contains(p),
                  labelStyle: TextStyle(
                    color: claim.claimedBy.contains(p)
                        ? SbColors.ink
                        : SbColors.paper,
                    fontWeight: FontWeight.w700,
                  ),
                  onSelected: (_) => onToggle(p),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.ready, required this.fmt});

  final SplitReady ready;
  final String Function(int) fmt;

  @override
  Widget build(BuildContext context) {
    final draft = ready.draft;
    final text = switch (draft.payer) {
      PaidByMe() when draft.friendShares.isEmpty =>
        'Just you: ${fmt(draft.myShareMinor)} on your budget.',
      PaidByMe() =>
        'You pay ${fmt(draft.totalPaidMinor)} now. Only your ${fmt(draft.myShareMinor)} counts '
            'as spending; ${fmt(draft.frontedForOthersMinor)} comes back from friends.',
      PaidByFriend(:final friend) =>
        '${friend.name} paid. You owe them ${fmt(draft.myShareMinor)}; your bank isn\'t touched yet.',
    };
    return BrutalCard(
      key: const Key('split-summary'),
      color: SbColors.raised,
      shadowColor: SbColors.owed,
      padding: const EdgeInsets.all(12),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.w700, height: 1.3),
      ),
    );
  }
}

class _AddItemDialog extends StatefulWidget {
  const _AddItemDialog();

  @override
  State<_AddItemDialog> createState() => _AddItemDialogState();
}

class _AddItemDialogState extends State<_AddItemDialog> {
  final _label = TextEditingController();
  final _price = TextEditingController();

  @override
  void dispose() {
    _label.dispose();
    _price.dispose();
    super.dispose();
  }

  void _submit() {
    final price = parseMoneyInput(_price.text);
    if (_label.text.trim().isEmpty || price == null || price <= 0) return;
    Navigator.pop(
      context,
      ReceiptItem(label: _label.text.trim(), priceMinor: price),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add an item'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _label,
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(labelText: 'Item'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _price,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: moneyInputFormatters,
            decoration: const InputDecoration(labelText: 'Price'),
            onSubmitted: (_) => _submit(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: const Text('ADD')),
      ],
    );
  }
}
