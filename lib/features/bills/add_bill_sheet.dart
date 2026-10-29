import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/database/app_database.dart';
import '../../core/money.dart';
import '../../core/providers/database_providers.dart';
import '../../core/providers/engine_providers.dart';
import '../../domain/expense_draft.dart';
import '../../domain/split_calculator.dart';
import '../../ui/prompts.dart';
import '../../ui/theme.dart';
import '../../ui/widgets.dart';
import '../friends/friend_directory.dart';
import 'trial_reminders.dart';

Future<void> showAddBillSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => const AddBillSheet(),
  );
}

/// Adds a free trial (with Trial Shield reminders) or a recurring flatmate
/// bill split equally with the chosen flatmates.
class AddBillSheet extends ConsumerStatefulWidget {
  const AddBillSheet({super.key});

  @override
  ConsumerState<AddBillSheet> createState() => _AddBillSheetState();
}

class _AddBillSheetState extends ConsumerState<AddBillSheet> {
  final _name = TextEditingController();
  final _amount = TextEditingController();
  final _cancelUrl = TextEditingController();
  bool _isTrial = true;
  late DateTime _date = _defaultDate(trial: true);
  final _flatmates = <FriendRef>[];
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _amount.dispose();
    _cancelUrl.dispose();
    super.dispose();
  }

  DateTime get _now => ref.read(clockProvider)();

  /// Trials: 30 days out (the usual trial). Bills: the next 1st at 9 am.
  DateTime _defaultDate({required bool trial}) {
    final now = DateTime.now();
    return trial
        ? DateTime(now.year, now.month, now.day + 30, now.hour, now.minute)
        : DateTime(now.year, now.month + 1, 1, 9);
  }

  int get _amountMinor => parseMoneyInput(_amount.text) ?? 0;

  /// The user's equal share (they pay the bill, so they absorb rounding).
  int get _myShareMinor {
    final total = _amountMinor;
    if (total <= 0) return 0;
    if (_isTrial || _flatmates.isEmpty) return total;
    final people = <Object>['me', ..._flatmates];
    return SplitCalculator.equal(total, people)['me']!;
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 730)),
      helpText: _isTrial ? 'When does the trial charge?' : 'Next charge date',
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_date),
    );
    setState(() {
      _date = DateTime(
        date.year,
        date.month,
        date.day,
        time?.hour ?? 9,
        time?.minute ?? 0,
      );
    });
  }

  Future<void> _addFlatmate() async {
    final directory =
        ref.read(friendDirectoryProvider).value ?? FriendDirectory(const []);
    final name = await promptFriendName(
      context,
      directory: directory,
      title: 'Add a flatmate',
    );
    if (name == null || name.trim().isEmpty) return;
    final friend = directory.resolve(name);
    if (_flatmates.contains(friend)) return;
    setState(() => _flatmates.add(friend));
  }

  Future<void> _save() async {
    final amount = _amountMinor;
    if (_name.text.trim().isEmpty || amount <= 0) {
      showSnack(context, 'Add a name and an amount.');
      return;
    }
    setState(() => _saving = true);
    try {
      final dao = ref.read(subscriptionsDaoProvider);
      final url = _cancelUrl.text.trim();
      final id = await dao.addSubscription(
        name: _name.text.trim(),
        amountMinor: amount,
        myShareMinor: _myShareMinor,
        billingDate: _date,
        isFreeTrial: _isTrial,
        cancelUrl: _isTrial && url.isNotEmpty
            ? (url.contains('://') ? url : 'https://$url')
            : null,
        splitGroup: _isTrial
            ? const []
            : [
                for (final f in _flatmates)
                  SplitGroupMember(
                    friendId: f.id,
                    friendName: f.name,
                    paymentHandle: f.paymentHandle,
                  ),
              ],
      );
      if (_isTrial) {
        final scheduler = ref.read(trialReminderSchedulerProvider);
        await scheduler.requestPermission();
        final sub = await dao.byId(id);
        if (sub != null) {
          await scheduler.schedule(
            sub,
            now: _now,
            symbol: ref.read(currencySymbolProvider),
          );
        }
      }
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final symbol = ref.watch(currencySymbolProvider);
    String fmt(int v) => Money.format(v, symbol: symbol);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'ADD A BILL',
              style: Theme.of(context).appBarTheme.titleTextStyle,
            ),
            const SizedBox(height: 14),
            SegmentedButton<bool>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(
                  value: true,
                  label: Text('Free trial'),
                  icon: Icon(Icons.shield_outlined),
                ),
                ButtonSegment(
                  value: false,
                  label: Text('Flatmate bill'),
                  icon: Icon(Icons.home_work_outlined),
                ),
              ],
              selected: {_isTrial},
              onSelectionChanged: (s) => setState(() {
                _isTrial = s.single;
                _date = _defaultDate(trial: _isTrial);
              }),
            ),
            const SizedBox(height: 14),
            TextField(
              key: const Key('bill-name'),
              controller: _name,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: _isTrial
                    ? 'Trial (e.g. Apple Music)'
                    : 'Bill (e.g. Wi-Fi)',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              key: const Key('bill-amount'),
              controller: _amount,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: moneyInputFormatters,
              decoration: InputDecoration(
                labelText: _isTrial ? 'Price after the trial' : 'Monthly total',
                prefixText: '$symbol ',
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _pickDate,
              icon: const Icon(Icons.event),
              label: Text(
                '${_isTrial ? 'Charges' : 'Next charge'} ${DateFormat('EEE d MMM, h:mm a').format(_date)}',
              ),
            ),
            if (_isTrial) ...[
              const SizedBox(height: 10),
              TextField(
                controller: _cancelUrl,
                keyboardType: TextInputType.url,
                decoration: const InputDecoration(
                  labelText: 'Cancel page (optional)',
                  hintText: 'apps.apple.com/account/subscriptions',
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'You\'ll get a high-priority alert 48h and 12h before it charges.',
                style: TextStyle(color: SbColors.muted),
              ),
            ] else ...[
              const SectionHeader('Split with'),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final f in _flatmates)
                    InputChip(
                      label: Text(f.name),
                      onDeleted: () => setState(() => _flatmates.remove(f)),
                    ),
                  ActionChip(
                    avatar: const Icon(Icons.person_add_alt_1, size: 16),
                    label: const Text('Add flatmate'),
                    onPressed: _addFlatmate,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                _flatmates.isEmpty
                    ? 'Just you.'
                    : 'Each month you pay ${fmt(_amountMinor)}; your share is ${fmt(_myShareMinor)} '
                          'and ${_flatmates.map((f) => f.name).join(', ')} get billed the rest automatically.',
                style: const TextStyle(color: SbColors.muted),
              ),
            ],
            const SizedBox(height: 18),
            FilledButton(
              key: const Key('bill-save'),
              onPressed: _saving ? null : _save,
              child: Text(_isTrial ? 'SHIELD THIS TRIAL' : 'ADD BILL'),
            ),
          ],
        ),
      ),
    );
  }
}
