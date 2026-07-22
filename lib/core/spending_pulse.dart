import 'package:jiyibi/core/budget_predictor.dart';

enum SpendingPulseLevel { unconfigured, calm, balanced, watch, over }

class SpendingPulse {
  const SpendingPulse({
    required this.level,
    required this.title,
    required this.message,
    required this.remainingCents,
    required this.safeDailyCents,
    required this.projectedCents,
    required this.budgetProgressPermille,
    required this.timeProgressPermille,
  });

  final SpendingPulseLevel level;
  final String title;
  final String message;
  final int remainingCents;
  final int safeDailyCents;
  final int projectedCents;
  final int budgetProgressPermille;
  final int timeProgressPermille;

  static SpendingPulse calculate({
    required int budgetCents,
    required int monthExpenseCents,
    required int todayExpenseCents,
    required DateTime now,
  }) {
    final daysInMonth = BudgetPredictor.daysInMonth(now.year, now.month);
    final daysPassed = BudgetPredictor.daysPassed(now, daysInMonth);

    if (budgetCents <= 0) {
      return const SpendingPulse(
        level: SpendingPulseLevel.unconfigured,
        title: '还没有消费边界',
        message: '设置月预算后，每天都会得到一条可执行的花钱建议。',
        remainingCents: 0,
        safeDailyCents: 0,
        projectedCents: 0,
        budgetProgressPermille: 0,
        timeProgressPermille: 0,
      );
    }

    final remaining = budgetCents - monthExpenseCents;
    final projected = BudgetPredictor.predictMonthEndCents(
      usedCents: monthExpenseCents,
      daysPassed: daysPassed,
      daysInMonth: daysInMonth,
    );
    final safeDaily = BudgetPredictor.suggestedDailyCents(
      budgetCents: budgetCents,
      usedCents: monthExpenseCents,
      daysPassed: daysPassed,
      daysInMonth: daysInMonth,
    );
    final budgetProgress = monthExpenseCents * 1000 ~/ budgetCents;
    final timeProgress = daysPassed * 1000 ~/ daysInMonth;

    if (remaining < 0) {
      return SpendingPulse(
        level: SpendingPulseLevel.over,
        title: '预算已经越线',
        message: '先暂停非必要支出，本月已超过预算。',
        remainingCents: remaining,
        safeDailyCents: 0,
        projectedCents: projected,
        budgetProgressPermille: budgetProgress,
        timeProgressPermille: timeProgress,
      );
    }

    final isProjectedOver = projected > budgetCents;
    final isTodayFast = safeDaily > 0 && todayExpenseCents > safeDaily;
    final isAheadOfTime = budgetProgress > timeProgress + 80;

    if (isProjectedOver || isAheadOfTime || isTodayFast) {
      return SpendingPulse(
        level: SpendingPulseLevel.watch,
        title: '今天需要收一点',
        message: '消费进度跑在时间前面，接下来按每日建议会更从容。',
        remainingCents: remaining,
        safeDailyCents: safeDaily,
        projectedCents: projected,
        budgetProgressPermille: budgetProgress,
        timeProgressPermille: timeProgress,
      );
    }

    if (budgetProgress + 120 < timeProgress) {
      return SpendingPulse(
        level: SpendingPulseLevel.calm,
        title: '财务气象晴朗',
        message: '消费节奏明显慢于时间进度，今天可以安心安排。',
        remainingCents: remaining,
        safeDailyCents: safeDaily,
        projectedCents: projected,
        budgetProgressPermille: budgetProgress,
        timeProgressPermille: timeProgress,
      );
    }

    return SpendingPulse(
      level: SpendingPulseLevel.balanced,
      title: '节奏刚刚好',
      message: '预算与时间进度基本同步，继续保持现在的消费节奏。',
      remainingCents: remaining,
      safeDailyCents: safeDaily,
      projectedCents: projected,
      budgetProgressPermille: budgetProgress,
      timeProgressPermille: timeProgress,
    );
  }
}
