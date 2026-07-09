import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:jiyibi/core/providers.dart';
import 'package:jiyibi/core/theme/app_theme.dart';
import 'package:jiyibi/core/utils/money_utils.dart';
import 'package:jiyibi/data/database/app_database.dart';
import 'package:jiyibi/presentation/calendar/calendar_page.dart';
import 'package:jiyibi/presentation/detail/widgets/month_summary_card.dart';
import 'package:jiyibi/presentation/detail/widgets/record_list_tile.dart';
import 'package:jiyibi/presentation/editor/editor_sheet.dart';

class DetailPage extends ConsumerWidget {
  const DetailPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final month = ref.watch(currentMonthProvider);
    final recordsAsync = ref.watch(monthRecordsProvider);
    final summaryAsync = ref.watch(monthSummaryProvider);
    final categoriesAsync = ref.watch(expenseCategoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: _MonthSelector(month: month),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month_outlined),
            tooltip: '日历视图',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const CalendarPage()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: summaryAsync.when(
              loading: () => const SizedBox(height: 88),
              error: (error, _) => _ErrorBanner(message: '$error'),
              data: (summary) => MonthSummaryCard(
                expenseCents: summary.expenseCents,
                incomeCents: summary.incomeCents,
              ),
            ),
          ),
          Expanded(
            child: recordsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => _ErrorBanner(message: '$error'),
              data: (records) => categoriesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => _ErrorBanner(message: '$error'),
                data: (categories) {
                  if (records.isEmpty) {
                    return const _EmptyState();
                  }
                  final categoryMap = <int, Category>{
                    for (final category in categories) category.id: category,
                  };
                  return _RecordList(
                    records: records,
                    categoryMap: categoryMap,
                    onDelete: (record) => _deleteRecord(ref, record),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteRecord(WidgetRef ref, Record record) async {
    await ref.read(recordRepoProvider).delete(record.id);
    ref.invalidate(monthRecordsProvider);
    ref.invalidate(monthSummaryProvider);
    ref.invalidate(monthByCategoryProvider);
  }
}

class _MonthSelector extends ConsumerWidget {
  const _MonthSelector({required this.month});

  final DateTime month;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: () {
            final previous = DateTime(month.year, month.month - 1, 1);
            ref.read(currentMonthProvider.notifier).setMonth(previous);
          },
        ),
        Text(
          DateFormat('yyyy年M月').format(month),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: () {
            final next = DateTime(month.year, month.month + 1, 1);
            ref.read(currentMonthProvider.notifier).setMonth(next);
          },
        ),
      ],
    );
  }
}

class _RecordList extends StatelessWidget {
  const _RecordList({
    required this.records,
    required this.categoryMap,
    required this.onDelete,
  });

  final List<Record> records;
  final Map<int, Category> categoryMap;
  final Future<void> Function(Record record) onDelete;

  @override
  Widget build(BuildContext context) {
    final grouped = _groupByDay(records);

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 96),
      itemCount: grouped.length,
      itemBuilder: (context, index) {
        final entry = grouped[index];
        return _DayGroup(
          day: entry.day,
          date: entry.date,
          dayExpenseCents: entry.dayExpenseCents,
          records: entry.records,
          categoryMap: categoryMap,
          onDelete: onDelete,
        );
      },
    );
  }

  List<_DayGroupData> _groupByDay(List<Record> records) {
    final sorted = [...records]..sort((a, b) => b.date.compareTo(a.date));
    final map = <int, List<Record>>{};
    for (final record in sorted) {
      map.putIfAbsent(record.date.day, () => []).add(record);
    }

    return map.entries.map((entry) {
      final dayRecords = entry.value;
      final dayExpenseCents = dayRecords
          .where((r) => r.type == 'expense')
          .fold<int>(0, (sum, r) => sum + r.amountCents);
      return _DayGroupData(
        day: entry.key,
        date: dayRecords.first.date,
        dayExpenseCents: dayExpenseCents,
        records: dayRecords,
      );
    }).toList();
  }
}

class _DayGroupData {
  const _DayGroupData({
    required this.day,
    required this.date,
    required this.dayExpenseCents,
    required this.records,
  });

  final int day;
  final DateTime date;
  final int dayExpenseCents;
  final List<Record> records;
}

class _DayGroup extends StatelessWidget {
  const _DayGroup({
    required this.day,
    required this.date,
    required this.dayExpenseCents,
    required this.records,
    required this.categoryMap,
    required this.onDelete,
  });

  final int day;
  final DateTime date;
  final int dayExpenseCents;
  final List<Record> records;
  final Map<int, Category> categoryMap;
  final Future<void> Function(Record record) onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final finance = theme.extension<FinanceColors>();
    final expenseColor = finance?.expense ?? const Color(0xFFD85A30);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(
            children: [
              Text(
                DateFormat('M月d日 EEE', 'zh_CN').format(date),
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              Text(
                MoneyUtils.formatYuan(dayExpenseCents),
                style: theme.textTheme.labelLarge?.copyWith(
                  color: expenseColor,
                ),
              ),
            ],
          ),
        ),
        for (final record in records)
          Dismissible(
            key: ValueKey(record.id),
            direction: DismissDirection.endToStart,
            background: Container(
              color: theme.colorScheme.error,
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 24),
              child: Icon(Icons.delete, color: theme.colorScheme.onError),
            ),
            confirmDismiss: (direction) => _confirmDelete(context, record),
            onDismissed: (direction) => onDelete(record),
            child: RecordListTile(
              record: record,
              category: record.categoryId == null
                  ? null
                  : categoryMap[record.categoryId],
              onTap: () => showEditorSheetForEdit(context, record),
            ),
          ),
        const Divider(height: 1),
      ],
    );
  }

  Future<bool> _confirmDelete(BuildContext context, Record record) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('删除记录'),
          content: const Text('确定删除这条记录吗？删除后无法恢复。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('删除'),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 64,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text('本月还没有记录', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              '点击底部的 + 记一笔吧',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Text(
        '加载失败: $message',
        style: TextStyle(color: Theme.of(context).colorScheme.error),
      ),
    );
  }
}
