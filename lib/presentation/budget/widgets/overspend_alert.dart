import 'package:flutter/material.dart';

import 'package:jiyibi/core/budget_predictor.dart';
import 'package:jiyibi/core/utils/money_utils.dart';

/// 预算超支预测提醒卡片。
/// 预测超支时显示橙/红卡片含预测金额和日均建议；否则显示绿色「节奏良好」。
class OverspendAlert extends StatelessWidget {
  const OverspendAlert({
    super.key,
    required this.budgetCents,
    required this.usedCents,
    required this.now,
  });

  final int budgetCents;
  final int usedCents;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    if (budgetCents <= 0) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final totalDays = BudgetPredictor.daysInMonth(now.year, now.month);
    final passed = BudgetPredictor.daysPassed(now, totalDays);
    final projected = BudgetPredictor.predictMonthEndCents(
      usedCents: usedCents,
      daysPassed: passed,
      daysInMonth: totalDays,
    );
    final willExceed = BudgetPredictor.willExceed(
      predictedCents: projected,
      budgetCents: budgetCents,
    );

    if (!willExceed) {
      return _AlertCard(
        icon: Icons.check_circle_outline,
        color: const Color(0xFF3B6D11),
        backgroundColor: const Color(0xFF3B6D11).withValues(alpha: 0.1),
        title: '节奏良好',
        message: '按当前节奏预计月末花费 ${MoneyUtils.formatYuan(projected)}，在预算内',
      );
    }

    final overage = BudgetPredictor.overageCents(
      predictedCents: projected,
      budgetCents: budgetCents,
    );
    final suggestion = BudgetPredictor.suggestedDailyCents(
      budgetCents: budgetCents,
      usedCents: usedCents,
      daysPassed: passed,
      daysInMonth: totalDays,
    );
    final isOverBudgetNow = usedCents > budgetCents;

    return _AlertCard(
      icon: Icons.warning_amber_rounded,
      color: isOverBudgetNow
          ? theme.colorScheme.error
          : const Color(0xFFBA7517),
      backgroundColor:
          (isOverBudgetNow ? theme.colorScheme.error : const Color(0xFFBA7517))
              .withValues(alpha: 0.1),
      title: isOverBudgetNow ? '已超支' : '预计超支',
      message: suggestion > 0
          ? '按当前节奏预计超支 ${MoneyUtils.formatYuan(overage)}，建议日均控制在 ${MoneyUtils.formatYuan(suggestion)}'
          : '按当前节奏预计超支 ${MoneyUtils.formatYuan(overage)}',
    );
  }
}

class _AlertCard extends StatelessWidget {
  const _AlertCard({
    required this.icon,
    required this.color,
    required this.backgroundColor,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final Color color;
  final Color backgroundColor;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(message, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
