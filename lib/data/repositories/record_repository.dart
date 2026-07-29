import 'package:drift/drift.dart';

import '../database/app_database.dart';

/// 流水数据访问层。所有金额返回 int 分，绝不 double。
class RecordRepository {
  RecordRepository(this._db);

  final AppDatabase _db;

  /// 新增手记。source 默认 'manual'，sourceId 传 null。
  Future<int> insert(RecordsCompanion data) {
    return _db.into(_db.records).insert(data);
  }

  /// 批量导入去重：先查已有 sourceId 集合，过滤 DB 已有 + rows 内部重复。
  /// 应用层过滤是性能优化；DB 唯一约束是兜底。
  Future<int> batchInsertIfNew(List<RecordsCompanion> rows) async {
    final sourceIds = rows
        .map((row) => row.sourceId.value)
        .whereType<String>()
        .toSet();

    final existing = await getExistingSourceIds(sourceIds);

    final seen = <String>{};
    final toInsert = <RecordsCompanion>[];

    for (final row in rows) {
      final sourceId = row.sourceId.value;
      if (sourceId == null) {
        toInsert.add(row);
      } else if (!existing.contains(sourceId) && !seen.contains(sourceId)) {
        toInsert.add(row);
        seen.add(sourceId);
      }
    }

    if (toInsert.isEmpty) return 0;

    await _db.batch((batch) {
      batch.insertAll(_db.records, toInsert);
    });

    return toInsert.length;
  }

  /// 编辑记录，同步更新 updatedAt。
  Future<int> update(int id, RecordsCompanion patch) {
    return (_db.update(_db.records)..where((r) => r.id.equals(id))).write(
      patch.copyWith(updatedAt: Value(DateTime.now())),
    );
  }

  /// 删除记录。
  Future<int> delete(int id) {
    return (_db.delete(_db.records)..where((r) => r.id.equals(id))).go();
  }

  /// 查全部记录，按日期倒序。CSV 导出 / 统计用。
  Future<List<Record>> getAll() {
    return (_db.select(
      _db.records,
    )..orderBy([(r) => OrderingTerm.desc(r.date)])).get();
  }

  /// 查某月全部记录，按日期倒序。半开区间 [start, nextMonthStart)。
  Future<List<Record>> getRecordsByMonth(int year, int month) {
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 1);

    return (_db.select(_db.records)
          ..where((r) => r.date.isBiggerOrEqualValue(start))
          ..where((r) => r.date.isSmallerThanValue(end))
          ..orderBy([(r) => OrderingTerm.desc(r.date)]))
        .get();
  }

  /// 查某日记录。
  Future<List<Record>> getRecordsByDay(DateTime date) {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));

    return (_db.select(_db.records)
          ..where((r) => r.date.isBiggerOrEqualValue(start))
          ..where((r) => r.date.isSmallerThanValue(end))
          ..orderBy([(r) => OrderingTerm.desc(r.date)]))
        .get();
  }

  /// 当月总支出/总收入（int 分）。整数 SUM，不转 double。
  Future<({int expenseCents, int incomeCents})> getMonthSummary(
    int year,
    int month,
  ) async {
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 1);

    final expense = await _sumAmount(start: start, end: end, type: 'expense');
    final income = await _sumAmount(start: start, end: end, type: 'income');

    return (expenseCents: expense, incomeCents: income);
  }

  /// 按分类统计当月支出（只统计未归档分类）。
  Future<List<({String category, int amountCents})>> getMonthByCategory(
    int year,
    int month,
  ) async {
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 1);
    final query =
        _db.selectOnly(_db.records).join([
            innerJoin(
              _db.categories,
              _db.categories.id.equalsExp(_db.records.categoryId),
            ),
          ])
          ..where(
            _db.records.date.isBiggerOrEqualValue(start) &
                _db.records.date.isSmallerThanValue(end) &
                _db.records.type.equals('expense') &
                _db.categories.archived.equals(false),
          )
          ..addColumns([_db.categories.name, _db.records.amountCents.sum()])
          ..groupBy([_db.categories.name]);

    final rows = await query.get();

    return rows.map((row) {
      return (
        category: row.read(_db.categories.name)!,
        amountCents: row.read(_db.records.amountCents.sum()) ?? 0,
      );
    }).toList();
  }

  /// 按日统计当月支出（趋势图用）。在 Dart 侧按日分组，避免 DateTime
  /// 含时分秒导致 groupBy 失效。
  Future<List<({int day, int amountCents})>> getMonthByDay(
    int year,
    int month,
  ) async {
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 1);

    final records =
        await (_db.select(_db.records)..where(
              (r) =>
                  r.date.isBiggerOrEqualValue(start) &
                  r.date.isSmallerThanValue(end) &
                  r.type.equals('expense'),
            ))
            .get();

    final byDay = <int, int>{};
    for (final record in records) {
      byDay[record.date.day] =
          (byDay[record.date.day] ?? 0) + record.amountCents;
    }

    final result =
        byDay.entries
            .map((entry) => (day: entry.key, amountCents: entry.value))
            .toList()
          ..sort((a, b) => a.day.compareTo(b.day));

    return result;
  }

  /// 按分类 id 统计当月支出（预算页用）。返回 categoryId -> 分。
  Future<Map<int, int>> getMonthExpenseByCategoryIds(
    int year,
    int month,
  ) async {
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 1);

    final query =
        _db.selectOnly(_db.records).join([
            innerJoin(
              _db.categories,
              _db.categories.id.equalsExp(_db.records.categoryId),
            ),
          ])
          ..where(
            _db.records.date.isBiggerOrEqualValue(start) &
                _db.records.date.isSmallerThanValue(end) &
                _db.records.type.equals('expense') &
                _db.categories.archived.equals(false),
          )
          ..addColumns([_db.categories.id, _db.records.amountCents.sum()])
          ..groupBy([_db.categories.id]);

    final rows = await query.get();

    return {
      for (final row in rows)
        row.read(_db.categories.id)!:
            row.read(_db.records.amountCents.sum()) ?? 0,
    };
  }

  /// 统计：总记录数、记账天数（有记录的不同日期数）、连续记账天数（从今天往前）。
  ///
  /// 只查 date 列并用 SQL 聚合，避免全表加载所有字段。
  Future<({int totalRecords, int distinctDays, int currentStreak})>
  getStats() async {
    final countRow = await (_db.selectOnly(_db.records)
          ..addColumns([_db.records.id.count()]))
        .getSingle();
    final totalRecords = countRow.read(_db.records.id.count()) ?? 0;

    // SQL 层 SELECT DISTINCT date，只拉日期列，避免全表加载所有字段。
    final dateRows = await (_db.selectOnly(_db.records, distinct: true)
          ..addColumns([_db.records.date]))
        .get();

    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    final distinctDates = <DateTime>{
      for (final row in dateRows)
        DateTime(
          row.read(_db.records.date)!.year,
          row.read(_db.records.date)!.month,
          row.read(_db.records.date)!.day,
        ),
    };

    var streak = 0;
    var cursor = todayDate;
    // 如果今天还没记，从昨天开始算连续（容错：今天还没记账不算断）
    if (!distinctDates.contains(cursor)) {
      cursor = cursor.subtract(const Duration(days: 1));
    }
    while (distinctDates.contains(cursor)) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }

    return (
      totalRecords: totalRecords,
      distinctDays: distinctDates.length,
      currentStreak: streak,
    );
  }

  /// 查已有 sourceId 集合（导入去重判断）。
  Future<Set<String>> getExistingSourceIds(Set<String> sourceIds) async {
    if (sourceIds.isEmpty) return {};

    final query = _db.selectOnly(_db.records)
      ..addColumns([_db.records.sourceId])
      ..where(
        _db.records.sourceId.isIn(sourceIds) & _db.records.sourceId.isNotNull(),
      );

    final rows = await query.get();

    return rows
        .map((row) => row.read(_db.records.sourceId))
        .whereType<String>()
        .toSet();
  }

  Future<int> _sumAmount({
    required DateTime start,
    required DateTime end,
    required String type,
  }) async {
    final query = _db.selectOnly(_db.records)
      ..addColumns([_db.records.amountCents.sum()])
      ..where(
        _db.records.date.isBiggerOrEqualValue(start) &
            _db.records.date.isSmallerThanValue(end) &
            _db.records.type.equals(type),
      );

    final row = await query.getSingle();

    return row.read(_db.records.amountCents.sum()) ?? 0;
  }
}
