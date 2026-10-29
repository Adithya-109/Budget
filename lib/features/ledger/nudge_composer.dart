import '../../core/database/enums.dart';
import '../../core/database/ledger_models.dart';
import '../../core/money.dart';
import 'shared_ledger.dart';

enum NudgeTone { polite, meme, digest }

/// A ready-to-share reminder: the message plus the lines a card renders.
class Nudge {
  const Nudge({
    required this.tone,
    required this.text,
    required this.headline,
    required this.lines,
    required this.totalMinor,
  });

  final NudgeTone tone;
  final String text;

  /// Big title on the shareable card.
  final String headline;
  final List<SharedLedgerLine> lines;
  final int totalMinor;
}

/// Writes friendly, never passive-aggressive reminders for money a friend
/// owes (Feature 4). Only `OWES_ME` splits are nudge material.
abstract final class NudgeComposer {
  static const _months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  /// Lines for [friendName]'s open receivables, oldest first.
  static List<SharedLedgerLine> linesFor(List<OpenSplit> splits) => [
    for (final s in splits)
      if (s.direction == SplitDirection.owesMe)
        SharedLedgerLine(
          label: s.merchant,
          amountMinor: s.amountMinor,
          date: DateTime(s.loggedAt.year, s.loggedAt.month, s.loggedAt.day),
        ),
  ];

  static Nudge compose({
    required NudgeTone tone,
    required String friendName,
    required List<OpenSplit> openSplits,
    required String currencySymbol,
    String? ownerName,
    Uri? settleLink,
  }) {
    final lines = linesFor(openSplits);
    if (lines.isEmpty) {
      throw ArgumentError('$friendName has nothing to settle');
    }
    final total = lines.fold(0, (sum, l) => sum + l.amountMinor);
    String money(int minor) => Money.format(minor, symbol: currencySymbol);
    final firstName = friendName.split(' ').first;
    final itemList = lines
        .map((l) => '${l.label} ${money(l.amountMinor)}')
        .join(', ');
    final linkLine = settleLink == null
        ? ''
        : '\n\nSettle in one tap: $settleLink';
    final sign = ownerName == null || ownerName.isEmpty ? '' : '\n— $ownerName';

    switch (tone) {
      case NudgeTone.polite:
        final what = lines.length == 1
            ? lines.single.label
            : 'this week\'s tab';
        return Nudge(
          tone: tone,
          headline: 'Settle-up note',
          text:
              'Hey $firstName! Settling up $what whenever you\'re free: '
              '${money(total)}${lines.length > 1 ? ' ($itemList)' : ''}. '
              'No rush 🙂$linkLine$sign',
          lines: lines,
          totalMinor: total,
        );
      case NudgeTone.meme:
        return Nudge(
          tone: tone,
          headline: 'SURVIVAL FUND NOTICE',
          text:
              '🚨 OFFICIAL SURVIVAL FUND NOTICE 🚨\n'
              'Dear $firstName, a broke college student is surviving on '
              'Maggi and hope. Your contribution of ${money(total)} '
              '($itemList) would restore essential services '
              '(snacks).$linkLine$sign',
          lines: lines,
          totalMinor: total,
        );
      case NudgeTone.digest:
        final latest = lines
            .map((l) => l.date)
            .reduce((a, b) => a.isAfter(b) ? a : b);
        final month = _months[latest.month - 1];
        final bullets = lines
            .map((l) => '• ${l.label} — ${money(l.amountMinor)}')
            .join('\n');
        return Nudge(
          tone: tone,
          headline: '$month tab',
          text:
              'Hi $firstName! Here\'s our $month tab in one go so I\'m not '
              'pinging you for every chai:\n$bullets\n'
              'Total: ${money(total)}$linkLine$sign',
          lines: lines,
          totalMinor: total,
        );
    }
  }

  /// Days 1–3 of a month are when the dashboard suggests sending digests.
  static bool isDigestWindow(DateTime today) => today.day <= 3;
}
