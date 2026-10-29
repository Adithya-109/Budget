import 'package:flutter/material.dart';

import '../../core/money.dart';
import '../../ui/theme.dart';
import 'nudge_composer.dart';
import 'shared_ledger.dart';

/// The shareable card for a nudge, drawn inside a RepaintBoundary and
/// exported as a PNG. Fixed width so it looks the same on every phone.
class NudgeCard extends StatelessWidget {
  const NudgeCard({
    super.key,
    required this.nudge,
    required this.friendName,
    required this.symbol,
    this.payeeName,
    this.settleLink,
  });

  final Nudge nudge;
  final String friendName;
  final String symbol;
  final String? payeeName;
  final Uri? settleLink;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 340,
      child: switch (nudge.tone) {
        NudgeTone.polite => _PoliteCard(this),
        NudgeTone.meme => _SurvivalFactsCard(this),
        NudgeTone.digest => _DigestCard(this),
      },
    );
  }

  String money(int minor) => Money.format(minor, symbol: symbol);
}

const _ink = TextStyle(color: SbColors.ink);

class _PoliteCard extends StatelessWidget {
  const _PoliteCard(this.card);

  final NudgeCard card;

  @override
  Widget build(BuildContext context) {
    final n = card.nudge;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: SbColors.paper,
        border: Border.all(color: SbColors.ink, width: 3),
        boxShadow: const [
          BoxShadow(color: SbColors.lime, offset: Offset(6, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'HEY ${card.friendName.split(' ').first.toUpperCase()} 👋',
            style: _ink.merge(SbType.label.copyWith(fontSize: 13)),
          ),
          const SizedBox(height: 12),
          Text(
            card.money(n.totalMinor),
            style: _ink.merge(SbType.hero.copyWith(fontSize: 44)),
          ),
          const SizedBox(height: 6),
          Text(
            'whenever you\'re free · ${n.lines.length} ${n.lines.length == 1 ? 'thing' : 'things'}',
            style: _ink.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 14),
          for (final l in n.lines.take(6))
            Text(
              '· ${l.label}  ${card.money(l.amountMinor)}',
              style: _ink.copyWith(fontWeight: FontWeight.w600),
            ),
          if (n.lines.length > 6)
            Text(
              '· +${n.lines.length - 6} more',
              style: _ink.copyWith(fontWeight: FontWeight.w600),
            ),
          const SizedBox(height: 14),
          Text(
            'No rush 🙂 · SplitBurn',
            style: _ink.copyWith(color: SbColors.ink.withValues(alpha: 0.6)),
          ),
        ],
      ),
    );
  }
}

/// "Broke College Student" meme card styled as a nutrition label.
class _SurvivalFactsCard extends StatelessWidget {
  const _SurvivalFactsCard(this.card);

  final NudgeCard card;

  @override
  Widget build(BuildContext context) {
    final n = card.nudge;
    Widget rule(double h) => Container(
      height: h,
      color: SbColors.ink,
      margin: const EdgeInsets.symmetric(vertical: 4),
    );
    Widget row(String label, String value, {bool bold = false}) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: _ink.copyWith(
                fontWeight: bold ? FontWeight.w900 : FontWeight.w500,
              ),
            ),
          ),
          Text(value, style: _ink.copyWith(fontWeight: FontWeight.w900)),
        ],
      ),
    );
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: SbColors.ink, width: 3),
        boxShadow: const [
          BoxShadow(color: SbColors.survival, offset: Offset(6, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Survival Facts',
            style: _ink.copyWith(
              fontSize: 34,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
          Text(
            '🚨 OFFICIAL SURVIVAL FUND NOTICE',
            style: _ink.copyWith(fontWeight: FontWeight.w800, fontSize: 12),
          ),
          rule(1),
          row('Serving size', '1 broke student'),
          row('Servings per semester', 'too few'),
          rule(9),
          row(
            'Owed by ${card.friendName.split(' ').first}',
            card.money(n.totalMinor),
            bold: true,
          ),
          rule(4),
          for (final l in n.lines.take(7))
            row(l.label, card.money(l.amountMinor)),
          if (n.lines.length > 7) row('+${n.lines.length - 7} more snacks', ''),
          rule(4),
          row('Maggi packets remaining', '2'),
          row('% Daily Value of hope', '3%'),
          rule(9),
          Text(
            '* Your contribution restores essential services (snacks).'
            '${card.payeeName == null ? '' : ' Pay ${card.payeeName}.'}',
            style: _ink.copyWith(fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

/// 1st-of-the-month digest: every micro-debt on one receipt.
class _DigestCard extends StatelessWidget {
  const _DigestCard(this.card);

  final NudgeCard card;

  @override
  Widget build(BuildContext context) {
    final n = card.nudge;
    const mono = TextStyle(
      fontFamily: SbType.mono,
      color: SbColors.ink,
      fontSize: 13,
    );
    String date(SharedLedgerLine l) =>
        '${l.date.day.toString().padLeft(2, '0')}/${l.date.month.toString().padLeft(2, '0')}';
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
      decoration: BoxDecoration(
        color: SbColors.paper,
        border: Border.all(color: SbColors.ink, width: 3),
        boxShadow: const [BoxShadow(color: SbColors.sky, offset: Offset(6, 6))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            n.headline.toUpperCase(),
            textAlign: TextAlign.center,
            style: mono.copyWith(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          Text(
            '${card.friendName} · all in one go',
            textAlign: TextAlign.center,
            style: mono,
          ),
          const SizedBox(height: 10),
          Text('-' * 34, style: mono, maxLines: 1, overflow: TextOverflow.clip),
          for (final l in n.lines.take(12))
            Row(
              children: [
                Text('${date(l)}  ', style: mono),
                Expanded(
                  child: Text(
                    l.label,
                    style: mono,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  card.money(l.amountMinor),
                  style: mono.copyWith(fontWeight: FontWeight.w800),
                ),
              ],
            ),
          if (n.lines.length > 12)
            Text('+${n.lines.length - 12} more', style: mono),
          Text('-' * 34, style: mono, maxLines: 1, overflow: TextOverflow.clip),
          Row(
            children: [
              Expanded(
                child: Text(
                  'TOTAL',
                  style: mono.copyWith(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
              ),
              Text(
                card.money(n.totalMinor),
                style: mono.copyWith(fontWeight: FontWeight.w900, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            card.settleLink == null
                ? 'Thank you! — SplitBurn'
                : 'Settle in one tap: ${card.settleLink!.host}',
            textAlign: TextAlign.center,
            style: mono.copyWith(fontSize: 11),
          ),
        ],
      ),
    );
  }
}
