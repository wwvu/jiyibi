import 'package:flutter/material.dart';

import 'package:jiyibi/core/theme/app_theme.dart';

class TypeSegmentedControl extends StatelessWidget {
  const TypeSegmentedControl({
    super.key,
    required this.type,
    required this.onChanged,
  });

  final String type;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final finance = theme.extension<FinanceColors>();
    final expense = finance?.expense ?? theme.colorScheme.error;
    final income = finance?.income ?? theme.colorScheme.primary;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh.withValues(alpha: 0.74),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: _Segment(
              label: '支出',
              selected: type == 'expense',
              color: expense,
              onTap: () => onChanged('expense'),
            ),
          ),
          Expanded(
            child: _Segment(
              label: '收入',
              selected: type == 'income',
              color: income,
              onTap: () => onChanged('income'),
            ),
          ),
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: selected ? color : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          height: 38,
          child: Center(
            child: Text(
              label,
              style: theme.textTheme.labelLarge?.copyWith(
                color: selected
                    ? theme.colorScheme.onPrimary
                    : theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
