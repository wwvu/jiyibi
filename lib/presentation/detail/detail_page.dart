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
import 'package:jiyibi/shared/widgets/month_switcher.dart';

class DetailPage extends ConsumerStatefulWidget {
  const DetailPage({super.key});

  @override
  ConsumerState<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends ConsumerState<DetailPage> {
  String _filter = 'all';

  @override
  Widget build(BuildContext context) {
    final month = ref.watch(currentMonthProvider);
    final recordsAsync = ref.watch(monthRecordsProvider);
    final summaryAsync = ref.watch(monthSummaryProvider);
    final categoriesAsync = ref.watch(allCategoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Align(
          alignment: Alignment.centerLeft,
          child: Text('收支明细'),
        ),
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
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 6),
            child: Row(
              children: [
                MonthSwitcher(
                  month: month,
                  onPrevious: () => _changeMonth(month, -1),
                  onNext: () => _changeMonth(month, 1),
                ),
                const Spacer(),
                _FilterButton(
                  value: _filter,
                  onChanged: (value) => setState(() => _filter = value),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: summaryAsync.when(
              loading: () => const SizedBox(height: 132),
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
                  final filteredRecords = _filter == 'all'
                      ? records
                      : records
                            .where((record) => record.type == _filter)
                            .toList();
                  if (filteredRecords.isEmpty) {
                    return const _EmptyState();
                  }
                  final categoryMap = <int, Category>{
                    for (final category in categories) category.id: category,
                  };
                  return _RecordList(
                    records: filteredRecords,
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
    ref.invalidate(monthByDayProvider);
    ref.invalidate(monthExpenseByCategoryProvider);
    ref.invalidate(recordStatsProvider);
  }

  void _changeMonth(DateTime month, int delta) {
    ref
        .read(currentMonthProvider.notifier)
        .setMonth(DateTime(month.year, month.month + delta));
  }
}

class _FilterButton extends StatelessWidget {
  const _FilterButton({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final labels = {'all': '全部', 'expense': '支出', 'income': '收入'};
    return MenuAnchor(
      builder: (context, controller, child) {
        return OutlinedButton.icon(
          onPressed: () =>
              controller.isOpen ? controller.close() : controller.open(),
          icon: const Icon(Icons.filter_list_rounded, size: 18),
          label: Text(labels[value]!),
        );
      },
      menuChildren: [
        for (final entry in labels.entries)
          MenuItemButton(
            onPressed: () => onChanged(entry.key),
            leadingIcon: value == entry.key
                ? const Icon(Icons.check_rounded)
                : const SizedBox(width: 24),
            child: Text(entry.value),
          ),
      ],
    );
  }
}

class _RecordList extends StatefulWidget {
  const _RecordList({
    required this.records,
    required this.categoryMap,
    required this.onDelete,
  });

  final List<Record> records;
  final Map<int, Category> categoryMap;
  final Future<void> Function(Record record) onDelete;

  @override
  State<_RecordList> createState() => _RecordListState();
}

class _RecordListState extends State<_RecordList> {
  /// 已 dismiss 但 provider 尚未刷新的记录 id，需立刻从树中移除避免断言崩溃。
  final _dismissedIds = <int>{};

  @override
  void didUpdateWidget(_RecordList oldWidget) {
    super.didUpdateWidget(oldWidget);
    final currentIds = widget.records.map((r) => r.id).toSet();
    _dismissedIds.removeWhere((id) => !currentIds.contains(id));
  }

  @override
  Widget build(BuildContext context) {
    final visibleRecords = widget.records
        .where((record) => !_dismissedIds.contains(record.id))
        .toList();
    if (visibleRecords.isEmpty) {
      return const _EmptyState();
    }
    final grouped = _groupByDay(visibleRecords);

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 112),
      itemCount: grouped.length,
      itemBuilder: (context, index) {
        final entry = grouped[index];
        return _DayGroup(
          day: entry.day,
          date: entry.date,
          dayExpenseCents: entry.dayExpenseCents,
          records: entry.records,
          categoryMap: widget.categoryMap,
          onDelete: (record) {
            setState(() => _dismissedIds.add(record.id));
            return widget.onDelete(record);
          },
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
    final expenseColor = finance?.expense ?? theme.colorScheme.error;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(2, 12, 2, 8),
          child: Row(
            children: [
              Text(
                DateFormat('M月d日 EEE', 'zh_CN').format(date),
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                MoneyUtils.formatYuan(dayExpenseCents),
                style: theme.textTheme.labelLarge?.copyWith(
                  color: expenseColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        Card(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Column(
              children: [
                for (var i = 0; i < records.length; i++) ...[
                  Dismissible(
                    key: ValueKey(records[i].id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      color: theme.colorScheme.error,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 24),
                      child: Icon(
                        Icons.delete,
                        color: theme.colorScheme.onError,
                      ),
                    ),
                    confirmDismiss: (direction) =>
                        _confirmDelete(context, records[i]),
                    onDismissed: (direction) => onDelete(records[i]),
                    child: RecordListTile(
                      record: records[i],
                      category: records[i].categoryId == null
                          ? null
                          : categoryMap[records[i].categoryId],
                      onTap: () => showEditorSheetForEdit(context, records[i]),
                    ),
                  ),
                  if (i != records.length - 1)
                    Divider(
                      height: 1,
                      indent: 72,
                      color: theme.colorScheme.outlineVariant.withValues(
                        alpha: 0.62,
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),
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
