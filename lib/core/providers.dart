import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database/app_database.dart';
import '../data/repositories/account_repository.dart';
import '../data/repositories/budget_repository.dart';
import '../data/repositories/category_repository.dart';
import '../data/repositories/record_repository.dart';

/// 数据库单例。
final databaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase();
  ref.onDispose(database.close);
  return database;
});

/// Repository 依赖注入。UI 层不直接碰 Database。
final recordRepoProvider = Provider<RecordRepository>((ref) {
  return RecordRepository(ref.read(databaseProvider));
});

final categoryRepoProvider = Provider<CategoryRepository>((ref) {
  return CategoryRepository(ref.read(databaseProvider));
});

final budgetRepoProvider = Provider<BudgetRepository>((ref) {
  return BudgetRepository(ref.read(databaseProvider));
});

final accountRepoProvider = Provider<AccountRepository>((ref) {
  return AccountRepository(ref.read(databaseProvider));
});

/// 当前选中月份（明细/日历/报表共用）。
final currentMonthProvider = NotifierProvider<CurrentMonthController, DateTime>(
  CurrentMonthController.new,
);

class CurrentMonthController extends Notifier<DateTime> {
  @override
  DateTime build() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, 1);
  }

  void setMonth(DateTime month) {
    state = DateTime(month.year, month.month, 1);
  }
}

/// 当月记录列表。
final monthRecordsProvider = FutureProvider<List<Record>>((ref) async {
  final month = ref.watch(currentMonthProvider);
  return ref
      .read(recordRepoProvider)
      .getRecordsByMonth(month.year, month.month);
});

/// 当月收支汇总（int 分）。
final monthSummaryProvider =
    FutureProvider<({int expenseCents, int incomeCents})>((ref) async {
      final month = ref.watch(currentMonthProvider);
      return ref
          .read(recordRepoProvider)
          .getMonthSummary(month.year, month.month);
    });

/// 当月按日统计（趋势图 / 日历用）。
final monthByDayProvider = FutureProvider<List<({int day, int amountCents})>>((
  ref,
) async {
  final month = ref.watch(currentMonthProvider);
  return ref.read(recordRepoProvider).getMonthByDay(month.year, month.month);
});

/// 当月按分类统计。
final monthByCategoryProvider =
    FutureProvider<List<({String category, int amountCents})>>((ref) async {
      final month = ref.watch(currentMonthProvider);
      return ref
          .read(recordRepoProvider)
          .getMonthByCategory(month.year, month.month);
    });

/// 支出分类列表（不含归档）。
final expenseCategoriesProvider = FutureProvider<List<Category>>((ref) async {
  return ref.read(categoryRepoProvider).getAll(type: 'expense');
});

/// 收入分类列表（不含归档）。
final incomeCategoriesProvider = FutureProvider<List<Category>>((ref) async {
  return ref.read(categoryRepoProvider).getAll(type: 'income');
});

/// 全部分类（含归档），分类管理页用。
final allCategoriesProvider = FutureProvider<List<Category>>((ref) async {
  final expense = await ref
      .read(categoryRepoProvider)
      .getAll(type: 'expense', includeArchived: true);
  final income = await ref
      .read(categoryRepoProvider)
      .getAll(type: 'income', includeArchived: true);
  return [...expense, ...income];
});

/// 全部账户（含归档），账户管理页用。
final allAccountsProvider = FutureProvider<List<Account>>((ref) async {
  return ref.read(accountRepoProvider).getAll(includeArchived: true);
});

/// 记账统计：总记录数、记账天数、连续记账天数。
final recordStatsProvider =
    FutureProvider<({int totalRecords, int distinctDays, int currentStreak})>((
      ref,
    ) async {
      return ref.read(recordRepoProvider).getStats();
    });

/// 当月预算列表（含总预算 categoryId=0 + 各分类预算）。
final monthBudgetsProvider = FutureProvider<List<Budget>>((ref) async {
  final month = ref.watch(currentMonthProvider);
  final monthInt = month.year * 100 + month.month;
  return ref.read(budgetRepoProvider).getByMonth(monthInt);
});

/// 当月各分类支出（categoryId -> 分），预算页用。
final monthExpenseByCategoryProvider = FutureProvider<Map<int, int>>((
  ref,
) async {
  final month = ref.watch(currentMonthProvider);
  return ref
      .read(recordRepoProvider)
      .getMonthExpenseByCategoryIds(month.year, month.month);
});

extension RecordDerivedRefInvalidation on Ref {
  void invalidateRecordDerivedProviders() {
    invalidate(monthRecordsProvider);
    invalidate(monthSummaryProvider);
    invalidate(monthByCategoryProvider);
    invalidate(monthByDayProvider);
    invalidate(monthExpenseByCategoryProvider);
    invalidate(recordStatsProvider);
  }
}

extension RecordDerivedWidgetRefInvalidation on WidgetRef {
  void invalidateRecordDerivedProviders() {
    invalidate(monthRecordsProvider);
    invalidate(monthSummaryProvider);
    invalidate(monthByCategoryProvider);
    invalidate(monthByDayProvider);
    invalidate(monthExpenseByCategoryProvider);
    invalidate(recordStatsProvider);
  }
}

/// BudgetPredictor 已在 core/budget_predictor.dart，T3.2 接入。
