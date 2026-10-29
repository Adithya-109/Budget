import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/money.dart';
import '../../domain/burn_rate.dart';
import '../../ui/theme.dart';
import '../../ui/widgets.dart';

/// Days-Until-Broke gauge: how far the cash goes at the current 7-day pace,
/// against the days until the next allowance. Turns magma/red in Survival
/// Mode and names the exact date the money runs out.
class SurvivalMeter extends StatelessWidget {
  const SurvivalMeter({super.key, required this.metrics, required this.symbol});

  final BurnRateMetrics metrics;
  final String symbol;

  @override
  Widget build(BuildContext context) {
    final days = metrics.daysUntilBroke;
    final remaining = metrics.daysRemaining;
    final fraction = days == null || remaining == 0
        ? 1.0
        : (days / remaining).clamp(0.0, 1.0);
    final color = !metrics.isSurvivalMode
        ? SbColors.lime
        : fraction < 0.5
        ? SbColors.survival
        : SbColors.magma;
    final pace = Money.format(metrics.avgDailyBurnMinor, symbol: symbol);
    final brokeDate = metrics.brokeDate;
    final message = days == null
        ? 'No spending in the last 7 days. Your cash isn\'t burning.'
        : metrics.isSurvivalMode
        ? 'At $pace/day you hit ${symbol}0 on '
              '${DateFormat('EEE d MMM').format(brokeDate!)}, '
              '${remaining - days} ${remaining - days == 1 ? 'day' : 'days'} before your allowance.'
        : 'At $pace/day your cash lasts past your next allowance.';

    return BrutalCard(
      key: const Key('survival-meter'),
      shadowColor: color,
      child: Row(
        children: [
          SizedBox.square(
            dimension: 92,
            child: TweenAnimationBuilder<double>(
              tween: Tween(end: fraction),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) => CustomPaint(
                painter: _GaugePainter(value: value, color: color),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        days == null ? '∞' : '$days',
                        key: const Key('days-until-broke'),
                        style: SbType.figure.copyWith(
                          fontSize: 24,
                          color: color,
                        ),
                      ),
                      const Text(
                        'days',
                        style: TextStyle(color: SbColors.muted, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SbLabel(
                  metrics.isSurvivalMode ? 'Days until broke' : 'Burn rate',
                  color: color,
                ),
                const SizedBox(height: 6),
                Text(
                  message,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '$remaining ${remaining == 1 ? 'day' : 'days'} until the next allowance',
                  style: const TextStyle(color: SbColors.muted, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  _GaugePainter({required this.value, required this.color});

  final double value;
  final Color color;

  static const _start = math.pi * 0.75;
  static const _sweep = math.pi * 1.5;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final arc = rect.deflate(8);
    final track = Paint()
      ..color = SbColors.raised
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.butt;
    final fill = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.butt;
    canvas.drawArc(arc, _start, _sweep, false, track);
    canvas.drawArc(arc, _start, _sweep * value, false, fill);
  }

  @override
  bool shouldRepaint(_GaugePainter old) =>
      old.value != value || old.color != color;
}

/// True Liquid Balance: bank − what I owe, with a green badge for what's
/// floating with friends.
class LiquidBalancePill extends StatelessWidget {
  const LiquidBalancePill({
    super.key,
    required this.balance,
    required this.symbol,
  });

  final TrueLiquidBalance balance;
  final String symbol;

  @override
  Widget build(BuildContext context) {
    String fmt(int v) => Money.format(v, symbol: symbol);
    return InkWell(
      key: const Key('liquid-balance-pill'),
      onTap: () => showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('True liquid balance'),
          content: Text(
            'Bank balance ${fmt(balance.bankBalanceMinor)}\n'
            '− money you owe friends ${fmt(balance.iOweMinor)}\n'
            '= ${fmt(balance.trueSpendableMinor)} that is really yours.\n\n'
            'Friends owe you ${fmt(balance.owedToMeMinor)}. That isn\'t income: '
            'it\'s your own cash coming back.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Got it'),
            ),
          ],
        ),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          SbTag(
            'TRUE ${fmt(balance.trueSpendableMinor)}',
            key: const Key('true-spendable'),
            icon: Icons.account_balance_wallet_outlined,
          ),
          if (balance.owedToMeMinor > 0)
            SbTag('+${fmt(balance.owedToMeMinor)} OWED', color: SbColors.owed),
          if (balance.iOweMinor > 0)
            SbTag('${fmt(balance.iOweMinor)} YOU OWE', color: SbColors.magma),
        ],
      ),
    );
  }
}
