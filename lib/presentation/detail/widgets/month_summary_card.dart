import 'package:flutter/material.dart';

import 'package:jiyibi/core/theme/app_theme.dart';
import 'package:jiyibi/core/utils/money_utils.dart';

/// 月份收支结余卡片：显示本月支出 / 收入 / 结余。
class MonthSummaryCard extends StatelessWidget {
  const MonthSummaryCard({
    super.key,
    required this.expenseCents,
    required this.incomeCents,
  });

  final int expenseCents;
  final int incomeCents;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final balanceCents = incomeCents - expenseCents;
    final finance = theme.extension<FinanceColors>();
    final expenseColor = finance?.expense ?? theme.colorScheme.error;
    final incomeColor = finance?.income ?? theme.colorScheme.primary;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '本月支出',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                MoneyUtils.formatYuan(expenseCents),
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: expenseColor,
                  fontWeight: FontWeight.w800,
                  height: 1.05,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _SummaryPill(
                    label: '收入',
                    value: MoneyUtils.formatYuan(incomeCents),
                    valueColor: incomeColor,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _SummaryPill(
                    label: '结余',
                    value: MoneyUtils.formatYuan(balanceCents),
                    valueColor: balanceCents >= 0
                        ? theme.colorScheme.onSurface
                        : expenseColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryPill extends StatelessWidget {
  const _SummaryPill({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.55,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: theme.textTheme.titleSmall?.copyWith(
                color: valueColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
