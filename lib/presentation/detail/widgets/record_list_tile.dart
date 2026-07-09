import 'package:flutter/material.dart';

import 'package:jiyibi/core/theme/app_theme.dart';
import 'package:jiyibi/core/utils/money_utils.dart';
import 'package:jiyibi/data/database/app_database.dart';

/// 单条流水行：分类圆形图标 + 备注/分类名 + 右侧金额。
class RecordListTile extends StatelessWidget {
  const RecordListTile({
    super.key,
    required this.record,
    required this.category,
    required this.onTap,
  });

  final Record record;
  final Category? category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final finance = theme.extension<FinanceColors>();
    final isExpense = record.type == 'expense';
    final amountColor = isExpense
        ? (finance?.expense ?? const Color(0xFFD85A30))
        : (finance?.income ?? const Color(0xFF3B6D11));

    final categoryName = category?.name ?? '未分类';
    final categoryIcon = category?.icon ?? '？';
    final categoryColor = category != null
        ? Color(category!.color)
        : theme.colorScheme.outline;

    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: _CategoryBadge(icon: categoryIcon, color: categoryColor),
      title: Text(
        record.note?.isNotEmpty == true ? record.note! : categoryName,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.bodyLarge,
      ),
      subtitle: Text(
        categoryName,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: Text(
        MoneyUtils.formatYuan(record.amountCents),
        style: theme.textTheme.titleSmall?.copyWith(
          color: amountColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _CategoryBadge extends StatelessWidget {
  const _CategoryBadge({required this.icon, required this.color});

  final String icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        icon,
        style: TextStyle(
          fontSize: 18,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
