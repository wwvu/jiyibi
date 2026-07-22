import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jiyibi/core/providers.dart';
import 'package:jiyibi/core/utils/money_utils.dart';
import 'package:jiyibi/data/database/app_database.dart';
import 'package:jiyibi/presentation/calendar/widgets/calendar_grid.dart';
import 'package:jiyibi/presentation/calendar/widgets/day_detail_sheet.dart';
import 'package:jiyibi/shared/widgets/month_switcher.dart';

class CalendarPage extends ConsumerWidget {
  const CalendarPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final month = ref.watch(currentMonthProvider);
    final byDayAsync = ref.watch(monthByDayProvider);
    final recordsAsync = ref.watch(monthRecordsProvider);
    final categoriesAsync = ref.watch(allCategoriesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('消费日历')),
      body: byDayAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('加载失败: $error')),
        data: (byDayList) {
          final expenseByDay = <int, int>{
            for (final item in byDayList) item.day: item.amountCents,
          };
          final total = byDayList.fold<int>(
            0,
            (sum, item) => sum + item.amountCents,
          );
          final average = byDayList.isEmpty ? 0 : total ~/ byDayList.length;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: MonthSwitcher(
                  month: month,
                  onPrevious: () => _changeMonth(ref, month, -1),
                  onNext: () => _changeMonth(ref, month, 1),
                ),
              ),
              const SizedBox(height: 16),
              _CalendarSummary(
                totalCents: total,
                activeDays: byDayList.length,
                averageCents: average,
              ),
              const SizedBox(height: 14),
              Card(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 14),
                  child: CalendarGrid(
                    month: month,
                    expenseByDay: expenseByDay,
                    onDayTap: (day) => _showDay(
                      context,
                      month: month,
                      day: day,
                      recordsAsync: recordsAsync,
                      categoriesAsync: categoriesAsync,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _CalendarLegend(hasData: expenseByDay.isNotEmpty),
            ],
          );
        },
      ),
    );
  }

  void _changeMonth(WidgetRef ref, DateTime month, int delta) {
    ref
        .read(currentMonthProvider.notifier)
        .setMonth(DateTime(month.year, month.month + delta));
  }

  void _showDay(
    BuildContext context, {
    required DateTime month,
    required int day,
    required AsyncValue<List<Record>> recordsAsync,
    required AsyncValue<List<Category>> categoriesAsync,
  }) {
    final date = DateTime(month.year, month.month, day);
    final records = recordsAsync.value ?? [];
    final categories = categoriesAsync.value ?? [];
    final categoryMap = <int, Category>{for (final c in categories) c.id: c};
    final dayRecords = records
        .where(
          (r) =>
              r.date.year == date.year &&
              r.date.month == date.month &&
              r.date.day == date.day,
        )
        .toList();

    showDayDetailSheet(context, date, dayRecords, categoryMap);
  }
}

class _CalendarSummary extends StatelessWidget {
  const _CalendarSummary({
    required this.totalCents,
    required this.activeDays,
    required this.averageCents,
  });

  final int totalCents;
  final int activeDays;
  final int averageCents;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Expanded(
            child: _SummaryItem(
              label: '本月支出',
              value: MoneyUtils.formatYuan(totalCents),
            ),
          ),
          Expanded(
            child: _SummaryItem(label: '消费日', value: '$activeDays 天'),
          ),
          Expanded(
            child: _SummaryItem(
              label: '消费日均',
              value: MoneyUtils.formatYuan(averageCents),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  const _SummaryItem({required this.label, required this.value});

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

class _CalendarLegend extends StatelessWidget {
  const _CalendarLegend({required this.hasData});

  final bool hasData;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          hasData ? Icons.grid_view_rounded : Icons.info_outline,
          size: 15,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 6),
        Text(
          hasData ? '颜色越深，表示当天支出越高' : '记账后会形成消费热力日历',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
