import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/money.dart';
import 'theme.dart';

/// Swiss Bento cell: rounded surface with a 1px hairline (DESIGN_SYSTEM §1).
class BentoCard extends StatelessWidget {
  const BentoCard({
    super.key,
    required this.child,
    this.color,
    this.borderColor,
    this.gradient,
    this.padding = const EdgeInsets.all(18),
    this.radius = SbRadius.card,
    this.onTap,
  });

  final Widget child;
  final Color? color;
  final Color? borderColor;
  final Gradient? gradient;
  final EdgeInsetsGeometry padding;
  final double radius;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final sb = context.sb;
    final shape = BorderRadius.circular(radius);
    final card = DecoratedBox(
      decoration: BoxDecoration(
        color: gradient == null ? (color ?? sb.surfacePrimary) : null,
        gradient: gradient,
        borderRadius: shape,
        border: Border.all(color: borderColor ?? sb.hairlineBorder),
        boxShadow: [
          BoxShadow(
            color: sb.shadow,
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(padding: padding, child: child),
    );
    if (onTap == null) return card;
    return Material(
      type: MaterialType.transparency,
      child: InkWell(borderRadius: shape, onTap: onTap, child: card),
    );
  }
}

/// Frosted glass HUD (True Liquid Balance, command pill): blurred backdrop,
/// translucent fill and a brighter specular top-left edge.
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.radius = SbRadius.card,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final sb = context.sb;
    final shape = BorderRadius.circular(radius);
    return ClipRRect(
      borderRadius: shape,
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(
          sigmaX: context.isDark ? 24 : 20,
          sigmaY: context.isDark ? 24 : 20,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: sb.surfaceGlass,
            borderRadius: shape,
          ),
          foregroundDecoration: BoxDecoration(
            borderRadius: shape,
            border: Border.all(color: sb.specularBorder),
          ),
          // Soft top-left specular highlight over the frosted fill.
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: shape,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: context.isDark ? 0.06 : 0.5),
                  Colors.white.withValues(alpha: 0),
                ],
                stops: const [0, 0.5],
              ),
            ),
            child: Padding(padding: padding, child: child),
          ),
        ),
      ),
    );
  }
}

/// Small upper-case label ("SAFE TO SPEND TODAY").
class SbLabel extends StatelessWidget {
  const SbLabel(this.text, {super.key, this.color});

  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) => Text(
    text.toUpperCase(),
    style: SbType.section.copyWith(
      fontSize: 11,
      color: color ?? context.sb.textSecondary,
    ),
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
  );
}

/// Tinted pill badge ("+₹900 OWED", "UPI AUTO", "4 DAYS LEFT").
class SbTag extends StatelessWidget {
  const SbTag(
    this.text, {
    super.key,
    this.color,
    this.icon,
    this.filled = false,
  });

  final String text;

  /// Semantic colour; defaults to secondary text.
  final Color? color;
  final IconData? icon;

  /// Solid fill (for the most important badge on a card).
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final sb = context.sb;
    final c = color ?? sb.textSecondary;
    final fg = filled ? (context.isDark ? sb.canvas : Colors.white) : c;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: filled ? c : c.withValues(alpha: context.isDark ? 0.14 : 0.10),
        borderRadius: BorderRadius.circular(SbRadius.pill),
        border: Border.all(color: c.withValues(alpha: filled ? 1 : 0.28)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 13, color: fg),
              const SizedBox(width: 4),
            ],
            Flexible(
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: SbType.chip.copyWith(color: fg),
              ),
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
      padding: const EdgeInsets.fromLTRB(4, 26, 4, 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: SbType.section.copyWith(color: context.sb.textSecondary),
            ),
          ),
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
    final sb = context.sb;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
      child: Column(
        children: [
          Icon(icon, color: sb.textMuted, size: 30),
          const SizedBox(height: 8),
          Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(color: sb.textSecondary),
          ),
        ],
      ),
    );
  }
}

/// Initials in a colour picked from the name, so a friend keeps one colour
/// everywhere (ledger, graph, receipt bubbles, bills).
class FriendAvatar extends StatelessWidget {
  const FriendAvatar(
    this.name, {
    super.key,
    this.size = 36,
    this.dimmed = false,
    this.ring,
  });

  final String name;
  final double size;

  /// Away / settled: greyed out.
  final bool dimmed;

  /// Optional coloured ring (selection, debt direction).
  final Color? ring;

  static const _hues = [152.0, 200.0, 262.0, 330.0, 24.0, 44.0, 172.0, 288.0];

  static Color colorFor(String name, {required bool dark}) {
    var h = 0;
    for (final c in name.toLowerCase().codeUnits) {
      h = (h * 31 + c) & 0x7fffffff;
    }
    return HSLColor.fromAHSL(
      1,
      _hues[h % _hues.length],
      0.62,
      dark ? 0.58 : 0.46,
    ).toColor();
  }

  @override
  Widget build(BuildContext context) {
    final sb = context.sb;
    final trimmed = name.trim();
    final initial = trimmed.isEmpty
        ? '?'
        : trimmed.characters.first.toUpperCase();
    final bg = dimmed
        ? sb.surfaceElevated
        : colorFor(trimmed, dark: context.isDark);
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
        border: Border.all(
          color: ring ?? sb.canvas,
          width: ring == null ? 2 : 2.5,
        ),
      ),
      child: Text(
        initial,
        style: TextStyle(
          fontFamily: SbType.display,
          fontWeight: FontWeight.w800,
          fontSize: size * 0.42,
          color: dimmed ? sb.textMuted : Colors.white,
        ),
      ),
    );
  }
}

/// Overlapping avatar bubbles ("who ate this").
class AvatarStack extends StatelessWidget {
  const AvatarStack(this.names, {super.key, this.size = 26, this.max = 4});

  final List<String> names;
  final double size;
  final int max;

  @override
  Widget build(BuildContext context) {
    final shown = names.take(max).toList();
    final extra = names.length - shown.length;
    final step = size * 0.68;
    final count = shown.length + (extra > 0 ? 1 : 0);
    return SizedBox(
      width: count == 0 ? 0 : step * (count - 1) + size,
      height: size,
      child: Stack(
        children: [
          for (var i = 0; i < shown.length; i++)
            Positioned(
              left: i * step,
              child: FriendAvatar(shown[i], size: size),
            ),
          if (extra > 0)
            Positioned(
              left: shown.length * step,
              child: Container(
                width: size,
                height: size,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: context.sb.surfaceElevated,
                  shape: BoxShape.circle,
                  border: Border.all(color: context.sb.canvas, width: 2),
                ),
                child: Text(
                  '+$extra',
                  style: SbType.chip.copyWith(
                    fontSize: size * 0.36,
                    color: context.sb.textSecondary,
                  ),
                ),
              ),
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
    final style = SbType.body.copyWith(
      fontWeight: FontWeight.w700,
      color: context.sb.textPrimary,
    );
    return Row(
      children: [
        Flexible(
          child: Text(from, style: style, overflow: TextOverflow.ellipsis),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Icon(
            Icons.arrow_forward_rounded,
            size: 16,
            color: context.sb.textMuted,
          ),
        ),
        Flexible(
          child: Text(to, style: style, overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }
}
