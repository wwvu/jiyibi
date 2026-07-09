import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jiyibi/data/database/app_database.dart';
import 'package:jiyibi/data/repositories/record_repository.dart';

void main() {
  late AppDatabase db;
  late RecordRepository repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = RecordRepository(db);
  });

  tearDown(() => db.close());

  test('insert and query by month', () async {
    await repo.insert(
      RecordsCompanion.insert(
        date: DateTime(2026, 7, 5),
        type: const Value('expense'),
        amountCents: 1234,
        categoryId: const Value(1),
      ),
    );

    final list = await repo.getRecordsByMonth(2026, 7);

    expect(list.length, 1);
    expect(list.first.amountCents, 1234);
    expect(list.first.source, 'manual');
    expect(list.first.sourceId, isNull);
  });

  test('month summary returns int cents and sums correctly', () async {
    await repo.insert(
      RecordsCompanion.insert(
        date: DateTime(2026, 7, 5),
        type: const Value('expense'),
        amountCents: 1234,
        categoryId: const Value(1),
      ),
    );
    await repo.insert(
      RecordsCompanion.insert(
        date: DateTime(2026, 7, 6),
        type: const Value('expense'),
        amountCents: 5600,
        categoryId: const Value(1),
      ),
    );
    await repo.insert(
      RecordsCompanion.insert(
        date: DateTime(2026, 7, 7),
        type: const Value('income'),
        amountCents: 10000,
        categoryId: const Value(9),
      ),
    );

    final summary = await repo.getMonthSummary(2026, 7);

    expect(summary.expenseCents, 6834);
    expect(summary.incomeCents, 10000);
  });

  test('large sum does not overflow int', () async {
    for (var i = 0; i < 1000; i++) {
      await repo.insert(
        RecordsCompanion.insert(
          date: DateTime(2026, 7, 1),
          type: const Value('expense'),
          amountCents: 999999,
          categoryId: const Value(1),
        ),
      );
    }

    final summary = await repo.getMonthSummary(2026, 7);

    expect(summary.expenseCents, 999999000);
  });

  test('month query uses half-open interval (excludes next month)', () async {
    await repo.insert(
      RecordsCompanion.insert(
        date: DateTime(2026, 7, 31, 23, 59, 59, 999),
        type: const Value('expense'),
        amountCents: 100,
        categoryId: const Value(1),
      ),
    );
    await repo.insert(
      RecordsCompanion.insert(
        date: DateTime(2026, 8, 1),
        type: const Value('expense'),
        amountCents: 200,
        categoryId: const Value(1),
      ),
    );

    final july = await repo.getRecordsByMonth(2026, 7);
    final august = await repo.getRecordsByMonth(2026, 8);

    expect(july.length, 1);
    expect(july.first.amountCents, 100);
    expect(august.length, 1);
    expect(august.first.amountCents, 200);
  });

  test('update bumps updatedAt', () async {
    final id = await repo.insert(
      RecordsCompanion.insert(
        date: DateTime(2026, 7, 5),
        type: const Value('expense'),
        amountCents: 1000,
        categoryId: const Value(1),
      ),
    );

    final before = (await repo.getRecordsByMonth(2026, 7)).first;
    // drift 默认存秒级 DateTime，需要等满 1 秒才能确保 updatedAt 不同。
    await Future<void>.delayed(const Duration(seconds: 2));

    await repo.update(id, const RecordsCompanion(amountCents: Value(2000)));

    final after = (await repo.getRecordsByMonth(2026, 7)).first;

    expect(after.amountCents, 2000);
    expect(after.updatedAt.isAfter(before.updatedAt), isTrue);
  });

  test('batchInsertIfNew skips duplicate sourceId', () async {
    final rows = [
      RecordsCompanion.insert(
        date: DateTime(2026, 7, 5),
        type: const Value('expense'),
        amountCents: 1000,
        categoryId: const Value(1),
        sourceId: const Value('abc-1'),
      ),
      RecordsCompanion.insert(
        date: DateTime(2026, 7, 5),
        type: const Value('expense'),
        amountCents: 2000,
        categoryId: const Value(1),
        sourceId: const Value('abc-2'),
      ),
      RecordsCompanion.insert(
        date: DateTime(2026, 7, 5),
        type: const Value('expense'),
        amountCents: 3000,
        categoryId: const Value(1),
        sourceId: const Value('abc-1'),
      ),
    ];

    final inserted = await repo.batchInsertIfNew(rows);

    expect(inserted, 2);

    final records = await repo.getRecordsByMonth(2026, 7);
    expect(records.length, 2);
  });

  test('DB unique constraint on sourceId throws on duplicate', () async {
    await repo.insert(
      RecordsCompanion.insert(
        date: DateTime(2026, 7, 5),
        type: const Value('expense'),
        amountCents: 1000,
        categoryId: const Value(1),
        sourceId: const Value('dup-1'),
      ),
    );

    expect(
      () => repo.insert(
        RecordsCompanion.insert(
          date: DateTime(2026, 7, 6),
          type: const Value('expense'),
          amountCents: 2000,
          categoryId: const Value(1),
          sourceId: const Value('dup-1'),
        ),
      ),
      throwsA(isA<Object>()),
    );
  });

  test('multiple null sourceId records do not conflict', () async {
    await repo.insert(
      RecordsCompanion.insert(
        date: DateTime(2026, 7, 5),
        type: const Value('expense'),
        amountCents: 1000,
        categoryId: const Value(1),
      ),
    );
    await repo.insert(
      RecordsCompanion.insert(
        date: DateTime(2026, 7, 6),
        type: const Value('expense'),
        amountCents: 2000,
        categoryId: const Value(1),
      ),
    );

    final records = await repo.getRecordsByMonth(2026, 7);

    expect(records.length, 2);
  });

  test('getMonthByCategory excludes archived categories', () async {
    // 餐饮(id=1) 未归档
    await repo.insert(
      RecordsCompanion.insert(
        date: DateTime(2026, 7, 5),
        type: const Value('expense'),
        amountCents: 5000,
        categoryId: const Value(1),
      ),
    );

    final byCategory = await repo.getMonthByCategory(2026, 7);

    expect(byCategory, isNotEmpty);
    expect(byCategory.first.category, '餐饮');
    expect(byCategory.first.amountCents, 5000);
  });

  test('getMonthByDay groups by date', () async {
    await repo.insert(
      RecordsCompanion.insert(
        date: DateTime(2026, 7, 5, 10),
        type: const Value('expense'),
        amountCents: 1000,
        categoryId: const Value(1),
      ),
    );
    await repo.insert(
      RecordsCompanion.insert(
        date: DateTime(2026, 7, 5, 18),
        type: const Value('expense'),
        amountCents: 2000,
        categoryId: const Value(1),
      ),
    );
    await repo.insert(
      RecordsCompanion.insert(
        date: DateTime(2026, 7, 6),
        type: const Value('expense'),
        amountCents: 3000,
        categoryId: const Value(1),
      ),
    );

    final byDay = await repo.getMonthByDay(2026, 7);
    final day5 = byDay.firstWhere((row) => row.day == 5);
    final day6 = byDay.firstWhere((row) => row.day == 6);

    expect(day5.amountCents, 3000);
    expect(day6.amountCents, 3000);
  });
}
