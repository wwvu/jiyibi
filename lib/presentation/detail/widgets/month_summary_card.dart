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
    final expenseColor = finance?.expense ?? const Color(0xFFD85A30);
    final incomeColor = finance?.income ?? const Color(0xFF3B6D11);

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        child: Row(
          children: [
            Expanded(
              child: _SummaryItem(
                label: '支出',
                value: MoneyUtils.formatYuan(expenseCents),
                valueColor: expenseColor,
              ),
            ),
            Container(width: 1, height: 36, color: theme.dividerColor),
            Expanded(
              child: _SummaryItem(
                label: '收入',
                value: MoneyUtils.formatYuan(incomeCents),
                valueColor: incomeColor,
              ),
            ),
            Container(width: 1, height: 36, color: theme.dividerColor),
            Expanded(
              child: _SummaryItem(
                label: '结余',
                value: MoneyUtils.formatYuan(balanceCents),
                valueColor: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  const _SummaryItem({
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

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 6),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              color: valueColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
