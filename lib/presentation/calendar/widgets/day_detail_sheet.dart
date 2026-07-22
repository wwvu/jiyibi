import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:jiyibi/core/theme/app_theme.dart';
import 'package:jiyibi/core/utils/money_utils.dart';
import 'package:jiyibi/data/database/app_database.dart';
import 'package:jiyibi/presentation/detail/widgets/record_list_tile.dart';
import 'package:jiyibi/presentation/editor/editor_sheet.dart';

/// 显示某日所有记录的底部弹层。
void showDayDetailSheet(
  BuildContext context,
  DateTime date,
  List<Record> records,
  Map<int, Category> categoryMap,
) {
  final rootContext = context;
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      final theme = Theme.of(context);
      final finance = theme.extension<FinanceColors>();
      final expense = records
          .where((record) => record.type == 'expense')
          .fold<int>(0, (sum, record) => sum + record.amountCents);
      final income = records
          .where((record) => record.type == 'income')
          .fold<int>(0, (sum, record) => sum + record.amountCents);
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Row(
                children: [
                  Text(
                    DateFormat('M月d日 EEE', 'zh_CN').format(date),
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${records.length} 笔',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (records.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _DayMetric(
                          label: '支出',
                          value: MoneyUtils.formatYuan(expense),
                          color: finance?.expense ?? theme.colorScheme.error,
                        ),
                      ),
                      Expanded(
                        child: _DayMetric(
                          label: '收入',
                          value: MoneyUtils.formatYuan(income),
                          color: finance?.income ?? theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (records.isEmpty)
              const Padding(padding: EdgeInsets.all(32), child: Text('当天无记录'))
            else
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.5,
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: records.length,
                  separatorBuilder: (_, _) => const Divider(indent: 72),
                  itemBuilder: (context, index) {
                    final record = records[index];
                    return RecordListTile(
                      record: record,
                      category: record.categoryId == null
                          ? null
                          : categoryMap[record.categoryId],
                      onTap: () {
                        Navigator.of(context).pop();
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (rootContext.mounted) {
                            showEditorSheetForEdit(rootContext, record);
                          }
                        });
                      },
                    );
                  },
                ),
              ),
            const SizedBox(height: 12),
          ],
        ),
      );
    },
  );
}

class _DayMetric extends StatelessWidget {
  const _DayMetric({
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
        const SizedBox(height: 3),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            style: theme.textTheme.titleSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}
