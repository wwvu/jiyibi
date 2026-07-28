import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:jiyibi/core/providers.dart';
import 'package:jiyibi/core/spending_pulse.dart';
import 'package:jiyibi/core/theme/app_theme.dart';
import 'package:jiyibi/core/utils/money_utils.dart';
import 'package:jiyibi/data/database/app_database.dart';
import 'package:jiyibi/presentation/budget/budget_page.dart';
import 'package:jiyibi/presentation/calendar/calendar_page.dart';
import 'package:jiyibi/presentation/detail/widgets/record_list_tile.dart';
import 'package:jiyibi/shared/widgets/section_header.dart';

class OverviewPage extends ConsumerWidget {
  const OverviewPage({
    super.key,
    required this.onShowDetails,
    required this.onShowInsights,
  });

  final VoidCallback onShowDetails;
  final VoidCallback onShowInsights;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recordsAsync = ref.watch(monthRecordsProvider);
    final budgetsAsync = ref.watch(monthBudgetsProvider);
    final categoriesAsync = ref.watch(allCategoriesProvider);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: recordsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _ErrorState(message: '$error'),
          data: (records) => budgetsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => _ErrorState(message: '$error'),
            data: (budgets) => categoriesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => _ErrorState(message: '$error'),
              data: (categories) => _OverviewContent(
                records: records,
                budgets: budgets,
                categories: categories,
                onShowDetails: onShowDetails,
                onShowInsights: onShowInsights,
                onOpenBudget: () => _openPage(context, ref, const BudgetPage()),
                onOpenCalendar: () =>
                    _openPage(context, ref, const CalendarPage()),
                onRefresh: () async {
                  ref.invalidate(monthRecordsProvider);
                  ref.invalidate(monthBudgetsProvider);
                  ref.invalidate(allCategoriesProvider);
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openPage(
    BuildContext context,
    WidgetRef ref,
    Widget page,
  ) async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => page));
    if (!context.mounted) return;
    final now = DateTime.now();
    ref
        .read(currentMonthProvider.notifier)
        .setMonth(DateTime(now.year, now.month));
  }
}

class _OverviewContent extends StatelessWidget {
  const _OverviewContent({
    required this.records,
    required this.budgets,
    required this.categories,
    required this.onShowDetails,
    required this.onShowInsights,
    required this.onOpenBudget,
    required this.onOpenCalendar,
    required this.onRefresh,
  });

  final List<Record> records;
  final List<Budget> budgets;
  final List<Category> categories;
  final VoidCallback onShowDetails;
  final VoidCallback onShowInsights;
  final VoidCallback onOpenBudget;
  final VoidCallback onOpenCalendar;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final categoryMap = <int, Category>{for (final c in categories) c.id: c};
    final monthExpense = records
        .where((record) => record.type == 'expense')
        .fold<int>(0, (sum, record) => sum + record.amountCents);
    final monthIncome = records
        .where((record) => record.type == 'income')
        .fold<int>(0, (sum, record) => sum + record.amountCents);
    final todayRecords = records.where((record) {
      return record.date.year == now.year &&
          record.date.month == now.month &&
          record.date.day == now.day;
    }).toList();
    final todayExpense = todayRecords
        .where((record) => record.type == 'expense')
        .fold<int>(0, (sum, record) => sum + record.amountCents);
    final totalBudget = budgets
        .where((budget) => budget.categoryId == 0)
        .fold<int>(0, (sum, budget) => sum + budget.amountCents);
    final pulse = SpendingPulse.calculate(
      budgetCents: totalBudget,
      monthExpenseCents: monthExpense,
      todayExpenseCents: todayExpense,
      now: now,
    );
    final topCategory = _topCategory(records, categoryMap);
    final activeDays = records
        .map(
          (record) =>
              DateTime(record.date.year, record.date.month, record.date.day),
        )
        .toSet()
        .length;
    final recentRecords = [...records]
      ..sort((a, b) => b.date.compareTo(a.date));
    final recentCount = recentRecords.length > 4 ? 4 : recentRecords.length;

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
        children: [
          _GreetingHeader(now: now),
          const SizedBox(height: 18),
          _PulseCard(
            pulse: pulse,
            todayExpenseCents: todayExpense,
            onSetBudget: onOpenBudget,
          ),
          const SizedBox(height: 14),
          _MonthBalanceStrip(
            expenseCents: monthExpense,
            incomeCents: monthIncome,
          ),
          const SizedBox(height: 14),
          _QuickActions(
            onBudget: onOpenBudget,
            onCalendar: onOpenCalendar,
            onInsights: onShowInsights,
          ),
          const SizedBox(height: 28),
          SectionHeader(
            title: '本月发现',
            subtitle: '从流水里提炼，不读取备注内容',
            actionLabel: '看洞察',
            onAction: onShowInsights,
          ),
          const SizedBox(height: 10),
          _InsightRow(
            topCategory: topCategory,
            activeDays: activeDays,
            recordCount: records.length,
          ),
          const SizedBox(height: 28),
          SectionHeader(
            title: '最近记录',
            subtitle: records.isEmpty ? '从第一笔开始建立自己的节奏' : '最近的消费与收入',
            actionLabel: records.isEmpty ? null : '全部',
            onAction: records.isEmpty ? null : onShowDetails,
          ),
          const SizedBox(height: 10),
          if (recentRecords.isEmpty)
            const _EmptyRecords()
          else
            Card(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Column(
                  children: [
                    for (var i = 0; i < recentCount; i++) ...[
                      RecordListTile(
                        record: recentRecords[i],
                        category: recentRecords[i].categoryId == null
                            ? null
                            : categoryMap[recentRecords[i].categoryId],
                        onTap: onShowDetails,
                      ),
                      if (i != recentCount - 1) const Divider(indent: 72),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  ({String name, int amountCents})? _topCategory(
    List<Record> records,
    Map<int, Category> categories,
  ) {
    final amounts = <int, int>{};
    for (final record in records.where((record) => record.type == 'expense')) {
      final id = record.categoryId;
      if (id == null) continue;
      amounts[id] = (amounts[id] ?? 0) + record.amountCents;
    }
    if (amounts.isEmpty) return null;
    final entry = amounts.entries.reduce(
      (current, next) => next.value > current.value ? next : current,
    );
    return (
      name: categories[entry.key]?.name ?? '未分类',
      amountCents: entry.value,
    );
  }
}

class _GreetingHeader extends StatelessWidget {
  const _GreetingHeader({required this.now});

  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final greeting = switch (now.hour) {
      < 6 => '夜深了',
      < 11 => '早上好',
      < 14 => '中午好',
      < 18 => '下午好',
      _ => '晚上好',
    };

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                greeting,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                DateFormat('M月d日 EEEE', 'zh_CN').format(now),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.account_balance_wallet_outlined,
            color: theme.colorScheme.primary,
          ),
        ),
      ],
    );
  }
}

class _PulseCard extends StatelessWidget {
  const _PulseCard({
    required this.pulse,
    required this.todayExpenseCents,
    required this.onSetBudget,
  });

  final SpendingPulse pulse;
  final int todayExpenseCents;
  final VoidCallback onSetBudget;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final finance = theme.extension<FinanceColors>();
    final statusColor = switch (pulse.level) {
      SpendingPulseLevel.unconfigured => theme.colorScheme.primary,
      SpendingPulseLevel.calm => finance?.income ?? theme.colorScheme.primary,
      SpendingPulseLevel.balanced => theme.colorScheme.primary,
      SpendingPulseLevel.watch => theme.colorScheme.tertiary,
      SpendingPulseLevel.over => theme.colorScheme.error,
    };
    final icon = switch (pulse.level) {
      SpendingPulseLevel.unconfigured => Icons.tune_rounded,
      SpendingPulseLevel.calm => Icons.wb_sunny_outlined,
      SpendingPulseLevel.balanced => Icons.balance_rounded,
      SpendingPulseLevel.watch => Icons.air_rounded,
      SpendingPulseLevel.over => Icons.thunderstorm_outlined,
    };

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Color.alphaBlend(
          statusColor.withValues(alpha: 0.055),
          theme.colorScheme.surface,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withValues(alpha: 0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: statusColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '今日财务气象',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      pulse.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(pulse.message, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 18),
          if (pulse.level == SpendingPulseLevel.unconfigured)
            FilledButton.icon(
              onPressed: onSetBudget,
              icon: const Icon(Icons.add_chart_rounded),
              label: const Text('设置本月预算'),
            )
          else ...[
            Row(
              children: [
                Expanded(
                  child: _PulseMetric(
                    label: '今日已花',
                    value: MoneyUtils.formatYuan(todayExpenseCents),
                  ),
                ),
                Expanded(
                  child: _PulseMetric(
                    label: pulse.safeDailyCents > 0 ? '安心可花 / 天' : '预算剩余',
                    value: MoneyUtils.formatYuan(
                      pulse.safeDailyCents > 0
                          ? pulse.safeDailyCents
                          : pulse.remainingCents,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: (pulse.budgetProgressPermille / 1000).clamp(0.0, 1.0),
                minHeight: 8,
                color: statusColor,
                backgroundColor: statusColor.withValues(alpha: 0.12),
              ),
            ),
            const SizedBox(height: 7),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '预算进度 ${pulse.budgetProgressPermille ~/ 10}%',
                  style: theme.textTheme.labelSmall,
                ),
                Text(
                  '时间进度 ${pulse.timeProgressPermille ~/ 10}%',
                  style: theme.textTheme.labelSmall,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _PulseMetric extends StatelessWidget {
  const _PulseMetric({required this.label, required this.value});

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
        const SizedBox(height: 3),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _MonthBalanceStrip extends StatelessWidget {
  const _MonthBalanceStrip({
    required this.expenseCents,
    required this.incomeCents,
  });

  final int expenseCents;
  final int incomeCents;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final finance = theme.extension<FinanceColors>();
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: _CompactMetric(
                label: '本月支出',
                value: MoneyUtils.formatYuan(expenseCents),
                color: finance?.expense ?? theme.colorScheme.error,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _CompactMetric(
                label: '本月收入',
                value: MoneyUtils.formatYuan(incomeCents),
                color: finance?.income ?? theme.colorScheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _CompactMetric(
                label: '结余',
                value: MoneyUtils.formatYuan(incomeCents - expenseCents),
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompactMetric extends StatelessWidget {
  const _CompactMetric({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

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
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({
    required this.onBudget,
    required this.onCalendar,
    required this.onInsights,
  });

  final VoidCallback onBudget;
  final VoidCallback onCalendar;
  final VoidCallback onInsights;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _QuickAction(
            icon: Icons.savings_outlined,
            label: '预算',
            onTap: onBudget,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _QuickAction(
            icon: Icons.calendar_month_outlined,
            label: '日历',
            onTap: onCalendar,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _QuickAction(
            icon: Icons.auto_graph_rounded,
            label: '洞察',
            onTap: onInsights,
          ),
        ),
      ],
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: theme.colorScheme.primary, size: 20),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InsightRow extends StatelessWidget {
  const _InsightRow({
    required this.topCategory,
    required this.activeDays,
    required this.recordCount,
  });

  final ({String name, int amountCents})? topCategory;
  final int activeDays;
  final int recordCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _InsightCard(
            icon: Icons.local_dining_outlined,
            label: '花得最多',
            value: topCategory?.name ?? '暂无',
            detail: topCategory == null
                ? '开始记账后生成'
                : MoneyUtils.formatYuan(topCategory!.amountCents),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _InsightCard(
            icon: Icons.event_available_outlined,
            label: '记账节奏',
            value: '$activeDays 天',
            detail: '$recordCount 笔记录',
          ),
        ),
      ],
    );
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.detail,
  });

  final IconData icon;
  final String label;
  final String value;
  final String detail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(height: 14),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            detail,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyRecords extends StatelessWidget {
  const _EmptyRecords();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.edit_note_rounded,
            size: 32,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              '记下第一笔，首页就会开始形成你的消费气象。',
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text('加载失败：$message'),
      ),
    );
  }
}
