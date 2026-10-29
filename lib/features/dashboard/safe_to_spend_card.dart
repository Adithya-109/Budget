import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/money.dart';
import '../../domain/burn_rate.dart';
import '../../ui/theme.dart';
import '../../ui/widgets.dart';
import 'spring_gauge.dart';

/// Money text that glides to its new value, so tomorrow's limit visibly
/// drops (or rises) the moment an expense is logged.
class AnimatedMoney extends StatelessWidget {
  const AnimatedMoney(
    this.minor, {
    super.key,
    required this.symbol,
    required this.style,
  });

  final int minor;
  final String symbol;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(end: minor.toDouble()),
      duration: const Duration(milliseconds: 750),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) => Text(
        // Whole units while gliding, the exact amount once it lands.
        Money.format(
          (value - minor).abs() < 0.5 ? minor : (value / 100).round() * 100,
          symbol: symbol,
        ),
        style: style,
        maxLines: 1,
        overflow: TextOverflow.fade,
        softWrap: false,
      ),
    );
  }
}

/// The hero (DESIGN_SYSTEM §3 Page 1): a 260° spring gauge of what's left
/// of today's limit over the survival aura, with tomorrow's recalibrated
/// limit underneath.
class SafeToSpendCard extends StatefulWidget {
  const SafeToSpendCard({
    super.key,
    required this.metrics,
    required this.symbol,
  });

  final BurnRateMetrics metrics;
  final String symbol;

  @override
  State<SafeToSpendCard> createState() => _SafeToSpendCardState();
}

class _SafeToSpendCardState extends State<SafeToSpendCard> {
  @override
  void didUpdateWidget(covariant SafeToSpendCard old) {
    super.didUpdateWidget(old);
    // Haptic choreography: crossing into Survival Mode is a heavy thud.
    if (!old.metrics.isSurvivalMode && widget.metrics.isSurvivalMode) {
      HapticFeedback.heavyImpact();
    }
  }

  @override
  Widget build(BuildContext context) {
    final sb = context.sb;
    final m = widget.metrics;
    String fmt(int v) => Money.format(v, symbol: widget.symbol);
    final survival = m.isSurvivalMode;
    final tomorrow = m.tomorrowLimitMinor;
    final delta = m.recalibrationDeltaMinor;
    final ratio = m.dailyLimitMinor <= 0
        ? 0.0
        : (m.leftTodayMinor / m.dailyLimitMinor).clamp(0.0, 1.0);
    final alert = survival || m.isOverToday;
    final accent = alert ? sb.survivalMagma : sb.safeMint;

    return BentoCard(
      key: const Key('safe-to-spend-card'),
      padding: EdgeInsets.zero,
      borderColor: survival ? sb.survivalMagma.withValues(alpha: 0.45) : null,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(SbRadius.card),
        child: Stack(
          children: [
            Positioned.fill(child: SurvivalAura(burnRatio: survival ? 1 : 0)),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: SbLabel(
                          survival ? 'Survival mode' : 'Safe to spend today',
                          color: accent,
                        ),
                      ),
                      SbTag(
                        '${m.daysRemaining} ${m.daysRemaining == 1 ? 'day' : 'days'} left',
                        icon: Icons.event_outlined,
                      ),
                    ],
                  ),
                  SizedBox(
                    height: 210,
                    child: SafeSpendSpring(
                      targetRatio: ratio,
                      builder: (context, animated) => CustomPaint(
                        painter: ArcGaugePainter(
                          ratio: animated,
                          track: sb.surfaceElevated,
                          colors: alert
                              ? [sb.survivalMagma, sb.survivalMagmaEnd]
                              : [
                                  sb.safeMint.withValues(alpha: 0.65),
                                  sb.safeMint,
                                ],
                        ),
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 46),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: AnimatedMoney(
                                    m.leftTodayMinor,
                                    key: const Key('safe-today'),
                                    symbol: widget.symbol,
                                    style: SbType.hero.copyWith(
                                      color: m.isOverToday
                                          ? sb.survivalMagma
                                          : sb.textPrimary,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  m.isOverToday
                                      ? 'over today\'s ${fmt(m.dailyLimitMinor)}'
                                      : 'left of ${fmt(m.dailyLimitMinor)} today',
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  style: SbType.chip.copyWith(
                                    fontSize: 13,
                                    color: sb.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (tomorrow != null)
                    _Recalibration(
                      tomorrowMinor: tomorrow,
                      deltaMinor: delta ?? 0,
                      symbol: widget.symbol,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "Tomorrow ₹455 ↓₹14": today's spending re-spreads the rest of the
/// allowance, and the number glides to its new value.
class _Recalibration extends StatelessWidget {
  const _Recalibration({
    required this.tomorrowMinor,
    required this.deltaMinor,
    required this.symbol,
  });

  final int tomorrowMinor;
  final int deltaMinor;
  final String symbol;

  @override
  Widget build(BuildContext context) {
    final sb = context.sb;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: sb.surfaceElevated.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(SbRadius.row),
        border: Border.all(color: sb.hairlineBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Flexible(
              child: Text(
                'Tomorrow',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: SbType.chip.copyWith(
                  fontSize: 13,
                  color: sb.textSecondary,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: AnimatedMoney(
                  tomorrowMinor,
                  key: const Key('tomorrow-limit'),
                  symbol: symbol,
                  style: SbType.amount.copyWith(
                    fontSize: 17,
                    color: sb.textPrimary,
                  ),
                ),
              ),
            ),
            if (deltaMinor != 0)
              SbTag(
                Money.format(deltaMinor.abs(), symbol: symbol),
                icon: deltaMinor < 0
                    ? Icons.south_rounded
                    : Icons.north_rounded,
                color: deltaMinor < 0 ? sb.iOwe : sb.owedToMe,
              ),
          ],
        ),
      ),
    );
  }
}
