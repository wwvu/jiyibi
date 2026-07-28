import 'package:flutter/material.dart';

import 'package:jiyibi/core/theme/app_theme.dart';
import 'package:jiyibi/core/utils/money_utils.dart';
import 'package:jiyibi/data/database/app_database.dart';
import 'package:jiyibi/shared/widgets/category_icon.dart';

/// 单条流水行：分类圆形图标 + 备注/分类名 + 右侧金额。
class RecordListTile extends StatelessWidget {
  const RecordListTile({
    super.key,
    required this.record,
    required this.category,
    this.account,
    required this.onTap,
  });

  final Record record;
  final Category? category;
  final Account? account;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final finance = theme.extension<FinanceColors>();
    final isExpense = record.type == 'expense';
    final amountColor = isExpense
        ? (finance?.expense ?? theme.colorScheme.error)
        : (finance?.income ?? theme.colorScheme.primary);

    final categoryName = category?.name ?? '未分类';
    final categoryColor = category != null
        ? Color(category!.color)
        : theme.colorScheme.outline;
    final title = record.note?.isNotEmpty == true ? record.note! : categoryName;
    final contextParts = <String>[
      categoryName,
      if (account != null) account!.name,
    ];

    return Material(
      color: theme.colorScheme.surface,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              CategoryIcon(
                name: categoryName,
                storedIcon: category?.icon,
                color: categoryColor,
                size: 44,
                iconSize: 22,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      contextParts.join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                MoneyUtils.formatYuan(record.amountCents),
                style: theme.textTheme.titleSmall?.copyWith(
                  color: amountColor,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
