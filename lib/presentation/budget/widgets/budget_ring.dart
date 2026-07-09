import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:jiyibi/core/theme/app_theme.dart';
import 'package:jiyibi/core/utils/money_utils.dart';

/// 总预算环形进度：预算 vs 已支出，百分比居中。
class BudgetRing extends StatelessWidget {
  const BudgetRing({
    super.key,
    required this.budgetCents,
    required this.usedCents,
  });

  final int budgetCents;
  final int usedCents;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final finance = theme.extension<FinanceColors>();
    final expenseColor = finance?.expense ?? const Color(0xFFD85A30);
    final isOver = budgetCents > 0 && usedCents > budgetCents;
    final ratio = budgetCents > 0 ? (usedCents / budgetCents) : 0.0;

    return Center(
      child: SizedBox(
        width: 180,
        height: 180,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CustomPaint(
              size: const Size(180, 180),
              painter: _RingPainter(
                progress: ratio.clamp(0.0, 1.0),
                color: isOver ? theme.colorScheme.error : expenseColor,
                trackColor: (isOver ? theme.colorScheme.error : expenseColor)
                    .withValues(alpha: 0.15),
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  budgetCents > 0
                      ? '${(ratio * 100).toStringAsFixed(0)}%'
                      : '未设置',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isOver ? theme.colorScheme.error : null,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  budgetCents > 0
                      ? '已用 ${MoneyUtils.formatYuan(usedCents)}'
                      : '点击设置预算',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                if (budgetCents > 0)
                  Text(
                    '预算 ${MoneyUtils.formatYuan(budgetCents)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
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

class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.progress,
    required this.color,
    required this.trackColor,
  });

  final double progress;
  final Color color;
  final Color trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 16) / 2;

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = trackColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 12,
    );

    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawArc(
      rect,
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 12
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.trackColor != trackColor;
  }
}
