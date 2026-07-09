import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jiyibi/data/database/app_database.dart';
import 'package:jiyibi/data/repositories/budget_repository.dart';

void main() {
  late AppDatabase db;
  late BudgetRepository repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = BudgetRepository(db);
  });

  tearDown(() => db.close());

  test('upsert inserts total budget (categoryId=0) on first call', () async {
    await repo.upsert(month: 202607, categoryId: 0, amountCents: 500000);

    final total = await repo.getTotalByMonth(202607);

    expect(total, isNotNull);
    expect(total!.categoryId, 0);
    expect(total.amountCents, 500000);
  });

  test('upsert updates total budget instead of inserting duplicate', () async {
    await repo.upsert(month: 202607, categoryId: 0, amountCents: 500000);
    await repo.upsert(month: 202607, categoryId: 0, amountCents: 600000);

    final budgets = await repo.getByMonth(202607);

    expect(budgets.length, 1);
    expect(budgets.first.amountCents, 600000);
  });

  test('upsert inserts category budget separately from total', () async {
    await repo.upsert(month: 202607, categoryId: 0, amountCents: 500000);
    await repo.upsert(month: 202607, categoryId: 1, amountCents: 150000);

    final budgets = await repo.getByMonth(202607);

    expect(budgets.length, 2);
  });

  test('upsert updates category budget without affecting total', () async {
    await repo.upsert(month: 202607, categoryId: 0, amountCents: 500000);
    await repo.upsert(month: 202607, categoryId: 1, amountCents: 150000);
    await repo.upsert(month: 202607, categoryId: 1, amountCents: 200000);

    final total = await repo.getTotalByMonth(202607);
    final dining = await repo.getCategoryBudget(202607, 1);

    expect(total!.amountCents, 500000);
    expect(dining!.amountCents, 200000);

    final all = await repo.getByMonth(202607);
    expect(all.length, 2);
  });

  test('DB unique constraint: duplicate (month, categoryId) throws', () async {
    await repo.upsert(month: 202607, categoryId: 0, amountCents: 500000);

    expect(
      () => db
          .into(db.budgets)
          .insert(
            BudgetsCompanion.insert(
              month: 202607,
              amountCents: 600000,
              categoryId: const Value(0),
            ),
          ),
      throwsA(isA<Object>()),
    );
  });

  test('different months do not conflict', () async {
    await repo.upsert(month: 202607, categoryId: 0, amountCents: 500000);
    await repo.upsert(month: 202608, categoryId: 0, amountCents: 600000);

    final july = await repo.getTotalByMonth(202607);
    final august = await repo.getTotalByMonth(202608);

    expect(july!.amountCents, 500000);
    expect(august!.amountCents, 600000);
  });

  test('delete removes budget', () async {
    await repo.upsert(month: 202607, categoryId: 0, amountCents: 500000);

    await repo.delete(202607, 0);

    final total = await repo.getTotalByMonth(202607);
    expect(total, isNull);
  });
}
