import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:jiyibi/core/providers.dart';
import 'package:jiyibi/core/theme/app_theme.dart';
import 'package:jiyibi/core/utils/money_utils.dart';
import 'package:jiyibi/data/database/app_database.dart';
import 'package:jiyibi/presentation/report/widgets/category_pie_chart.dart';
import 'package:jiyibi/presentation/report/widgets/daily_trend_chart.dart';
import 'package:jiyibi/shared/widgets/month_switcher.dart';
import 'package:jiyibi/shared/widgets/section_header.dart';
import 'package:jiyibi/shared/widgets/type_segmented_control.dart';

class ReportPage extends ConsumerStatefulWidget {
  const ReportPage({super.key});

  @override
  ConsumerState<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends ConsumerState<ReportPage> {
  String _type = 'expense';

  @override
  Widget build(BuildContext context) {
    final month = ref.watch(currentMonthProvider);
    final recordsAsync = ref.watch(monthRecordsProvider);
    final categoriesAsync = ref.watch(allCategoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Align(
          alignment: Alignment.centerLeft,
          child: Text('消费洞察'),
        ),
      ),
      body: recordsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('加载失败：$error')),
        data: (records) => categoriesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text('加载失败：$error')),
          data: (categories) => _buildBody(
            context,
            month: month,
            records: records,
            categories: categories,
          ),
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context, {
    required DateTime month,
    required List<Record> records,
    required List<Category> categories,
  }) {
    final theme = Theme.of(context);
    final finance = theme.extension<FinanceColors>();
    final accent = _type == 'expense'
        ? (finance?.expense ?? theme.colorScheme.error)
        : (finance?.income ?? theme.colorScheme.primary);
    final categoryById = <int, Category>{for (final c in categories) c.id: c};
    final typeRecords = records
        .where((record) => record.type == _type)
        .toList();
    final totalCents = typeRecords.fold<int>(
      0,
      (sum, record) => sum + record.amountCents,
    );

    final amountByCategory = <int, int>{};
    final amountByDay = <int, int>{};
    for (final record in typeRecords) {
      final categoryId = record.categoryId;
      if (categoryId != null) {
        amountByCategory[categoryId] =
            (amountByCategory[categoryId] ?? 0) + record.amountCents;
      }
      amountByDay[record.date.day] =
          (amountByDay[record.date.day] ?? 0) + record.amountCents;
    }

    final sections =
        amountByCategory.entries
            .map((entry) {
              final category = categoryById[entry.key];
              if (category == null) return null;
              return PieSection(
                label: category.name,
                amountCents: entry.value,
                color: Color(category.color),
              );
            })
            .whereType<PieSection>()
            .toList()
          ..sort((a, b) => b.amountCents.compareTo(a.amountCents));
    final byDay =
        amountByDay.entries
            .map((entry) => (day: entry.key, amountCents: entry.value))
            .toList()
          ..sort((a, b) => a.day.compareTo(b.day));
    final activeDays = amountByDay.length;
    final dailyAverage = activeDays == 0 ? 0 : totalCents ~/ activeDays;
    final peakDay = byDay.isEmpty
        ? null
        : byDay.reduce(
            (current, next) =>
                next.amountCents > current.amountCents ? next : current,
          );
    final topCategory = sections.isEmpty ? null : sections.first;
    final topShare = topCategory == null || totalCents == 0
        ? 0
        : topCategory.amountCents * 100 ~/ totalCents;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
      children: [
        Row(
          children: [
            MonthSwitcher(
              month: month,
              onPrevious: () => _changeMonth(month, -1),
              onNext: () => _changeMonth(month, 1),
              compact: true,
            ),
            const Spacer(),
            SizedBox(
              width: 154,
              child: TypeSegmentedControl(
                type: _type,
                onChanged: (type) => setState(() => _type = type),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        _NarrativeCard(
          type: _type,
          totalCents: totalCents,
          topCategory: topCategory,
          topShare: topShare,
          peakDay: peakDay,
          accent: accent,
        ),
        const SizedBox(height: 14),
        _MetricGrid(
          totalCents: totalCents,
          dailyAverageCents: dailyAverage,
          activeDays: activeDays,
          peakDay: peakDay,
          accent: accent,
          type: _type,
        ),
        const SizedBox(height: 28),
        const SectionHeader(title: '分类结构', subtitle: '看见钱主要流向哪里'),
        const SizedBox(height: 10),
        Card(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 14),
            child: Column(
              children: [
                CategoryPieChart(
                  sections: sections,
                  totalCents: totalCents,
                  centerLabel: _type == 'expense' ? '总支出' : '总收入',
                ),
                if (sections.isNotEmpty)
                  for (var i = 0; i < sections.length; i++)
                    _CategoryRankItem(
                      rank: i + 1,
                      section: sections[i],
                      totalCents: totalCents,
                    ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 28),
        const SectionHeader(title: '每日趋势', subtitle: '识别高峰日和消费节奏'),
        const SizedBox(height: 10),
        Card(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 18, 10, 10),
            child: DailyTrendChart(
              byDay: byDay,
              daysInMonth: DateTime(month.year, month.month + 1, 0).day,
              color: accent,
            ),
          ),
        ),
      ],
    );
  }

  void _changeMonth(DateTime month, int delta) {
    ref
        .read(currentMonthProvider.notifier)
        .setMonth(DateTime(month.year, month.month + delta));
  }
}

class _NarrativeCard extends StatelessWidget {
  const _NarrativeCard({
    required this.type,
    required this.totalCents,
    required this.topCategory,
    required this.topShare,
    required this.peakDay,
    required this.accent,
  });

  final String type;
  final int totalCents;
  final PieSection? topCategory;
  final int topShare;
  final ({int day, int amountCents})? peakDay;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isExpense = type == 'expense';
    final text = totalCents == 0
        ? '这个月还没有${isExpense ? '支出' : '收入'}数据，记下几笔后这里会自动生成结论。'
        : topCategory == null
        ? '本月共${isExpense ? '支出' : '收入'} ${MoneyUtils.formatYuan(totalCents)}。'
        : '${topCategory!.label}占了 $topShare%，是本月${isExpense ? '最主要的花费方向' : '最大的收入来源'}${peakDay == null ? '。' : '；${peakDay!.day}日是峰值日。'}';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(Icons.lightbulb_outline_rounded, color: accent),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '本月一句话',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: accent,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(text, style: theme.textTheme.bodyLarge),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({
    required this.totalCents,
    required this.dailyAverageCents,
    required this.activeDays,
    required this.peakDay,
    required this.accent,
    required this.type,
  });

  final int totalCents;
  final int dailyAverageCents;
  final int activeDays;
  final ({int day, int amountCents})? peakDay;
  final Color accent;
  final String type;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _MetricCard(
            label: type == 'expense' ? '总支出' : '总收入',
            value: MoneyUtils.formatYuan(totalCents),
            icon: Icons.payments_outlined,
            color: accent,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _MetricCard(
            label: '有记录日均',
            value: MoneyUtils.formatYuan(dailyAverageCents),
            icon: Icons.calendar_view_day_outlined,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _MetricCard(
            label: '峰值日',
            value: peakDay == null ? '--' : '${peakDay!.day}日',
            detail: '$activeDays 个活跃日',
            icon: Icons.stacked_line_chart_rounded,
            color: Theme.of(context).colorScheme.tertiary,
          ),
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.detail,
  });

  final String label;
  final String value;
  final String? detail;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 19),
          const SizedBox(height: 12),
          Text(
            label,
            maxLines: 1,
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
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          if (detail != null)
            Text(
              detail!,
              maxLines: 1,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }
}

class _CategoryRankItem extends StatelessWidget {
  const _CategoryRankItem({
    required this.rank,
    required this.section,
    required this.totalCents,
  });

  final int rank;
  final PieSection section;
  final int totalCents;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final share = totalCents == 0 ? 0 : section.amountCents * 100 ~/ totalCents;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 9),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            child: Text(
              '$rank',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: section.color,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 9),
          SizedBox(
            width: 50,
            child: Text(
              section.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: share / 100,
                minHeight: 7,
                color: section.color,
                backgroundColor: section.color.withValues(alpha: 0.12),
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 76,
            child: Text(
              MoneyUtils.formatYuan(section.amountCents),
              textAlign: TextAlign.right,
              maxLines: 1,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 34,
            child: Text(
              '$share%',
              textAlign: TextAlign.right,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
