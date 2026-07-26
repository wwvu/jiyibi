import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:jiyibi/core/budget_predictor.dart';
import 'package:jiyibi/core/providers.dart';
import 'package:jiyibi/core/theme/app_theme.dart';
import 'package:jiyibi/core/utils/money_utils.dart';
import 'package:jiyibi/data/database/app_database.dart';
import 'package:jiyibi/presentation/budget/widgets/category_budget_bar.dart';
import 'package:jiyibi/shared/widgets/month_switcher.dart';
import 'package:jiyibi/shared/widgets/section_header.dart';

class BudgetPage extends ConsumerWidget {
  const BudgetPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final month = ref.watch(currentMonthProvider);
    final budgetsAsync = ref.watch(monthBudgetsProvider);
    final summaryAsync = ref.watch(monthSummaryProvider);
    final expenseByCategoryAsync = ref.watch(monthExpenseByCategoryProvider);
    final categoriesAsync = ref.watch(expenseCategoriesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('预算计划')),
      body: budgetsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('加载失败：$error')),
        data: (budgets) => summaryAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text('加载失败：$error')),
          data: (summary) => expenseByCategoryAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(child: Text('加载失败：$error')),
            data: (expenseByCategory) => categoriesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(child: Text('加载失败：$error')),
              data: (categories) => _BudgetContent(
                month: month,
                budgets: budgets,
                usedCents: summary.expenseCents,
                expenseByCategory: expenseByCategory,
                categories: categories,
                onChangeMonth: (delta) {
                  ref
                      .read(currentMonthProvider.notifier)
                      .setMonth(DateTime(month.year, month.month + delta));
                },
                onEdit:
                    ({
                      required int categoryId,
                      required int currentCents,
                      required String title,
                    }) => _editBudget(
                      context,
                      ref,
                      monthInt: month.year * 100 + month.month,
                      categoryId: categoryId,
                      currentCents: currentCents,
                      title: title,
                    ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _editBudget(
    BuildContext context,
    WidgetRef ref, {
    required int monthInt,
    required int categoryId,
    required int currentCents,
    required String title,
  }) async {
    final amountText = await showDialog<String>(
      context: context,
      builder: (context) => _BudgetAmountDialog(
        title: title,
        initialAmount: currentCents > 0
            ? MoneyUtils.formatYuanPlain(currentCents)
            : '',
      ),
    );
    if (amountText == null) return;

    await ref
        .read(budgetRepoProvider)
        .upsert(
          month: monthInt,
          categoryId: categoryId,
          amountCents: MoneyUtils.yuanToCents(amountText),
        );
    ref.invalidate(monthBudgetsProvider);
  }
}

class _BudgetAmountDialog extends StatefulWidget {
  const _BudgetAmountDialog({required this.title, required this.initialAmount});

  final String title;
  final String initialAmount;

  @override
  State<_BudgetAmountDialog> createState() => _BudgetAmountDialogState();
}

class _BudgetAmountDialogState extends State<_BudgetAmountDialog> {
  late final TextEditingController _controller;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialAmount);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          prefixText: '¥ ',
          hintText: '0.00',
          labelText: '每月预算',
          errorText: _errorText,
        ),
        autofocus: true,
        onChanged: (_) {
          if (_errorText != null) setState(() => _errorText = null);
        },
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        FilledButton(onPressed: _submit, child: const Text('保存')),
      ],
    );
  }

  void _submit() {
    final cents = MoneyUtils.yuanToCents(_controller.text);
    if (cents <= 0) {
      setState(() => _errorText = '请输入大于 0 的预算金额');
      return;
    }
    Navigator.of(context).pop(_controller.text);
  }
}

typedef _EditBudgetCallback =
    Future<void> Function({
      required int categoryId,
      required int currentCents,
      required String title,
    });

class _BudgetContent extends StatelessWidget {
  const _BudgetContent({
    required this.month,
    required this.budgets,
    required this.usedCents,
    required this.expenseByCategory,
    required this.categories,
    required this.onChangeMonth,
    required this.onEdit,
  });

  final DateTime month;
  final List<Budget> budgets;
  final int usedCents;
  final Map<int, int> expenseByCategory;
  final List<Category> categories;
  final ValueChanged<int> onChangeMonth;
  final _EditBudgetCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final totalBudget = _budgetForCategory(0);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: MonthSwitcher(
            month: month,
            onPrevious: () => onChangeMonth(-1),
            onNext: () => onChangeMonth(1),
          ),
        ),
        const SizedBox(height: 16),
        _BudgetHero(
          budgetCents: totalBudget,
          usedCents: usedCents,
          month: month,
          onEdit: () =>
              onEdit(categoryId: 0, currentCents: totalBudget, title: '设置总预算'),
        ),
        const SizedBox(height: 28),
        SectionHeader(
          title: '分类预算',
          subtitle: '给容易失控的类别单独设边界',
          actionLabel: '总预算',
          onAction: () =>
              onEdit(categoryId: 0, currentCents: totalBudget, title: '设置总预算'),
        ),
        const SizedBox(height: 10),
        if (categories.isEmpty)
          const Center(
            child: Padding(padding: EdgeInsets.all(28), child: Text('暂无支出分类')),
          )
        else
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                children: [
                  for (var i = 0; i < categories.length; i++) ...[
                    CategoryBudgetBar(
                      category: categories[i],
                      budgetCents: _budgetForCategory(categories[i].id),
                      usedCents: expenseByCategory[categories[i].id] ?? 0,
                      onTap: () => onEdit(
                        categoryId: categories[i].id,
                        currentCents: _budgetForCategory(categories[i].id),
                        title: '设置「${categories[i].name}」预算',
                      ),
                    ),
                    if (i != categories.length - 1) const Divider(indent: 66),
                  ],
                ],
              ),
            ),
          ),
      ],
    );
  }

  int _budgetForCategory(int categoryId) {
    return budgets
        .where((budget) => budget.categoryId == categoryId)
        .fold<int>(0, (sum, budget) => sum + budget.amountCents);
  }
}

class _BudgetHero extends StatelessWidget {
  const _BudgetHero({
    required this.budgetCents,
    required this.usedCents,
    required this.month,
    required this.onEdit,
  });

  final int budgetCents;
  final int usedCents;
  final DateTime month;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final finance = theme.extension<FinanceColors>();
    final expenseColor = finance?.expense ?? theme.colorScheme.error;
    if (budgetCents <= 0) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.savings_outlined, color: theme.colorScheme.primary),
            const SizedBox(height: 18),
            Text(
              '先给这个月一个边界',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            const Text('有了总预算，首页会每天计算“安心可花”和月末风险。'),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: onEdit,
              icon: const Icon(Icons.add_rounded),
              label: const Text('设置总预算'),
            ),
          ],
        ),
      );
    }

    final isCurrentMonth =
        DateTime.now().year == month.year &&
        DateTime.now().month == month.month;
    final referenceDay = isCurrentMonth
        ? DateTime.now()
        : DateTime(month.year, month.month + 1, 0);
    final daysInMonth = BudgetPredictor.daysInMonth(month.year, month.month);
    final daysPassed = BudgetPredictor.daysPassed(referenceDay, daysInMonth);
    final projected = BudgetPredictor.predictMonthEndCents(
      usedCents: usedCents,
      daysPassed: daysPassed,
      daysInMonth: daysInMonth,
    );
    final safeDaily = BudgetPredictor.suggestedDailyCents(
      budgetCents: budgetCents,
      usedCents: usedCents,
      daysPassed: daysPassed,
      daysInMonth: daysInMonth,
    );
    final remaining = budgetCents - usedCents;
    final isOver = remaining < 0;
    final progressPermille = usedCents * 1000 ~/ budgetCents;
    final statusColor = isOver ? theme.colorScheme.error : expenseColor;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                isOver ? '已超出预算' : '预算还剩',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: onEdit,
                tooltip: '编辑总预算',
                icon: const Icon(Icons.edit_outlined),
              ),
            ],
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              MoneyUtils.formatYuan(remaining.abs()),
              style: theme.textTheme.displaySmall?.copyWith(
                color: statusColor,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: (progressPermille / 1000).clamp(0.0, 1.0),
              minHeight: 10,
              color: statusColor,
              backgroundColor: statusColor.withValues(alpha: 0.12),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text('已用 ${MoneyUtils.formatYuan(usedCents)}'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text('预算 ${MoneyUtils.formatYuan(budgetCents)}'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _BudgetMetric(
                  label: '安心可花 / 天',
                  value: safeDaily > 0
                      ? MoneyUtils.formatYuan(safeDaily)
                      : '--',
                ),
              ),
              Expanded(
                child: _BudgetMetric(
                  label: '预计月末',
                  value: MoneyUtils.formatYuan(projected),
                ),
              ),
              Expanded(
                child: _BudgetMetric(
                  label: '预算进度',
                  value: '${progressPermille ~/ 10}%',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BudgetMetric extends StatelessWidget {
  const _BudgetMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}
