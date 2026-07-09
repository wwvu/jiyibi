import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:jiyibi/core/providers.dart';
import 'package:jiyibi/core/utils/money_utils.dart';
import 'package:jiyibi/data/database/app_database.dart';
import 'package:jiyibi/presentation/report/widgets/category_pie_chart.dart';
import 'package:jiyibi/presentation/report/widgets/daily_trend_chart.dart';

class ReportPage extends ConsumerStatefulWidget {
  const ReportPage({super.key});

  @override
  ConsumerState<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends ConsumerState<ReportPage> {
  String _type = 'expense'; // 'expense' | 'income'

  @override
  Widget build(BuildContext context) {
    final month = ref.watch(currentMonthProvider);
    final summaryAsync = ref.watch(monthSummaryProvider);
    final recordsAsync = ref.watch(monthRecordsProvider);
    final expenseCatsAsync = ref.watch(expenseCategoriesProvider);
    final incomeCatsAsync = ref.watch(incomeCategoriesProvider);

    final categoriesAsync = _type == 'expense'
        ? expenseCatsAsync
        : incomeCatsAsync;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: () {
                final previous = DateTime(month.year, month.month - 1, 1);
                ref.read(currentMonthProvider.notifier).setMonth(previous);
              },
            ),
            Text(DateFormat('yyyy年M月').format(month)),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: () {
                final next = DateTime(month.year, month.month + 1, 1);
                ref.read(currentMonthProvider.notifier).setMonth(next);
              },
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: summaryAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('加载失败: $error')),
        data: (summary) => recordsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text('加载失败: $error')),
          data: (records) => categoriesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(child: Text('加载失败: $error')),
            data: (categories) => _buildBody(
              context,
              summary: summary,
              records: records,
              categories: categories,
              month: month,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context, {
    required ({int expenseCents, int incomeCents}) summary,
    required List<Record> records,
    required List<Category> categories,
    required DateTime month,
  }) {
    final theme = Theme.of(context);
    final categoryById = <int, Category>{for (final c in categories) c.id: c};

    final typeRecords = records.where((r) => r.type == _type).toList();
    final totalCents = _type == 'expense'
        ? summary.expenseCents
        : summary.incomeCents;

    // 饼图 sections：按分类聚合
    final amountByCat = <int, int>{};
    for (final r in typeRecords) {
      final catId = r.categoryId;
      if (catId == null) continue;
      amountByCat[catId] = (amountByCat[catId] ?? 0) + r.amountCents;
    }
    final pieSections = <PieSection>[];
    for (final entry in amountByCat.entries) {
      final cat = categoryById[entry.key];
      if (cat == null) continue;
      pieSections.add(
        PieSection(
          label: cat.name,
          amountCents: entry.value,
          color: Color(cat.color),
        ),
      );
    }
    pieSections.sort((a, b) => b.amountCents.compareTo(a.amountCents));

    // 每日趋势：按日聚合
    final byDayMap = <int, int>{};
    for (final r in typeRecords) {
      byDayMap[r.date.day] = (byDayMap[r.date.day] ?? 0) + r.amountCents;
    }
    final byDay =
        byDayMap.entries.map((e) => (day: e.key, amountCents: e.value)).toList()
          ..sort((a, b) => a.day.compareTo(b.day));
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;

    return ListView(
      padding: const EdgeInsets.only(bottom: 96),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: _TypeToggle(
            type: _type,
            onChanged: (t) => setState(() => _type = t),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: _OverviewItem(
                      label: _type == 'expense' ? '总支出' : '总收入',
                      value: MoneyUtils.formatYuan(totalCents),
                      valueColor: _type == 'expense'
                          ? const Color(0xFFD85A30)
                          : const Color(0xFF3B6D11),
                    ),
                  ),
                  Container(width: 1, height: 36, color: theme.dividerColor),
                  Expanded(
                    child: _OverviewItem(
                      label: '结余',
                      value: MoneyUtils.formatYuan(
                        summary.incomeCents - summary.expenseCents,
                      ),
                      valueColor: theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Text('分类占比', style: theme.textTheme.titleSmall),
        ),
        CategoryPieChart(sections: pieSections, totalCents: totalCents),
        if (pieSections.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 12,
              runSpacing: 4,
              children: [
                for (final s in pieSections)
                  _LegendItem(label: s.label, color: s.color),
              ],
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 4),
          child: Text('每日趋势', style: theme.textTheme.titleSmall),
        ),
        DailyTrendChart(byDay: byDay, daysInMonth: daysInMonth),
      ],
    );
  }
}

class _TypeToggle extends StatelessWidget {
  const _TypeToggle({required this.type, required this.onChanged});

  final String type;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        children: [
          Expanded(
            child: _ToggleButton(
              label: '支出',
              isSelected: type == 'expense',
              color: const Color(0xFFD85A30),
              onTap: () => onChanged('expense'),
            ),
          ),
          Expanded(
            child: _ToggleButton(
              label: '收入',
              isSelected: type == 'income',
              color: const Color(0xFF3B6D11),
              onTap: () => onChanged('income'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ToggleButton extends StatelessWidget {
  const _ToggleButton({
    required this.label,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: theme.textTheme.titleSmall?.copyWith(
            color: isSelected
                ? theme.colorScheme.onPrimary
                : theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _OverviewItem extends StatelessWidget {
  const _OverviewItem({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
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
          child: Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              color: valueColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
