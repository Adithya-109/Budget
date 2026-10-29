import 'package:flutter/material.dart';

import '../features/friends/friend_directory.dart';
import 'widgets.dart';

// Small dialogs that own their TextEditingControllers. A controller must
// outlive the dialog's closing animation, so it is disposed with the
// dialog's State, never right after `showDialog` returns.

/// Asks for a line of text. Resolves to null on cancel.
Future<String?> promptText(
  BuildContext context, {
  required String title,
  String initial = '',
  String? hint,
  TextInputType? keyboardType,
  TextCapitalization capitalization = TextCapitalization.none,
  String actionLabel = 'SAVE',
  Key? fieldKey,
}) {
  return showDialog<String>(
    context: context,
    builder: (_) => _TextPromptDialog(
      title: title,
      initial: initial,
      hint: hint,
      keyboardType: keyboardType,
      capitalization: capitalization,
      actionLabel: actionLabel,
      fieldKey: fieldKey,
    ),
  );
}

class _TextPromptDialog extends StatefulWidget {
  const _TextPromptDialog({
    required this.title,
    required this.initial,
    required this.hint,
    required this.keyboardType,
    required this.capitalization,
    required this.actionLabel,
    required this.fieldKey,
  });

  final String title;
  final String initial;
  final String? hint;
  final TextInputType? keyboardType;
  final TextCapitalization capitalization;
  final String actionLabel;
  final Key? fieldKey;

  @override
  State<_TextPromptDialog> createState() => _TextPromptDialogState();
}

class _TextPromptDialogState extends State<_TextPromptDialog> {
  late final _controller = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        key: widget.fieldKey,
        controller: _controller,
        autofocus: true,
        keyboardType: widget.keyboardType,
        textCapitalization: widget.capitalization,
        decoration: InputDecoration(hintText: widget.hint),
        onSubmitted: (v) => Navigator.pop(context, v),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _controller.text),
          child: Text(widget.actionLabel),
        ),
      ],
    );
  }
}

/// Asks for an amount in minor units. Resolves to null on cancel or junk.
Future<int?> promptMoney(
  BuildContext context, {
  required String title,
  required String symbol,
  int initialMinor = 0,
  String? help,
  Key? fieldKey,
}) {
  return showDialog<int>(
    context: context,
    builder: (_) => _MoneyPromptDialog(
      title: title,
      symbol: symbol,
      initialMinor: initialMinor,
      help: help,
      fieldKey: fieldKey,
    ),
  );
}

class _MoneyPromptDialog extends StatefulWidget {
  const _MoneyPromptDialog({
    required this.title,
    required this.symbol,
    required this.initialMinor,
    required this.help,
    required this.fieldKey,
  });

  final String title;
  final String symbol;
  final int initialMinor;
  final String? help;
  final Key? fieldKey;

  @override
  State<_MoneyPromptDialog> createState() => _MoneyPromptDialogState();
}

class _MoneyPromptDialogState extends State<_MoneyPromptDialog> {
  late final _controller = TextEditingController(
    text: moneyFieldText(widget.initialMinor),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        key: widget.fieldKey,
        controller: _controller,
        autofocus: true,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: moneyInputFormatters,
        decoration: InputDecoration(
          prefixText: '${widget.symbol} ',
          helperText: widget.help,
          helperMaxLines: 3,
        ),
        onSubmitted: (v) => Navigator.pop(context, parseMoneyInput(v)),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () =>
              Navigator.pop(context, parseMoneyInput(_controller.text)),
          child: const Text('SAVE'),
        ),
      ],
    );
  }
}

/// Picks an existing friend by name (autocomplete) or types a new one.
Future<String?> promptFriendName(
  BuildContext context, {
  required FriendDirectory directory,
  String title = 'Add a friend',
}) {
  return showDialog<String>(
    context: context,
    builder: (_) => _FriendPromptDialog(directory: directory, title: title),
  );
}

class _FriendPromptDialog extends StatefulWidget {
  const _FriendPromptDialog({required this.directory, required this.title});

  final FriendDirectory directory;
  final String title;

  @override
  State<_FriendPromptDialog> createState() => _FriendPromptDialogState();
}

class _FriendPromptDialogState extends State<_FriendPromptDialog> {
  String _name = '';

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Autocomplete<String>(
        optionsBuilder: (value) =>
            widget.directory.matching(value.text).map((f) => f.name),
        onSelected: (name) => Navigator.pop(context, name),
        fieldViewBuilder: (context, controller, focus, _) => TextField(
          key: const Key('friend-name'),
          controller: controller,
          focusNode: focus,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(hintText: 'Name'),
          onChanged: (v) => _name = v,
          onSubmitted: (v) => Navigator.pop(context, v),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          key: const Key('friend-add'),
          onPressed: () => Navigator.pop(context, _name),
          child: const Text('ADD'),
        ),
      ],
    );
  }
}
