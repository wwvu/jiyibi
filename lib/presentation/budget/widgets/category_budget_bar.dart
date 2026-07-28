import 'package:flutter/material.dart';

import 'package:jiyibi/core/utils/money_utils.dart';
import 'package:jiyibi/data/database/app_database.dart';
import 'package:jiyibi/shared/widgets/category_icon.dart';

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

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          child: Row(
            children: [
              CategoryIcon(
                name: category.name,
                storedIcon: category.icon,
                color: categoryColor,
                size: 34,
                iconSize: 18,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            category.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerRight,
                            child: Text(
                              budgetCents > 0
                                  ? '${MoneyUtils.formatYuan(usedCents)} / ${MoneyUtils.formatYuan(budgetCents)}'
                                  : '未设置预算',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: isOver
                                    ? theme.colorScheme.error
                                    : theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: budgetCents > 0 ? ratio.clamp(0.0, 1.0) : 0.0,
                        minHeight: 7,
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
      ),
    );
  }
}
