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
  final _searchController = TextEditingController();
  var _filter = const _RecordFilter();
  var _searchQuery = '';
  var _showSearch = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final month = ref.watch(currentMonthProvider);
    final recordsAsync = ref.watch(monthRecordsProvider);
    final summaryAsync = ref.watch(monthSummaryProvider);
    final categoriesAsync = ref.watch(allCategoriesProvider);
    final accountsAsync = ref.watch(allAccountsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Align(
          alignment: Alignment.centerLeft,
          child: Text('收支明细'),
        ),
        actions: [
          IconButton(
            icon: Icon(_showSearch ? Icons.search_off_rounded : Icons.search),
            tooltip: _showSearch ? '关闭搜索' : '搜索明细',
            onPressed: () {
              setState(() {
                _showSearch = !_showSearch;
                if (!_showSearch) {
                  _searchController.clear();
                  _searchQuery = '';
                }
              });
            },
          ),
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
                  activeCount: _filter.activeCount,
                  onTap: () => _showFilters(
                    context,
                    categoriesAsync.value,
                    accountsAsync.value,
                  ),
                ),
              ],
            ),
          ),
          if (_showSearch)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 6),
              child: SearchBar(
                controller: _searchController,
                autoFocus: true,
                hintText: '搜索备注、分类或账户',
                leading: const Icon(Icons.search, size: 20),
                trailing: [
                  if (_searchQuery.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      tooltip: '清空',
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    ),
                ],
                onChanged: (value) =>
                    setState(() => _searchQuery = value.trim().toLowerCase()),
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
                  final categoryMap = <int, Category>{
                    for (final category in categories) category.id: category,
                  };
                  final accountMap = <int, Account>{
                    for (final account in accountsAsync.value ?? <Account>[])
                      account.id: account,
                  };
                  final filteredRecords = records.where((record) {
                    if (_filter.type != 'all' && record.type != _filter.type) {
                      return false;
                    }
                    if (_filter.categoryId != null &&
                        record.categoryId != _filter.categoryId) {
                      return false;
                    }
                    if (_filter.accountId != null &&
                        record.accountId != _filter.accountId) {
                      return false;
                    }
                    if (_searchQuery.isEmpty) return true;
                    final categoryName =
                        categoryMap[record.categoryId]?.name ?? '';
                    return [
                      record.note ?? '',
                      categoryName,
                      accountMap[record.accountId]?.name ?? '',
                    ].any(
                      (value) => value.toLowerCase().contains(_searchQuery),
                    );
                  }).toList();
                  if (filteredRecords.isEmpty) {
                    return _EmptyState(isFiltered: _hasActiveQuery);
                  }
                  return _RecordList(
                    records: filteredRecords,
                    categoryMap: categoryMap,
                    accountMap: accountMap,
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
    ref.invalidateRecordDerivedProviders();
  }

  void _changeMonth(DateTime month, int delta) {
    ref
        .read(currentMonthProvider.notifier)
        .setMonth(DateTime(month.year, month.month + delta));
  }

  bool get _hasActiveQuery =>
      _searchQuery.isNotEmpty || _filter.activeCount > 0;

  Future<void> _showFilters(
    BuildContext context,
    List<Category>? categories,
    List<Account>? accounts,
  ) async {
    if (categories == null || accounts == null) return;
    final next = await showModalBottomSheet<_RecordFilter>(
      context: context,
      showDragHandle: true,
      builder: (context) => _FilterSheet(
        initial: _filter,
        categories: categories.where((category) => !category.archived).toList(),
        accounts: accounts.where((account) => !account.archived).toList(),
      ),
    );
    if (next != null && mounted) setState(() => _filter = next);
  }
}

class _FilterButton extends StatelessWidget {
  const _FilterButton({required this.activeCount, required this.onTap});

  final int activeCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: const Icon(Icons.filter_list_rounded, size: 18),
      label: Text(activeCount == 0 ? '筛选' : '筛选 $activeCount'),
    );
  }
}

class _RecordFilter {
  const _RecordFilter({this.type = 'all', this.categoryId, this.accountId});

  final String type;
  final int? categoryId;
  final int? accountId;

  int get activeCount =>
      (type == 'all' ? 0 : 1) +
      (categoryId == null ? 0 : 1) +
      (accountId == null ? 0 : 1);
}

class _FilterSheet extends StatefulWidget {
  const _FilterSheet({
    required this.initial,
    required this.categories,
    required this.accounts,
  });

  final _RecordFilter initial;
  final List<Category> categories;
  final List<Account> accounts;

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late String _type;
  int? _categoryId;
  int? _accountId;

  @override
  void initState() {
    super.initState();
    _type = widget.initial.type;
    _categoryId = widget.initial.categoryId;
    _accountId = widget.initial.accountId;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final visibleCategories = widget.categories
        .where((category) => _type == 'all' || category.type == _type)
        .toList();
    if (_categoryId != null &&
        !visibleCategories.any((category) => category.id == _categoryId)) {
      _categoryId = null;
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '筛选明细',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => setState(() {
                    _type = 'all';
                    _categoryId = null;
                    _accountId = null;
                  }),
                  child: const Text('重置'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'all', label: Text('全部')),
                ButtonSegment(value: 'expense', label: Text('支出')),
                ButtonSegment(value: 'income', label: Text('收入')),
              ],
              selected: {_type},
              showSelectedIcon: false,
              onSelectionChanged: (selected) => setState(() {
                _type = selected.first;
                _categoryId = null;
              }),
            ),
            const SizedBox(height: 20),
            Text(
              '分类',
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 180),
              child: SingleChildScrollView(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilterChip(
                      label: const Text('不限'),
                      selected: _categoryId == null,
                      onSelected: (_) => setState(() => _categoryId = null),
                    ),
                    for (final category in visibleCategories)
                      FilterChip(
                        avatar: Text(category.icon),
                        label: Text(category.name),
                        selected: _categoryId == category.id,
                        onSelected: (_) =>
                            setState(() => _categoryId = category.id),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              '账户',
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  FilterChip(
                    label: const Text('不限'),
                    selected: _accountId == null,
                    onSelected: (_) => setState(() => _accountId = null),
                  ),
                  for (final account in widget.accounts) ...[
                    const SizedBox(width: 8),
                    FilterChip(
                      avatar: Text(account.icon),
                      label: Text(account.name),
                      selected: _accountId == account.id,
                      onSelected: (_) =>
                          setState(() => _accountId = account.id),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(
                  _RecordFilter(
                    type: _type,
                    categoryId: _categoryId,
                    accountId: _accountId,
                  ),
                ),
                child: const Text('查看结果'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecordList extends StatefulWidget {
  const _RecordList({
    required this.records,
    required this.categoryMap,
    required this.accountMap,
    required this.onDelete,
  });

  final List<Record> records;
  final Map<int, Category> categoryMap;
  final Map<int, Account> accountMap;
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
          accountMap: widget.accountMap,
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
    required this.accountMap,
    required this.onDelete,
  });

  final int day;
  final DateTime date;
  final int dayExpenseCents;
  final List<Record> records;
  final Map<int, Category> categoryMap;
  final Map<int, Account> accountMap;
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
                      account: accountMap[records[i].accountId],
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
  const _EmptyState({this.isFiltered = false});

  final bool isFiltered;

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
            Text(
              isFiltered ? '没有符合条件的记录' : '本月还没有记录',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              isFiltered ? '换个关键词或调整筛选条件' : '点击底部的 + 记一笔吧',
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
