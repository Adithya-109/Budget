import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../core/database/ledger_models.dart';
import '../../core/money.dart';
import '../../ui/theme.dart';
import '../../ui/widgets.dart';

/// Personal spend per day this cycle against the even-pace line
/// (allowance ÷ cycle length). Today's bar is highlighted.
class BurnChart extends StatelessWidget {
  const BurnChart({
    super.key,
    required this.days,
    required this.today,
    required this.evenPaceMinor,
    required this.symbol,
  });

  final List<DailySpend> days;
  final DateTime today;
  final int evenPaceMinor;
  final String symbol;

  @override
  Widget build(BuildContext context) {
    final maxSpend = days.fold<int>(
      evenPaceMinor,
      (m, d) => d.personalSpendMinor > m ? d.personalSpendMinor : m,
    );
    final top = maxSpend <= 0 ? 100.0 : maxSpend * 1.15 / 100;
    final barWidth = days.length > 25 ? 5.0 : 8.0;
    return BrutalCard(
      shadowColor: SbColors.sky,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const SbLabel('This cycle', color: SbColors.sky),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'even pace ${Money.format(evenPaceMinor, symbol: symbol)}/day',
                  textAlign: TextAlign.end,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: SbColors.muted, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 120,
            child: BarChart(
              BarChartData(
                maxY: top,
                minY: 0,
                alignment: BarChartAlignment.spaceBetween,
                titlesData: const FlTitlesData(show: false),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(
                  show: true,
                  border: const Border(
                    bottom: BorderSide(color: SbColors.outline, width: 2),
                  ),
                ),
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => SbColors.paper,
                    getTooltipItem: (group, _, rod, _) => BarTooltipItem(
                      '${days[group.x].day.day}/${days[group.x].day.month}\n'
                      '${Money.format(days[group.x].personalSpendMinor, symbol: symbol)}',
                      const TextStyle(
                        color: SbColors.ink,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                extraLinesData: ExtraLinesData(
                  horizontalLines: [
                    HorizontalLine(
                      y: evenPaceMinor / 100,
                      color: SbColors.lime,
                      strokeWidth: 2,
                      dashArray: const [6, 4],
                    ),
                  ],
                ),
                barGroups: [
                  for (var i = 0; i < days.length; i++)
                    BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: days[i].personalSpendMinor / 100,
                          width: barWidth,
                          borderRadius: BorderRadius.zero,
                          color: days[i].day == today
                              ? SbColors.lime
                              : days[i].personalSpendMinor > evenPaceMinor
                              ? SbColors.magma
                              : SbColors.paper,
                        ),
                      ],
                    ),
                ],
              ),
              duration: const Duration(milliseconds: 400),
            ),
          ),
        ],
      ),
    );
  }
}
