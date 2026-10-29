import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/money.dart';
import '../../ui/theme.dart';
import 'nudge_composer.dart';
import 'shared_ledger.dart';
import 'thermal_receipt.dart';

/// The shareable card for a nudge: a thermal-paper receipt with serrated
/// edges (DESIGN_SYSTEM §3 Page 4), drawn inside a RepaintBoundary and
/// exported as a PNG. Fixed width so it looks the same on every phone, and
/// paper-coloured in both themes (paper is paper).
class NudgeCard extends StatelessWidget {
  const NudgeCard({
    super.key,
    required this.nudge,
    required this.friendName,
    required this.symbol,
    this.payeeName,
    this.settleLink,
    this.qrData,
  });

  final Nudge nudge;
  final String friendName;
  final String symbol;
  final String? payeeName;
  final Uri? settleLink;

  /// What the QR code pays: a UPI link when the user has a UPI ID, else the
  /// zero-install settle link. No QR when null.
  final String? qrData;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 300,
      child: ClipPath(
        clipper: const SerratedEdgeClipper(),
        child: ColoredBox(
          color: SplitBurnTokens.light.thermalPaper,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 26, 20, 26),
            child: DefaultTextStyle(
              style: SbType.receipt.copyWith(color: _ink, height: 1.35),
              child: switch (nudge.tone) {
                NudgeTone.polite => _PoliteReceipt(this),
                NudgeTone.meme => _SurvivalNotice(this),
                NudgeTone.digest => _DigestReceipt(this),
              },
            ),
          ),
        ),
      ),
    );
  }

  String money(int minor) => Money.format(minor, symbol: symbol);
}

const _ink = SplitBurnTokens.thermalInk;

TextStyle _strong(double size) => SbType.receipt.copyWith(
  color: _ink,
  fontWeight: FontWeight.w700,
  fontSize: size,
);

Widget _rule(double height) => Container(
  height: height,
  color: _ink,
  margin: const EdgeInsets.symmetric(vertical: 5),
);

Widget _dashes() => const Text(
  '--------------------------------------',
  maxLines: 1,
  overflow: TextOverflow.clip,
  softWrap: false,
);

Widget _row(String label, String value, {bool bold = false, double size = 13}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 1.5),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: bold ? _strong(size) : TextStyle(fontSize: size),
          ),
        ),
        const SizedBox(width: 10),
        Text(value, style: _strong(size)),
      ],
    ),
  );
}

class _SettleQr extends StatelessWidget {
  const _SettleQr(this.card);

  final NudgeCard card;

  @override
  Widget build(BuildContext context) {
    final data = card.qrData;
    if (data == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        children: [
          QrImageView(
            key: const Key('nudge-qr'),
            data: data,
            size: 112,
            padding: EdgeInsets.zero,
            backgroundColor: Colors.transparent,
            eyeStyle: const QrEyeStyle(
              eyeShape: QrEyeShape.square,
              color: _ink,
            ),
            dataModuleStyle: const QrDataModuleStyle(
              dataModuleShape: QrDataModuleShape.square,
              color: _ink,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            data.startsWith('upi:') ? 'SCAN TO PAY (UPI)' : 'SCAN TO SETTLE',
            style: _strong(11),
          ),
        ],
      ),
    );
  }
}

class _PoliteReceipt extends StatelessWidget {
  const _PoliteReceipt(this.card);

  final NudgeCard card;

  @override
  Widget build(BuildContext context) {
    final n = card.nudge;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('SETTLE-UP NOTE', textAlign: TextAlign.center, style: _strong(17)),
        Text(
          'for ${card.friendName.split(' ').first} · no rush',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        _dashes(),
        for (final l in n.lines.take(6))
          _row(l.label, card.money(l.amountMinor)),
        if (n.lines.length > 6) Text('+${n.lines.length - 6} more'),
        _dashes(),
        _row('TOTAL', card.money(n.totalMinor), bold: true, size: 16),
        const SizedBox(height: 8),
        const Text('whenever you\'re free :)', textAlign: TextAlign.center),
        _SettleQr(card),
      ],
    );
  }
}

/// "Broke College Student" meme card: a nutrition label for the survival
/// deficit.
class _SurvivalNotice extends StatelessWidget {
  const _SurvivalNotice(this.card);

  final NudgeCard card;

  @override
  Widget build(BuildContext context) {
    final n = card.nudge;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'OFFICIAL SURVIVAL\nFUND NOTICE',
          textAlign: TextAlign.center,
          style: _strong(17),
        ),
        _rule(1.5),
        Text(
          'Nutrition Facts',
          style: TextStyle(
            fontFamily: SbType.display,
            color: _ink,
            fontSize: 30,
            fontWeight: FontWeight.w800,
            height: 1.05,
          ),
        ),
        Text('Hostel Survival Deficit · ${card.friendName.split(' ').first}'),
        _rule(7),
        Align(
          alignment: Alignment.centerRight,
          child: Text('% Daily Value', style: _strong(11)),
        ),
        _rule(1),
        for (final l in n.lines.take(7))
          _row(l.label, card.money(l.amountMinor)),
        if (n.lines.length > 7) _row('+${n.lines.length - 7} more snacks', ''),
        _rule(1.5),
        _row('SURVIVAL DEFICIT', '100%', bold: true),
        _row('EXCUSES REMAINING', '0%', bold: true),
        _rule(4),
        _row(
          'TOTAL PAYABLE NOW',
          card.money(n.totalMinor),
          bold: true,
          size: 15,
        ),
        const SizedBox(height: 6),
        Text(
          '* Your contribution restores essential services (snacks).'
          '${card.payeeName == null ? '' : ' Pay ${card.payeeName}.'}',
          style: const TextStyle(fontSize: 11),
        ),
        _SettleQr(card),
      ],
    );
  }
}

/// 1st-of-the-month digest: every micro-debt on one receipt.
class _DigestReceipt extends StatelessWidget {
  const _DigestReceipt(this.card);

  final NudgeCard card;

  @override
  Widget build(BuildContext context) {
    final n = card.nudge;
    String date(SharedLedgerLine l) =>
        '${l.date.day.toString().padLeft(2, '0')}/${l.date.month.toString().padLeft(2, '0')}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          n.headline.toUpperCase(),
          textAlign: TextAlign.center,
          style: _strong(18),
        ),
        Text('${card.friendName} · all in one go', textAlign: TextAlign.center),
        const SizedBox(height: 8),
        _dashes(),
        for (final l in n.lines.take(12))
          _row('${date(l)}  ${l.label}', card.money(l.amountMinor)),
        if (n.lines.length > 12) Text('+${n.lines.length - 12} more'),
        _dashes(),
        _row('TOTAL', card.money(n.totalMinor), bold: true, size: 16),
        const SizedBox(height: 8),
        Text(
          card.settleLink == null
              ? 'Thank you! — SplitBurn'
              : 'Settle in one tap: ${card.settleLink!.host}',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 11),
        ),
        _SettleQr(card),
      ],
    );
  }
}
