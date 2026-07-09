import 'package:flutter/material.dart';

import 'package:jiyibi/core/utils/money_utils.dart';

/// 月历网格：7 列，每天显示日期 + 支出金额（小字红色）。今天圆形高亮。
class CalendarGrid extends StatelessWidget {
  const CalendarGrid({
    super.key,
    required this.month,
    required this.expenseByDay,
    required this.onDayTap,
  });

  final DateTime month;
  final Map<int, int> expenseByDay;
  final ValueChanged<int> onDayTap;

  @override
  Widget build(BuildContext context) {
    final firstOfMonth = DateTime(month.year, month.month, 1);
    // 周一=1 ... 周日=7，网格以周日起始。
    final leadingBlanks = firstOfMonth.weekday % 7;
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final today = DateTime.now();
    final isCurrentMonth =
        today.year == month.year && today.month == month.month;

    final cells = <Widget>[];
    for (var i = 0; i < leadingBlanks; i++) {
      cells.add(const SizedBox.shrink());
    }
    for (var day = 1; day <= daysInMonth; day++) {
      final expense = expenseByDay[day] ?? 0;
      final isToday = isCurrentMonth && day == today.day;
      cells.add(
        _DayCell(
          day: day,
          expenseCents: expense,
          isToday: isToday,
          onTap: () => onDayTap(day),
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Row(
            children: [
              for (final label in const ['日', '一', '二', '三', '四', '五', '六'])
                Expanded(
                  child: Center(
                    child: Text(
                      label,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        GridView.count(
          crossAxisCount: 7,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 0.85,
          children: cells,
        ),
      ],
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.expenseCents,
    required this.isToday,
    required this.onTap,
  });

  final int day;
  final int expenseCents;
  final bool isToday;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isToday ? colorScheme.primary : null,
            ),
            child: Text(
              '$day',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isToday ? colorScheme.onPrimary : colorScheme.onSurface,
                fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          const SizedBox(height: 2),
          if (expenseCents > 0)
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                MoneyUtils.formatYuan(expenseCents),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: const Color(0xFFD85A30),
                ),
              ),
            )
          else
            const SizedBox(height: 12),
        ],
      ),
    );
  }
}
