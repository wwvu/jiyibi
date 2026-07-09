import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [Records, Categories, Accounts, Budgets])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  /// 仅供测试用：传入内存库或自定义 QueryExecutor。
  factory AppDatabase.forTesting(QueryExecutor executor) {
    return AppDatabase._(executor);
  }

  AppDatabase._(super.executor);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await _seedDefaults();
    },
  );

  /// 默认数据：8 个支出分类 + 3 个收入分类 + 1 个「现金」账户。
  Future<void> _seedDefaults() async {
    await batch((batch) {
      batch.insertAll(categories, [
        CategoriesCompanion.insert(
          name: '餐饮',
          icon: '餐',
          color: const Value(0xFFBA7517),
          type: const Value('expense'),
          sortOrder: const Value(1),
        ),
        CategoriesCompanion.insert(
          name: '交通',
          icon: '交',
          color: const Value(0xFF185FA5),
          type: const Value('expense'),
          sortOrder: const Value(2),
        ),
        CategoriesCompanion.insert(
          name: '购物',
          icon: '购',
          color: const Value(0xFFD85A30),
          type: const Value('expense'),
          sortOrder: const Value(3),
        ),
        CategoriesCompanion.insert(
          name: '娱乐',
          icon: '娱',
          color: const Value(0xFF7F77DD),
          type: const Value('expense'),
          sortOrder: const Value(4),
        ),
        CategoriesCompanion.insert(
          name: '医疗',
          icon: '医',
          color: const Value(0xFFA32D2D),
          type: const Value('expense'),
          sortOrder: const Value(5),
        ),
        CategoriesCompanion.insert(
          name: '居家',
          icon: '居',
          color: const Value(0xFF0F6E56),
          type: const Value('expense'),
          sortOrder: const Value(6),
        ),
        CategoriesCompanion.insert(
          name: '学习',
          icon: '学',
          color: const Value(0xFF3B6D11),
          type: const Value('expense'),
          sortOrder: const Value(7),
        ),
        CategoriesCompanion.insert(
          name: '其他',
          icon: '他',
          color: const Value(0xFF888780),
          type: const Value('expense'),
          sortOrder: const Value(8),
        ),
        CategoriesCompanion.insert(
          name: '工资',
          icon: '资',
          color: const Value(0xFF3B6D11),
          type: const Value('income'),
          sortOrder: const Value(1),
        ),
        CategoriesCompanion.insert(
          name: '兼职',
          icon: '兼',
          color: const Value(0xFF0F6E56),
          type: const Value('income'),
          sortOrder: const Value(2),
        ),
        CategoriesCompanion.insert(
          name: '其他收入',
          icon: '他',
          color: const Value(0xFF888780),
          type: const Value('income'),
          sortOrder: const Value(3),
        ),
      ]);
    });

    await into(accounts).insert(AccountsCompanion.insert(name: '现金'));
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'jiyibi.db'));
    // MVP 明文；将来切 SQLCipher 只改这一处 NativeDatabase -> SQLCipher。
    return NativeDatabase(file);
  });
}
