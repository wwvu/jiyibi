import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:jiyibi/core/providers.dart';
import 'package:jiyibi/core/utils/money_utils.dart';
import 'package:jiyibi/data/database/app_database.dart';
import 'package:jiyibi/presentation/budget/widgets/budget_ring.dart';
import 'package:jiyibi/presentation/budget/widgets/category_budget_bar.dart';
import 'package:jiyibi/presentation/budget/widgets/overspend_alert.dart';

class BudgetPage extends ConsumerWidget {
  const BudgetPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final month = ref.watch(currentMonthProvider);
    final monthInt = month.year * 100 + month.month;
    final budgetsAsync = ref.watch(monthBudgetsProvider);
    final summaryAsync = ref.watch(monthSummaryProvider);
    final expenseByCatAsync = ref.watch(monthExpenseByCategoryProvider);
    final categoriesAsync = ref.watch(expenseCategoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(DateFormat('yyyy年M月 预算').format(month)),
        centerTitle: true,
      ),
      body: budgetsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('加载失败: $error')),
        data: (budgets) {
          final totalBudget = budgets
              .where((b) => b.categoryId == 0)
              .fold<int>(0, (sum, b) => sum + b.amountCents);

          return ListView(
            children: [
              if (totalBudget > 0)
                summaryAsync.when(
                  loading: () => const SizedBox.shrink(),
                  error: (error, _) => const SizedBox.shrink(),
                  data: (summary) => OverspendAlert(
                    budgetCents: totalBudget,
                    usedCents: summary.expenseCents,
                    now: DateTime.now(),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                child: summaryAsync.when(
                  loading: () => const SizedBox(height: 180),
                  error: (error, _) => Text('支出加载失败: $error'),
                  data: (summary) => GestureDetector(
                    onTap: () => _editBudget(
                      context,
                      ref,
                      monthInt: monthInt,
                      categoryId: 0,
                      currentCents: totalBudget,
                      title: '设置总预算',
                    ),
                    child: BudgetRing(
                      budgetCents: totalBudget,
                      usedCents: summary.expenseCents,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  '分类预算',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              expenseByCatAsync.when(
                loading: () => const SizedBox(height: 100),
                error: (error, _) => Text('分类支出加载失败: $error'),
                data: (expenseByCat) => categoriesAsync.when(
                  loading: () => const SizedBox(height: 100),
                  error: (error, _) => Text('分类加载失败: $error'),
                  data: (categories) {
                    if (categories.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(child: Text('暂无支出分类')),
                      );
                    }
                    return Column(
                      children: [
                        for (final category in categories)
                          CategoryBudgetBar(
                            category: category,
                            budgetCents: _budgetForCategory(
                              budgets,
                              category.id,
                            ),
                            usedCents: expenseByCat[category.id] ?? 0,
                            onTap: () => _editBudget(
                              context,
                              ref,
                              monthInt: monthInt,
                              categoryId: category.id,
                              currentCents: _budgetForCategory(
                                budgets,
                                category.id,
                              ),
                              title: '设置「${category.name}」预算',
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 80),
            ],
          );
        },
      ),
    );
  }

  int _budgetForCategory(List<Budget> budgets, int categoryId) {
    return budgets
        .where((b) => b.categoryId == categoryId)
        .fold<int>(0, (sum, b) => sum + b.amountCents);
  }

  Future<void> _editBudget(
    BuildContext context,
    WidgetRef ref, {
    required int monthInt,
    required int categoryId,
    required int currentCents,
    required String title,
  }) async {
    final controller = TextEditingController(
      text: currentCents > 0 ? MoneyUtils.formatYuanPlain(currentCents) : '',
    );

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              prefixText: '¥ ',
              hintText: '0.00',
              border: OutlineInputBorder(),
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('保存'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    final amountCents = MoneyUtils.yuanToCents(controller.text);
    await ref
        .read(budgetRepoProvider)
        .upsert(
          month: monthInt,
          categoryId: categoryId,
          amountCents: amountCents,
        );
    ref.invalidate(monthBudgetsProvider);
  }
}
