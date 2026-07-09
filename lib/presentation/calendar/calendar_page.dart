import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:jiyibi/core/providers.dart';
import 'package:jiyibi/data/database/app_database.dart';
import 'package:jiyibi/presentation/calendar/widgets/calendar_grid.dart';
import 'package:jiyibi/presentation/calendar/widgets/day_detail_sheet.dart';

class CalendarPage extends ConsumerWidget {
  const CalendarPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final month = ref.watch(currentMonthProvider);
    final byDayAsync = ref.watch(monthByDayProvider);
    final recordsAsync = ref.watch(monthRecordsProvider);
    final categoriesAsync = ref.watch(expenseCategoriesProvider);

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
      body: byDayAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('加载失败: $error')),
        data: (byDayList) {
          final expenseByDay = <int, int>{
            for (final item in byDayList) item.day: item.amountCents,
          };
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
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
          );
        },
      ),
    );
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
