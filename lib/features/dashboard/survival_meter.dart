import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/money.dart';
import '../../domain/burn_rate.dart';
import '../../ui/theme.dart';
import '../../ui/widgets.dart';

/// Days-Until-Broke velocity meter (DESIGN_SYSTEM §3 Page 1): how long the
/// cash lasts at the 7-day pace, against the days until the next allowance.
/// Survival Mode turns it magma and names the date the money runs out.
class SurvivalMeter extends StatelessWidget {
  const SurvivalMeter({super.key, required this.metrics, required this.symbol});

  final BurnRateMetrics metrics;
  final String symbol;

  @override
  Widget build(BuildContext context) {
    final sb = context.sb;
    final days = metrics.daysUntilBroke;
    final remaining = metrics.daysRemaining;
    final survival = metrics.isSurvivalMode;
    final fraction = days == null || remaining == 0
        ? 1.0
        : (days / remaining).clamp(0.0, 1.0);
    final pace = Money.format(metrics.avgDailyBurnMinor, symbol: symbol);
    final brokeDate = metrics.brokeDate;
    final message = days == null
        ? 'No spending in the last 7 days. Your cash isn\'t burning.'
        : survival
        ? 'At $pace/day you hit ${symbol}0 on '
              '${DateFormat('EEE d MMM').format(brokeDate!)}, '
              '${remaining - days} ${remaining - days == 1 ? 'day' : 'days'} before your allowance.'
        : 'At $pace/day your cash lasts past your next allowance.';

    return BentoCard(
      key: const Key('survival-meter'),
      borderColor: survival ? sb.survivalMagma.withValues(alpha: 0.4) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SbLabel(
                      'Days until broke',
                      color: survival ? sb.survivalMagma : null,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          days == null ? '∞' : '$days',
                          key: const Key('days-until-broke'),
                          style: SbType.balance.copyWith(
                            fontSize: 30,
                            color: survival ? sb.survivalMagma : sb.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            days == 1 ? 'day of cash' : 'days of cash',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: SbType.chip.copyWith(
                              fontSize: 13,
                              color: sb.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: SbTag(
                  '$remaining ${remaining == 1 ? 'day' : 'days'} to allowance',
                  color: survival ? sb.survivalMagma : sb.safeMint,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _VelocityBar(fraction: fraction, survival: survival),
          const SizedBox(height: 12),
          Text(
            message,
            style: SbType.body.copyWith(
              fontSize: 14,
              height: 1.35,
              color: sb.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Cash runway as a share of the days left; the end marker is the next
/// allowance.
class _VelocityBar extends StatelessWidget {
  const _VelocityBar({required this.fraction, required this.survival});

  final double fraction;
  final bool survival;

  @override
  Widget build(BuildContext context) {
    final sb = context.sb;
    return SizedBox(
      height: 12,
      child: LayoutBuilder(
        builder: (context, box) => Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: sb.surfaceElevated,
                  borderRadius: BorderRadius.circular(SbRadius.pill),
                ),
              ),
            ),
            TweenAnimationBuilder<double>(
              tween: Tween(end: fraction),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) => Container(
                width: (box.maxWidth * value).clamp(12, box.maxWidth),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(SbRadius.pill),
                  gradient: survival
                      ? sb.magmaGradient
                      : LinearGradient(
                          colors: [
                            sb.safeMint.withValues(alpha: 0.6),
                            sb.safeMint,
                          ],
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// True Liquid Balance glass card: bank − what I owe, with what's floating
/// with friends as a pill (tap → Friends).
class LiquidBalanceCard extends StatelessWidget {
  const LiquidBalanceCard({
    super.key,
    required this.balance,
    required this.symbol,
    required this.onOpenFriends,
  });

  final TrueLiquidBalance balance;
  final String symbol;
  final VoidCallback onOpenFriends;

  @override
  Widget build(BuildContext context) {
    final sb = context.sb;
    String fmt(int v) => Money.format(v, symbol: symbol);
    return GestureDetector(
      key: const Key('liquid-balance-card'),
      onTap: () => _explain(context, fmt),
      child: GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Expanded(child: SbLabel('True spendable cash')),
                if (balance.owedToMeMinor > 0)
                  GestureDetector(
                    onTap: onOpenFriends,
                    child: SbTag(
                      '+${fmt(balance.owedToMeMinor)} owed to you',
                      key: const Key('owed-pill'),
                      color: sb.owedToMe,
                      icon: Icons.south_west_rounded,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                fmt(balance.trueSpendableMinor),
                key: const Key('true-spendable'),
                style: SbType.hero.copyWith(
                  fontSize: 34,
                  color: balance.trueSpendableMinor < 0
                      ? sb.survivalMagma
                      : sb.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 14,
              runSpacing: 4,
              children: [
                _Figure(
                  label: 'Bank',
                  value: fmt(balance.bankBalanceMinor),
                  color: sb.textSecondary,
                ),
                _Figure(
                  label: 'You owe',
                  value: balance.iOweMinor == 0
                      ? fmt(0)
                      : '−${fmt(balance.iOweMinor)}',
                  color: balance.iOweMinor == 0 ? sb.textSecondary : sb.iOwe,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _explain(BuildContext context, String Function(int) fmt) {
    showDialog<void>(
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
    );
  }
}

class _Figure extends StatelessWidget {
  const _Figure({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '$label  ',
            style: TextStyle(color: context.sb.textMuted),
          ),
          TextSpan(
            text: value,
            style: SbType.amount.copyWith(fontSize: 14, color: color),
          ),
        ],
      ),
      style: SbType.chip.copyWith(fontSize: 13),
    );
  }
}
