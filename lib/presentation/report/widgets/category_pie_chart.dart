import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import 'package:jiyibi/core/utils/money_utils.dart';

class PieSection {
  const PieSection({
    required this.label,
    required this.amountCents,
    required this.color,
  });

  final String label;
  final int amountCents;
  final Color color;
}

/// 分类占比饼图。中心显示总支出。金额转 double 仅用于绘制。
class CategoryPieChart extends StatelessWidget {
  const CategoryPieChart({
    super.key,
    required this.sections,
    required this.totalCents,
    this.centerLabel = '总支出',
  });

  final List<PieSection> sections;
  final int totalCents;
  final String centerLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (totalCents <= 0 || sections.isEmpty) {
      return SizedBox(
        height: 200,
        child: Center(
          child: Text(
            '暂无数据',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: 220,
      child: Stack(
        alignment: Alignment.center,
        children: [
          PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 60,
              sections: [
                for (final section in sections)
                  PieChartSectionData(
                    value: section.amountCents.toDouble(),
                    color: section.color,
                    radius: 36,
                    title: '',
                  ),
              ],
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                centerLabel,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                MoneyUtils.formatYuan(totalCents),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
