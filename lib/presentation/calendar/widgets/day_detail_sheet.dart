import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:jiyibi/data/database/app_database.dart';
import 'package:jiyibi/presentation/detail/widgets/record_list_tile.dart';

/// 显示某日所有记录的底部弹层。
void showDayDetailSheet(
  BuildContext context,
  DateTime date,
  List<Record> records,
  Map<int, Category> categoryMap,
) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  Text(
                    DateFormat('M月d日 EEE', 'zh_CN').format(date),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const Spacer(),
                  Text(
                    '${records.length} 笔',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            if (records.isEmpty)
              const Padding(padding: EdgeInsets.all(32), child: Text('当天无记录'))
            else
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.5,
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: records.length,
                  itemBuilder: (context, index) {
                    final record = records[index];
                    return RecordListTile(
                      record: record,
                      category: record.categoryId == null
                          ? null
                          : categoryMap[record.categoryId],
                      onTap: () => Navigator.of(context).pop(),
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
