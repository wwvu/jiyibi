import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import 'package:jiyibi/core/utils/money_utils.dart';

/// 每日支出趋势曲线图。X 轴 1-31 日，曲线高度=当日支出。
class DailyTrendChart extends StatelessWidget {
  const DailyTrendChart({
    super.key,
    required this.byDay,
    required this.daysInMonth,
    this.color,
  });

  final List<({int day, int amountCents})> byDay;
  final int daysInMonth;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final lineColor = color ?? colorScheme.primary;

    if (byDay.isEmpty) {
      return SizedBox(
        height: 180,
        child: Center(
          child: Text(
            '暂无数据',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    final amountByDay = {for (final item in byDay) item.day: item.amountCents};
    final maxY = amountByDay.values.fold<int>(0, (a, b) => a > b ? a : b);
    final maxYValue = maxY <= 0 ? 1.0 : maxY.toDouble();

    return SizedBox(
      height: 200,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Padding(
          padding: const EdgeInsets.only(right: 16, top: 8, left: 4),
          child: SizedBox(
            width: daysInMonth * 25.0,
            child: LineChart(
              LineChartData(
                minX: 1,
                maxX: daysInMonth.toDouble(),
                minY: 0,
                maxY: maxYValue * 1.1,
                lineBarsData: [
                  LineChartBarData(
                    spots: [
                      for (var day = 1; day <= daysInMonth; day++)
                        FlSpot(
                          day.toDouble(),
                          (amountByDay[day] ?? 0).toDouble(),
                        ),
                    ],
                    isCurved: true,
                    curveSmoothness: 0.3,
                    color: lineColor,
                    barWidth: 2.5,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: lineColor.withValues(alpha: 0.15),
                    ),
                  ),
                ],
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 20,
                      getTitlesWidget: (value, meta) {
                        if ((value - value.roundToDouble()).abs() > 0.01) {
                          return const SizedBox.shrink();
                        }
                        final day = value.toInt();
                        if (day < 1 || day > daysInMonth) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            '$day',
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontSize: 8,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => colorScheme.inverseSurface,
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        return LineTooltipItem(
                          '${spot.x.toInt()}日\n${MoneyUtils.formatYuan(spot.y.toInt())}',
                          TextStyle(
                            color: colorScheme.onInverseSurface,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
