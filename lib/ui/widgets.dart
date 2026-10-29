import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/money.dart';
import 'theme.dart';

/// Flat slab with a thick outline and a hard offset shadow.
class BrutalCard extends StatelessWidget {
  const BrutalCard({
    super.key,
    required this.child,
    this.color = SbColors.surface,
    this.shadowColor = SbColors.lime,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
  });

  final Widget child;
  final Color color;
  final Color shadowColor;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final card = DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        border: Border.all(color: SbColors.outline, width: 2.5),
        boxShadow: [BoxShadow(color: shadowColor, offset: const Offset(5, 5))],
      ),
      child: Padding(padding: padding, child: child),
    );
    if (onTap == null) return card;
    return Material(
      type: MaterialType.transparency,
      child: InkWell(onTap: onTap, child: card),
    );
  }
}

/// Monospace all-caps section / field label.
class SbLabel extends StatelessWidget {
  const SbLabel(this.text, {super.key, this.color = SbColors.muted});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Text(
    text.toUpperCase(),
    style: SbType.label.copyWith(color: color),
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
  );
}

/// Small boxed tag ("TRUE ₹8,330", "+₹900 OWED", "UPI AUTO").
class SbTag extends StatelessWidget {
  const SbTag(this.text, {super.key, this.color = SbColors.paper, this.icon});

  final String text;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        border: Border.all(color: SbColors.ink, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 13, color: SbColors.ink),
              const SizedBox(width: 4),
            ],
            Text(
              text,
              style: SbType.label.copyWith(color: SbColors.ink, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 24, 4, 10),
      child: Row(
        children: [
          Expanded(child: SbLabel(title, color: SbColors.paper)),
          ?trailing,
        ],
      ),
    );
  }
}

class EmptyNote extends StatelessWidget {
  const EmptyNote(this.text, {super.key, this.icon = Icons.inbox_outlined});

  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
      child: Column(
        children: [
          Icon(icon, color: SbColors.muted, size: 32),
          const SizedBox(height: 8),
          Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(color: SbColors.muted),
          ),
        ],
      ),
    );
  }
}

/// Parses what people type into money fields: `450`, `1,200.50`, `₹99`.
int? parseMoneyInput(String text) {
  final cleaned = text.replaceAll(
    RegExp(r'[₹$,\s]|rs\.?', caseSensitive: false),
    '',
  );
  if (cleaned.isEmpty) return null;
  final match = RegExp(r'^(\d{1,9})(?:\.(\d{0,2}))?$').firstMatch(cleaned);
  if (match == null) return null;
  final fraction = (match[2] ?? '').padRight(2, '0');
  return int.parse(match[1]!) * 100 + int.parse(fraction);
}

/// Digits, one decimal point, up to 2 decimals.
final moneyInputFormatters = <TextInputFormatter>[
  FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
  TextInputFormatter.withFunction((oldValue, newValue) {
    final text = newValue.text.replaceAll(',', '');
    return RegExp(r'^\d{0,9}(\.\d{0,2})?$').hasMatch(text)
        ? newValue
        : oldValue;
  }),
];

/// Text for a money field's initial value (`45000` → `450`).
String moneyFieldText(int minor) {
  if (minor == 0) return '';
  return minor % 100 == 0 ? '${minor ~/ 100}' : Money.toPlainDecimal(minor);
}

void showSnack(BuildContext context, String message, {SnackBarAction? action}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message), action: action));
}

/// "today", "yesterday", "3d ago", "12 Oct".
String relativeDay(DateTime date, DateTime today) {
  final d = DateTime(date.year, date.month, date.day);
  final t = DateTime(today.year, today.month, today.day);
  final days = DateTime.utc(
    t.year,
    t.month,
    t.day,
  ).difference(DateTime.utc(d.year, d.month, d.day)).inDays;
  if (days == 0) return 'today';
  if (days == 1) return 'yesterday';
  if (days > 1 && days < 7) return '${days}d ago';
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${date.day} ${months[date.month - 1]}';
}

/// "Rahul → You" with a drawn arrow (no reliance on font arrow glyphs).
class TransferLabel extends StatelessWidget {
  const TransferLabel({super.key, required this.from, required this.to});

  final String from;
  final String to;

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(fontWeight: FontWeight.w800);
    return Row(
      children: [
        Flexible(
          child: Text(from, style: style, overflow: TextOverflow.ellipsis),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 6),
          child: Icon(Icons.arrow_forward, size: 16, color: SbColors.muted),
        ),
        Flexible(
          child: Text(to, style: style, overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }
}
