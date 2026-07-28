import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jiyibi/core/providers.dart';
import 'package:jiyibi/data/database/app_database.dart';
import 'package:jiyibi/presentation/editor/editor_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({'lastExpenseCategory': 1});
  });

  test('last category load does not overwrite an edited record', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(editorProvider.notifier);

    notifier.startEdit(_record(categoryId: 2));
    await Future<void>.delayed(Duration.zero);

    expect(container.read(editorProvider).categoryId, 2);
    expect(container.read(editorProvider).isEditing, isTrue);
  });

  test('last category load does not overwrite a manual selection', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(editorProvider.notifier);

    notifier.setCategory(2);
    await Future<void>.delayed(Duration.zero);

    expect(container.read(editorProvider).categoryId, 2);
  });

  test('save persists selected account', () async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    final container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(database)],
    );
    addTearDown(container.dispose);
    final notifier = container.read(editorProvider.notifier);

    notifier
      ..setCategory(1)
      ..setAccount(1)
      ..appendDigit('2')
      ..appendDigit('5');
    await notifier.save();

    final records = await container.read(recordRepoProvider).getAll();
    expect(records, hasLength(1));
    expect(records.single.accountId, 1);
    expect(records.single.amountCents, 2500);
  });
}

Record _record({required int categoryId}) {
  final now = DateTime(2026, 7, 26);
  return Record(
    id: 1,
    date: now,
    type: 'expense',
    amountCents: 1200,
    categoryId: categoryId,
    accountId: 1,
    note: null,
    source: 'manual',
    sourceId: null,
    merchant: null,
    createdAt: now,
    updatedAt: now,
  );
}
