import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jiyibi/data/database/app_database.dart';
import 'package:jiyibi/data/repositories/category_repository.dart';

void main() {
  late AppDatabase db;
  late CategoryRepository repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = CategoryRepository(db);
  });

  tearDown(() => db.close());

  test('seed defaults: 8 expense + 3 income categories', () async {
    final expense = await repo.getAll(type: 'expense');
    final income = await repo.getAll(type: 'income');

    expect(expense.length, 8);
    expect(income.length, 3);
  });

  test('getAll excludes archived by default', () async {
    // 餐饮(id=1) 归档
    await repo.archive(1);

    final expense = await repo.getAll(type: 'expense');

    expect(expense.length, 7);
    expect(expense.any((c) => c.name == '餐饮'), isFalse);
  });

  test('getAll with includeArchived=true includes archived', () async {
    await repo.archive(1);

    final expense = await repo.getAll(type: 'expense', includeArchived: true);

    expect(expense.length, 8);
    expect(expense.any((c) => c.name == '餐饮'), isTrue);
  });

  test('archived category can be restored', () async {
    await repo.setArchived(1, true);
    await repo.setArchived(1, false);

    final expense = await repo.getAll(type: 'expense');
    expect(expense.any((category) => category.id == 1), isTrue);
  });

  test('insert throws on duplicate (name, type)', () async {
    expect(
      () => repo.insert(
        CategoriesCompanion.insert(
          name: '餐饮',
          icon: '餐',
          type: const Value('expense'),
        ),
      ),
      throwsA(isA<Object>()),
    );
  });

  test('same name across different types does not conflict', () async {
    // 支出「其他」已存在（id=8），收入「其他收入」已存在（id=11）。
    // 再插一个 name='其他' type='income' 应该可以（不与 expense 冲突）。
    final id = await repo.insert(
      CategoriesCompanion.insert(
        name: '其他',
        icon: '他',
        type: const Value('income'),
      ),
    );

    expect(id, greaterThan(0));

    final income = await repo.getAll(type: 'income');
    expect(income.any((c) => c.name == '其他'), isTrue);
  });
}
