/// 预算超支预测 -- 补鲨鱼记账最大缺口。全程 int 分整数运算，无浮点。
class BudgetPredictor {
  const BudgetPredictor._();

  /// 预测月末总支出（分）。
  /// [daysPassed] 含今天（如 7 月 15 日则传 15）。
  /// daysPassed <= 0 时返回 0。
  static int predictMonthEndCents({
    required int usedCents,
    required int daysPassed,
    required int daysInMonth,
  }) {
    if (daysPassed <= 0) return 0;
    final dailyAvg = usedCents ~/ daysPassed;
    return dailyAvg * daysInMonth;
  }

  /// 是否预测超支。
  static bool willExceed({
    required int predictedCents,
    required int budgetCents,
  }) {
    return predictedCents > budgetCents;
  }

  /// 预测超支金额（分）。未超支返回 0。
  static int overageCents({
    required int predictedCents,
    required int budgetCents,
  }) {
    final over = predictedCents - budgetCents;
    return over > 0 ? over : 0;
  }

  /// 建议日均支出（分）：剩余预算 / 剩余天数。
  /// 剩余天数 <= 0 或剩余预算 <= 0 返回 0。
  static int suggestedDailyCents({
    required int budgetCents,
    required int usedCents,
    required int daysPassed,
    required int daysInMonth,
  }) {
    final daysLeft = daysInMonth - daysPassed;
    if (daysLeft <= 0) return 0;
    final remaining = budgetCents - usedCents;
    if (remaining <= 0) return 0;
    return remaining ~/ daysLeft;
  }

  /// 当月天数。
  static int daysInMonth(int year, int month) {
    return DateTime(year, month + 1, 0).day;
  }

  /// 已过天数（含今天）。
  static int daysPassed(DateTime now, int daysInMonth) {
    if (now.day > daysInMonth) return daysInMonth;
    return now.day;
  }
}
