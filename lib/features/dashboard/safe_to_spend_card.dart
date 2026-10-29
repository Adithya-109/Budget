import 'package:flutter/material.dart';

import '../../core/money.dart';
import '../../domain/burn_rate.dart';
import '../../ui/theme.dart';
import '../../ui/widgets.dart';

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

/// The hero: what's safe to spend today, and how today's spending moves
/// tomorrow's limit.
class SafeToSpendCard extends StatelessWidget {
  const SafeToSpendCard({
    super.key,
    required this.metrics,
    required this.symbol,
  });

  final BurnRateMetrics metrics;
  final String symbol;

  @override
  Widget build(BuildContext context) {
    final survival = metrics.isSurvivalMode;
    final ink = survival ? SbColors.ink : SbColors.paper;
    final tomorrow = metrics.tomorrowLimitMinor;
    final delta = metrics.recalibrationDeltaMinor;
    return BrutalCard(
      key: const Key('safe-to-spend-card'),
      color: survival ? SbColors.survival : SbColors.surface,
      shadowColor: survival ? SbColors.paper : SbColors.lime,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: SbLabel(
                  survival ? 'Survival mode' : 'Safe to spend today',
                  color: survival ? SbColors.ink : SbColors.lime,
                ),
              ),
              const SizedBox(width: 8),
              SbTag(
                '${metrics.daysRemaining} ${metrics.daysRemaining == 1 ? 'DAY' : 'DAYS'} LEFT',
                color: survival ? SbColors.paper : SbColors.lime,
              ),
            ],
          ),
          const SizedBox(height: 10),
          FittedBox(
            alignment: Alignment.centerLeft,
            fit: BoxFit.scaleDown,
            child: AnimatedMoney(
              metrics.leftTodayMinor,
              key: const Key('safe-today'),
              symbol: symbol,
              style: SbType.hero.copyWith(
                color: metrics.isOverToday && !survival ? SbColors.magma : ink,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            metrics.isOverToday
                ? 'Over today\'s ${Money.format(metrics.dailyLimitMinor, symbol: symbol)} limit'
                : 'left of your ${Money.format(metrics.dailyLimitMinor, symbol: symbol)} daily limit',
            style: TextStyle(
              color: ink.withValues(alpha: 0.75),
              fontWeight: FontWeight.w600,
            ),
          ),
          if (tomorrow != null) ...[
            const SizedBox(height: 14),
            Container(height: 2, color: ink),
            const SizedBox(height: 10),
            Row(
              children: [
                SbLabel('Tomorrow', color: ink.withValues(alpha: 0.75)),
                const SizedBox(width: 10),
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: AnimatedMoney(
                      tomorrow,
                      key: const Key('tomorrow-limit'),
                      symbol: symbol,
                      style: SbType.figure.copyWith(color: ink),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (delta != null && delta != 0)
                  SbTag(
                    Money.format(delta.abs(), symbol: symbol),
                    icon: delta < 0 ? Icons.south : Icons.north,
                    color: delta < 0 ? SbColors.magma : SbColors.owed,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
