import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jiyibi/data/database/app_database.dart';
import 'package:jiyibi/data/repositories/account_repository.dart';

void main() {
  late AppDatabase database;
  late AccountRepository repository;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    repository = AccountRepository(database);
  });

  tearDown(() => database.close());

  test('archive and restore preserve the account', () async {
    await repository.setArchived(1, true);
    expect(await repository.getAll(), isEmpty);

    await repository.setArchived(1, false);
    final accounts = await repository.getAll();
    expect(accounts, hasLength(1));
    expect(accounts.single.name, '现金');
  });

  test('current balance combines opening balance and records', () async {
    await repository.update(
      1,
      const AccountsCompanion(balanceCents: Value(10000)),
    );
    final date = DateTime(2026, 7, 28);
    await database
        .into(database.records)
        .insert(
          RecordsCompanion.insert(
            date: date,
            amountCents: 2500,
            accountId: const Value(1),
          ),
        );
    await database
        .into(database.records)
        .insert(
          RecordsCompanion.insert(
            date: date,
            type: const Value('income'),
            amountCents: 5000,
            accountId: const Value(1),
          ),
        );

    final balances = await repository.getCurrentBalances();
    expect(balances[1], 12500);
  });
}
