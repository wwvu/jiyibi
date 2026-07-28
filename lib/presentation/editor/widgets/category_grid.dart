import 'package:flutter/material.dart';

import 'package:jiyibi/data/database/app_database.dart';
import 'package:jiyibi/shared/widgets/category_icon.dart';

/// 分类网格：4 列，圆形图标 + 分类名，选中高亮。
class CategoryGrid extends StatelessWidget {
  const CategoryGrid({
    super.key,
    required this.categories,
    required this.selectedId,
    required this.onChanged,
  });

  final List<Category> categories;
  final int? selectedId;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: categories.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 0.9,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      itemBuilder: (context, index) {
        final category = categories[index];
        return _CategoryItem(
          category: category,
          isSelected: category.id == selectedId,
          onTap: () => onChanged(category.id),
        );
      },
    );
  }
}

class _CategoryItem extends StatelessWidget {
  const _CategoryItem({
    required this.category,
    required this.isSelected,
    required this.onTap,
  });

  final Category category;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = Color(category.color);

    return Material(
      color: isSelected
          ? color.withValues(alpha: 0.12)
          : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.42),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              CategoryIcon(
                name: category.name,
                storedIcon: category.icon,
                color: color,
                size: 42,
                iconSize: 21,
                selected: isSelected,
              ),
              const SizedBox(height: 6),
              Text(
                category.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isSelected
                      ? color
                      : theme.colorScheme.onSurfaceVariant,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
