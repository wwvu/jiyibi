import 'package:flutter/material.dart';

import 'package:jiyibi/core/utils/money_utils.dart';
import 'package:jiyibi/data/database/app_database.dart';

/// 分类预算条：分类名 + 已用/预算 + 进度条（超支变红）。
class CategoryBudgetBar extends StatelessWidget {
  const CategoryBudgetBar({
    super.key,
    required this.category,
    required this.budgetCents,
    required this.usedCents,
    required this.onTap,
  });

  final Category category;
  final int budgetCents;
  final int usedCents;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isOver = budgetCents > 0 && usedCents > budgetCents;
    final ratio = budgetCents > 0 ? (usedCents / budgetCents) : 0.0;
    final categoryColor = Color(category.color);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: categoryColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                category.icon,
                style: TextStyle(
                  color: categoryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(category.name, style: theme.textTheme.bodyLarge),
                      Text(
                        budgetCents > 0
                            ? '${MoneyUtils.formatYuan(usedCents)} / ${MoneyUtils.formatYuan(budgetCents)}'
                            : '未设置预算',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isOver
                              ? theme.colorScheme.error
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: budgetCents > 0 ? ratio.clamp(0.0, 1.0) : 0.0,
                      minHeight: 8,
                      backgroundColor:
                          (isOver ? theme.colorScheme.error : categoryColor)
                              .withValues(alpha: 0.15),
                      color: isOver ? theme.colorScheme.error : categoryColor,
                    ),
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
