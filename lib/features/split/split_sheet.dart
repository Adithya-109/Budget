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

  /// Receipt mode: the person whose avatar snaps onto the next tapped dish.
  Participant _active = const Me();

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
              widget.resplitTransactionId == null ? 'Split a bill' : 'Re-split',
              style: SbType.title.copyWith(color: context.sb.textPrimary),
            ),
            const SizedBox(height: 14),
            if (outcome case SplitReady(:final draft)
                when draft.paidByMe && draft.friendShares.isNotEmpty) ...[
              NetShareImpactBar(
                myShareMinor: draft.myShareMinor,
                floatingMinor: draft.frontedForOthersMinor,
                symbol: symbol,
              ),
              const SizedBox(height: 14),
            ],
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
                style: SbType.balance.copyWith(color: context.sb.textPrimary),
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
                      avatar: FriendAvatar(participantName(p), size: 22),
                      label: Text(participantName(p)),
                      selected: _form.payer == p,
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
                  style: TextStyle(
                    color: context.sb.iOwe,
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
                    ? 'Save split'
                    : 'Update split',
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
              child: const Text('Even split'),
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
                    label: Text(_scanning ? 'Reading…' : 'Scan'),
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
                  label: const Text('Item'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_form.claimedItems.isNotEmpty) ...[
            _AvatarDock(
              people: _form.participants,
              active: _form.participants.contains(_active)
                  ? _active
                  : const Me(),
              onSelect: (p) => setState(() => _active = p),
            ),
            const SizedBox(height: 10),
          ],
          if (_form.claimedItems.isEmpty)
            const EmptyNote(
              'Scan the bill, then tap who had what.',
              icon: Icons.receipt_outlined,
            ),
          for (var i = 0; i < _form.claimedItems.length; i++)
            _ClaimRow(
              key: Key('claim-$i'),
              claim: _form.claimedItems[i],
              people: _form.participants,
              fmt: fmt,
              onTap: () {
                final who = _form.participants.contains(_active)
                    ? _active
                    : const Me();
                HapticFeedback.lightImpact();
                final items = [..._form.claimedItems];
                items[i] = items[i].toggle(who);
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
    final sb = context.sb;
    final style = SbType.body.copyWith(
      fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
      color: sb.textPrimary,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          if (!bold) ...[
            FriendAvatar(name, size: 26),
            const SizedBox(width: 10),
          ],
          Expanded(child: Text(name, style: style)),
          Text(value, style: SbType.amount.copyWith(color: sb.textPrimary)),
        ],
      ),
    );
  }
}

/// "My share ₹320 (26%) | Floating friend IOUs ₹880 (74%)": what hits the
/// budget versus cash that comes back (DESIGN_SYSTEM §3 Page 2).
class NetShareImpactBar extends StatelessWidget {
  const NetShareImpactBar({
    super.key,
    required this.myShareMinor,
    required this.floatingMinor,
    required this.symbol,
  });

  final int myShareMinor;
  final int floatingMinor;
  final String symbol;

  @override
  Widget build(BuildContext context) {
    final sb = context.sb;
    final total = myShareMinor + floatingMinor;
    if (total <= 0) return const SizedBox.shrink();
    final mine = myShareMinor / total;
    final minePct = (mine * 100).round();
    String fmt(int v) => Money.format(v, symbol: symbol);
    final amber = sb.trialAmber;
    final onMint = context.isDark ? sb.canvas : Colors.white;
    return ClipRRect(
      key: const Key('net-share-bar'),
      borderRadius: BorderRadius.circular(SbRadius.row),
      child: SizedBox(
        height: 64,
        child: Row(
          children: [
            Expanded(
              flex: (mine * 1000).round().clamp(180, 820),
              child: ColoredBox(
                color: sb.safeMint,
                child: _BarLabel(
                  title: 'My share',
                  value: '${fmt(myShareMinor)} ($minePct%)',
                  color: onMint,
                  align: CrossAxisAlignment.start,
                ),
              ),
            ),
            Expanded(
              flex: ((1 - mine) * 1000).round().clamp(180, 820),
              child: CustomPaint(
                painter: _HatchPainter(
                  base: amber.withValues(alpha: 0.85),
                  stripe: amber,
                ),
                child: _BarLabel(
                  title: 'Floating IOUs',
                  value: '${fmt(floatingMinor)} (${100 - minePct}%)',
                  color: SplitBurnTokens.thermalInk,
                  align: CrossAxisAlignment.end,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BarLabel extends StatelessWidget {
  const _BarLabel({
    required this.title,
    required this.value,
    required this.color,
    required this.align,
  });

  final String title;
  final String value;
  final Color color;
  final CrossAxisAlignment align;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: align,
        children: [
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: SbType.chip.copyWith(color: color.withValues(alpha: 0.85)),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: SbType.amount.copyWith(color: color, fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }
}

/// Diagonal hatching for money that isn't really spent.
class _HatchPainter extends CustomPainter {
  _HatchPainter({required this.base, required this.stripe});

  final Color base;
  final Color stripe;

  @override
  void paint(Canvas canvas, Size size) {
    // Stripes start left of the box: clip so they never cover "My share".
    canvas.clipRect(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, Paint()..color = base);
    final paint = Paint()
      ..color = stripe
      ..strokeWidth = 5;
    for (var x = -size.height; x < size.width; x += 12) {
      canvas.drawLine(
        Offset(x, size.height),
        Offset(x + size.height, 0),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_HatchPainter old) =>
      old.base != base || old.stripe != stripe;
}

/// Magnetic avatar dock: pick a person, then tap the dishes they had.
class _AvatarDock extends StatelessWidget {
  const _AvatarDock({
    required this.people,
    required this.active,
    required this.onSelect,
  });

  final List<Participant> people;
  final Participant active;
  final ValueChanged<Participant> onSelect;

  @override
  Widget build(BuildContext context) {
    final sb = context.sb;
    return GlassCard(
      key: const Key('avatar-dock'),
      radius: SbRadius.pill,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final p in people)
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: GestureDetector(
                        key: Key('dock-${participantName(p)}'),
                        onTap: () {
                          HapticFeedback.selectionClick();
                          onSelect(p);
                        },
                        child: AnimatedScale(
                          scale: p == active ? 1.12 : 1,
                          duration: const Duration(milliseconds: 160),
                          child: FriendAvatar(
                            participantName(p),
                            size: 34,
                            ring: p == active ? sb.accent : null,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            'tap dishes for ${participantName(active)}',
            style: SbType.chip.copyWith(color: sb.textSecondary),
          ),
        ],
      ),
    );
  }
}

/// A receipt line as a Bento card: dish, price, who had it and each share.
class _ClaimRow extends StatelessWidget {
  const _ClaimRow({
    super.key,
    required this.claim,
    required this.people,
    required this.fmt,
    required this.onTap,
    required this.onRemove,
  });

  final ClaimedItem claim;
  final List<Participant> people;
  final String Function(int) fmt;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final sb = context.sb;
    final eaters = [
      for (final p in people)
        if (claim.claimedBy.contains(p)) participantName(p),
    ];
    final unclaimed = eaters.isEmpty;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: BentoCard(
        onTap: onTap,
        radius: SbRadius.row,
        padding: const EdgeInsets.fromLTRB(14, 10, 4, 10),
        borderColor: unclaimed ? sb.iOwe : null,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${claim.item.label} · ${fmt(claim.item.priceMinor)}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: SbType.body.copyWith(
                      fontWeight: FontWeight.w600,
                      color: sb.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    unclaimed
                        ? 'Nobody yet: tap to add'
                        : eaters.length == 1
                        ? eaters.single
                        : '${fmt(claim.item.priceMinor ~/ eaters.length)} each · ${eaters.length} people',
                    style: SbType.receipt.copyWith(
                      fontSize: 12,
                      color: unclaimed ? sb.iOwe : sb.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            AvatarStack(eaters, size: 28),
            IconButton(
              visualDensity: VisualDensity.compact,
              onPressed: onRemove,
              icon: Icon(Icons.close_rounded, size: 18, color: sb.textMuted),
              tooltip: 'Remove item',
            ),
          ],
        ),
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
    final sb = context.sb;
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
    return BentoCard(
      key: const Key('split-summary'),
      color: sb.surfaceElevated,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, color: sb.safeMint, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                height: 1.35,
                color: sb.textPrimary,
              ),
            ),
          ),
        ],
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
        FilledButton(onPressed: _submit, child: const Text('Add')),
      ],
    );
  }
}
