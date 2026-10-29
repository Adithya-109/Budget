import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/money.dart';
import '../../core/providers/database_providers.dart';
import '../../core/providers/engine_providers.dart';
import '../../core/providers/native_providers.dart';
import '../../ui/prompts.dart';
import '../../ui/theme.dart';
import '../../ui/widgets.dart';
import '../bills/trial_reminders.dart';
import '../ledger/settle_links.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(budgetSettingsProvider).value;
    final balance = ref.watch(trueLiquidBalanceProvider).value;
    if (config == null || balance == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final symbol = config.currencySymbol;
    String fmt(int v) => Money.format(v, symbol: symbol);
    final budget = ref.read(budgetDaoProvider);
    final bridge = ref.watch(nativeBridgeProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('SETTINGS')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
        children: [
          const SectionHeader('Your money'),
          ListTile(
            key: const Key('setting-allowance'),
            contentPadding: EdgeInsets.zero,
            title: const Text('Monthly allowance'),
            subtitle: const Text('Pocket money, stipend or salary per cycle'),
            trailing: Text(
              fmt(Money.toMinor(config.monthlyAllowance)),
              style: SbType.figure,
            ),
            onTap: () async {
              final v = await _askMoney(
                context,
                'Monthly allowance',
                Money.toMinor(config.monthlyAllowance),
                symbol,
              );
              if (v != null) {
                await budget.updateSettings(monthlyAllowanceMinor: v);
              }
            },
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Allowance arrives on'),
            subtitle: const Text('Your cycle resets on this day'),
            trailing: DropdownButton<int>(
              value: config.cycleResetDay,
              underline: const SizedBox.shrink(),
              items: [
                for (var d = 1; d <= 31; d++)
                  DropdownMenuItem(value: d, child: Text(_ordinal(d))),
              ],
              onChanged: (d) =>
                  d == null ? null : budget.updateSettings(cycleResetDay: d),
            ),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Currency'),
            trailing: SegmentedButton<String>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: '₹', label: Text('₹')),
                ButtonSegment(value: r'$', label: Text(r'$')),
              ],
              selected: {symbol},
              onSelectionChanged: (s) =>
                  budget.updateSettings(currencySymbol: s.single),
            ),
          ),
          const SectionHeader('Bank balance'),
          BrutalCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fmt(balance.bankBalanceMinor),
                  style: SbType.figure.copyWith(fontSize: 28),
                ),
                const SizedBox(height: 4),
                const Text(
                  'What SplitBurn thinks is in your bank',
                  style: TextStyle(color: SbColors.muted),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  key: const Key('reconcile'),
                  onPressed: () => _reconcile(
                    context,
                    ref,
                    balance.bankBalanceMinor,
                    symbol,
                  ),
                  child: const Text('MATCH MY BANK APP'),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: () async {
                    final v = await _askMoney(
                      context,
                      'Money that came in',
                      0,
                      symbol,
                      help: 'Allowance, stipend, pocket money. Not friends paying you back.',
                    );
                    if (v != null && v > 0) await budget.recordIncome(v);
                  },
                  child: const Text('MONEY CAME IN'),
                ),
              ],
            ),
          ),
          const SectionHeader('You, on shared links'),
          _OwnerFields(
            name: config.ownerName,
            handle: config.ownerPaymentHandle,
          ),
          const SectionHeader('Automation'),
          if (bridge.supportsUpiCapture)
            _UpiCaptureTile()
          else
            const ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.touch_app_outlined),
              title: Text('Log from Apple Pay or the Action Button'),
              subtitle: Text(
                'Shortcuts → Automation → Transaction → "Log Split Expense" with Amount and Merchant. '
                'Or ask Siri: "Log a split in SplitBurn".',
              ),
            ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.shield_outlined),
            title: const Text('Free Trial Shield alerts'),
            subtitle: const Text(
              'Allow notifications so trials can\'t sneak a charge',
            ),
            onTap: () async {
              final ok = await ref
                  .read(trialReminderSchedulerProvider)
                  .requestPermission();
              if (context.mounted) {
                showSnack(
                  context,
                  ok ? 'Trial alerts are on.' : 'Turn on notifications for SplitBurn in system settings.',
                );
              }
            },
          ),
        ],
      ),
    );
  }

  static String _ordinal(int d) {
    if (d >= 11 && d <= 13) return '${d}th';
    return switch (d % 10) {
      1 => '${d}st',
      2 => '${d}nd',
      3 => '${d}rd',
      _ => '${d}th',
    };
  }

  Future<void> _reconcile(
    BuildContext context,
    WidgetRef ref,
    int current,
    String symbol,
  ) async {
    final answer = await showDialog<(int, bool)>(
      context: context,
      builder: (_) => _ReconcileDialog(currentMinor: current, symbol: symbol),
    );
    if (answer == null) return;
    final (actual, countAsSpend) = answer;
    final result = await ref
        .read(balanceReconcilerProvider.notifier)
        .reconcile(actual, logShortfallAsSpend: countAsSpend);
    if (!context.mounted) return;
    final delta = result.deltaMinor;
    String fmt(int v) => Money.format(v, symbol: symbol);
    showSnack(
      context,
      delta == 0
          ? 'Already matching. Nice bookkeeping.'
          : delta > 0
          ? 'Balance up by ${fmt(delta)}.'
          : result.untrackedSpendTransactionId != null
          ? 'Logged ${fmt(-delta)} of untracked spending.'
          : 'Balance corrected by ${fmt(-delta)}.',
    );
  }

  Future<int?> _askMoney(
    BuildContext context,
    String title,
    int initial,
    String symbol, {
    String? help,
  }) => promptMoney(
    context,
    title: title,
    symbol: symbol,
    initialMinor: initial,
    help: help,
  );
}

/// "What does your bank app show?" Resolves to (balance, count gap as spend).
class _ReconcileDialog extends StatefulWidget {
  const _ReconcileDialog({required this.currentMinor, required this.symbol});

  final int currentMinor;
  final String symbol;

  @override
  State<_ReconcileDialog> createState() => _ReconcileDialogState();
}

class _ReconcileDialogState extends State<_ReconcileDialog> {
  late final _controller = TextEditingController(
    text: moneyFieldText(widget.currentMinor),
  );
  bool _countAsSpend = true;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final value = parseMoneyInput(_controller.text);
    if (value != null) Navigator.pop(context, (value, _countAsSpend));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('What does your bank app show?'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              key: const Key('reconcile-amount'),
              controller: _controller,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: moneyInputFormatters,
              decoration: InputDecoration(prefixText: '${widget.symbol} '),
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'If it\'s lower, count the gap as spending '
                    '(probably stuff you forgot to log)',
                  ),
                ),
                Switch(
                  value: _countAsSpend,
                  onChanged: (v) => setState(() => _countAsSpend = v),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: const Text('MATCH')),
      ],
    );
  }
}

class _OwnerFields extends ConsumerStatefulWidget {
  const _OwnerFields({required this.name, required this.handle});

  final String? name;
  final String? handle;

  @override
  ConsumerState<_OwnerFields> createState() => _OwnerFieldsState();
}

class _OwnerFieldsState extends ConsumerState<_OwnerFields> {
  late final _name = TextEditingController(text: widget.name ?? '');
  late final _handle = TextEditingController(text: widget.handle ?? '');
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _handle.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final handle = _handle.text.trim();
    if (handle.isNotEmpty && SettleLinks.railOf(handle) == null) {
      setState(
        () => _error = 'Use a UPI ID (name@okaxis) or a Venmo handle (@name)',
      );
      return;
    }
    setState(() => _error = null);
    await ref
        .read(budgetDaoProvider)
        .updateOwner(name: _name.text, paymentHandle: handle);
    if (mounted) {
      showSnack(context, 'Saved. Friends can now pay you in one tap.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          key: const Key('owner-name'),
          controller: _name,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(labelText: 'Your name'),
        ),
        const SizedBox(height: 10),
        TextField(
          key: const Key('owner-handle'),
          controller: _handle,
          decoration: InputDecoration(
            labelText: 'Your UPI ID or Venmo',
            hintText: 'you@okaxis',
            errorText: _error,
          ),
        ),
        const SizedBox(height: 10),
        OutlinedButton(
          key: const Key('owner-save'),
          onPressed: _save,
          child: const Text('SAVE'),
        ),
      ],
    );
  }
}

class _UpiCaptureTile extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabled = ref.watch(upiCaptureEnabledProvider).value ?? false;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        Icons.notifications_active_outlined,
        color: enabled ? SbColors.owed : SbColors.muted,
      ),
      title: const Text('UPI auto-capture'),
      subtitle: Text(
        enabled
            ? 'On: GPay, PhonePe, Paytm, BHIM and bank alerts are logged automatically.'
            : 'Off: grant notification access so payments log themselves.',
      ),
      trailing: enabled
          ? const SbTag('ON', color: SbColors.owed)
          : const SbTag('OFF'),
      onTap: () async {
        await ref.read(nativeBridgeProvider).openUpiCaptureSettings();
        ref.invalidate(upiCaptureEnabledProvider);
      },
    );
  }
}
