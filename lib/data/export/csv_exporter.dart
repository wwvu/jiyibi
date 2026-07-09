import 'dart:convert';

import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/utils/money_utils.dart';
import '../database/app_database.dart';

/// CSV 导出。导出列：日期,类型,分类,金额(元),金额(分),备注,商户,来源。
class CsvExporter {
  const CsvExporter._();

  /// 导出全部记录为 CSV 文件并分享。
  /// [records] 已按日期倒序，[categoryMap] 用于分类名映射。
  static Future<void> exportAndShare({
    required List<Record> records,
    required Map<int, Category> categoryMap,
    int? year,
    int? month,
  }) async {
    final rows = <List<String>>[
      const ['日期', '类型', '分类', '金额(元)', '金额(分)', '备注', '商户', '来源'],
      for (final record in records) _rowFor(record, categoryMap),
    ];

    // 默认逗号分隔，自动加 BOM 让 Excel 正确识别 UTF-8。
    final csvData = Csv(addBom: true).encode(rows);
    final fileName = (year != null && month != null)
        ? '记一笔_$year${month.toString().padLeft(2, '0')}.csv'
        : '记一笔_全部.csv';

    final bytes = utf8.encode(csvData);

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile.fromData(bytes, mimeType: 'text/csv', name: fileName)],
        text: fileName,
      ),
    );
  }

  static List<String> _rowFor(Record record, Map<int, Category> categoryMap) {
    final category = record.categoryId == null
        ? null
        : categoryMap[record.categoryId!];

    return [
      DateFormat('yyyy-MM-dd').format(record.date),
      record.type == 'expense' ? '支出' : '收入',
      category?.name ?? '未分类',
      MoneyUtils.formatYuanPlain(record.amountCents),
      record.amountCents.toString(),
      record.note ?? '',
      record.merchant ?? '',
      record.source,
    ];
  }
}
