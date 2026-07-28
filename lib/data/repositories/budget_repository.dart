import 'package:drift/drift.dart';

import '../database/app_database.dart';

/// 预算数据访问层。总预算 categoryId=0，分类预算 categoryId=真实分类 id。
/// upsert 依赖 unique(month, categoryId) 约束。
class BudgetRepository {
  BudgetRepository(this._db);

  final AppDatabase _db;

  /// 查某月预算列表。包含总预算（categoryId=0）和各分类预算。
  Future<List<Budget>> getByMonth(int month) {
    return (_db.select(_db.budgets)..where((b) => b.month.equals(month))).get();
  }

  /// 查某月总预算（categoryId=0）。
  Future<Budget?> getTotalByMonth(int month) {
    return (_db.select(_db.budgets)
          ..where((b) => b.month.equals(month) & b.categoryId.equals(0)))
        .getSingleOrNull();
  }

  /// 查某月某分类预算。
  Future<Budget?> getCategoryBudget(int month, int categoryId) {
    return (_db.select(_db.budgets)..where(
          (b) => b.month.equals(month) & b.categoryId.equals(categoryId),
        ))
        .getSingleOrNull();
  }

  /// upsert 预算。同 (month, categoryId) 存在则更新，不存在则插入。
  /// categoryId=0 表示总预算。
  Future<void> upsert({
    required int month,
    required int categoryId,
    required int amountCents,
  }) async {
    final existing =
        await (_db.select(_db.budgets)..where(
              (b) => b.month.equals(month) & b.categoryId.equals(categoryId),
            ))
            .getSingleOrNull();

    if (existing == null) {
      await _db
          .into(_db.budgets)
          .insert(
            BudgetsCompanion.insert(
              month: month,
              amountCents: amountCents,
              categoryId: Value(categoryId),
            ),
          );
    } else {
      await (_db.update(_db.budgets)..where(
            (b) => b.month.equals(month) & b.categoryId.equals(categoryId),
          ))
          .write(BudgetsCompanion(amountCents: Value(amountCents)));
    }
  }

  /// 删除预算（物理删除，预算不需要软删除）。
  Future<int> delete(int month, int categoryId) {
    return (_db.delete(_db.budgets)..where(
          (b) => b.month.equals(month) & b.categoryId.equals(categoryId),
        ))
        .go();
  }

  /// 用来源月份完整替换目标月份预算，返回复制条数。
  Future<int> replaceMonth({
    required int sourceMonth,
    required int targetMonth,
  }) async {
    return _db.transaction(() async {
      final source = await getByMonth(sourceMonth);
      if (source.isEmpty) return 0;
      await (_db.delete(
        _db.budgets,
      )..where((budget) => budget.month.equals(targetMonth))).go();
      await _db.batch((batch) {
        batch.insertAll(
          _db.budgets,
          source
              .map(
                (budget) => BudgetsCompanion.insert(
                  month: targetMonth,
                  amountCents: budget.amountCents,
                  categoryId: Value(budget.categoryId),
                ),
              )
              .toList(),
        );
      });
      return source.length;
    });
  }
}
