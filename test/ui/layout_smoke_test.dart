import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:jiyibi/core/providers.dart';
import 'package:jiyibi/core/theme/app_theme.dart';
import 'package:jiyibi/data/database/app_database.dart';
import 'package:jiyibi/presentation/budget/budget_page.dart';
import 'package:jiyibi/presentation/detail/detail_page.dart';
import 'package:jiyibi/presentation/editor/editor_sheet.dart';
import 'package:jiyibi/presentation/overview/overview_page.dart';
import 'package:jiyibi/presentation/report/report_page.dart';
import 'package:jiyibi/presentation/settings/settings_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late DateTime now;
  late List<Category> categories;
  late List<Record> records;
  late List<Budget> budgets;

  setUpAll(() async {
    await initializeDateFormatting('zh_CN');
    SharedPreferences.setMockInitialValues({});
  });

  setUp(() {
    now = DateTime.now();
    categories = const [
      Category(
        id: 1,
        name: '餐饮',
        icon: '餐',
        color: 0xFFBA7517,
        type: 'expense',
        sortOrder: 1,
        archived: false,
      ),
      Category(
        id: 2,
        name: '交通',
        icon: '交',
        color: 0xFF185FA5,
        type: 'expense',
        sortOrder: 2,
        archived: false,
      ),
      Category(
        id: 9,
        name: '工资',
        icon: '资',
        color: 0xFF3B6D11,
        type: 'income',
        sortOrder: 1,
        archived: false,
      ),
    ];
    records = [
      _record(1, now, 'expense', 2860, 1, '午餐'),
      _record(
        2,
        now.subtract(const Duration(days: 1)),
        'expense',
        1200,
        2,
        '地铁',
      ),
      _record(
        3,
        now.subtract(const Duration(days: 3)),
        'income',
        860000,
        9,
        '本月工资',
      ),
    ];
    budgets = [
      Budget(
        id: 1,
        month: now.year * 100 + now.month,
        amountCents: 450000,
        categoryId: 0,
      ),
      Budget(
        id: 2,
        month: now.year * 100 + now.month,
        amountCents: 100000,
        categoryId: 1,
      ),
    ];
  });

  testWidgets('overview fits a compact Android viewport', (tester) async {
    await _setPhoneSize(tester);
    await _pump(
      tester,
      OverviewPage(onShowDetails: () {}, onShowInsights: () {}),
      overrides: _baseOverrides(records, budgets, categories),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('detail fits a compact Android viewport', (tester) async {
    await _setPhoneSize(tester);
    await _pump(
      tester,
      const DetailPage(),
      overrides: [
        monthRecordsProvider.overrideWith((ref) async => records),
        monthSummaryProvider.overrideWith(
          (ref) async => (expenseCents: 4060, incomeCents: 860000),
        ),
        allCategoriesProvider.overrideWith((ref) async => categories),
      ],
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('budget fits a compact Android viewport', (tester) async {
    await _setPhoneSize(tester);
    await _pump(
      tester,
      const BudgetPage(),
      overrides: [
        monthBudgetsProvider.overrideWith((ref) async => budgets),
        monthSummaryProvider.overrideWith(
          (ref) async => (expenseCents: 4060, incomeCents: 860000),
        ),
        monthExpenseByCategoryProvider.overrideWith(
          (ref) async => {1: 2860, 2: 1200},
        ),
        expenseCategoriesProvider.overrideWith(
          (ref) async => categories.where((c) => c.type == 'expense').toList(),
        ),
      ],
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('insights fits a compact Android viewport', (tester) async {
    await _setPhoneSize(tester);
    await _pump(
      tester,
      const ReportPage(),
      overrides: [
        monthRecordsProvider.overrideWith((ref) async => records),
        allCategoriesProvider.overrideWith((ref) async => categories),
      ],
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('settings fits a compact Android viewport', (tester) async {
    await _setPhoneSize(tester);
    await _pump(
      tester,
      const SettingsPage(),
      overrides: [
        recordStatsProvider.overrideWith(
          (ref) async =>
              (totalRecords: 128, distinctDays: 46, currentStreak: 7),
        ),
        allCategoriesProvider.overrideWith((ref) async => categories),
        allAccountsProvider.overrideWith((ref) async => const []),
      ],
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('record editor fits a compact Android viewport', (tester) async {
    await _setPhoneSize(tester);
    await _pump(
      tester,
      Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: FilledButton(
              onPressed: () => showEditorSheet(context),
              child: const Text('记一笔'),
            ),
          ),
        ),
      ),
      overrides: [
        expenseCategoriesProvider.overrideWith(
          (ref) async => categories.where((c) => c.type == 'expense').toList(),
        ),
        incomeCategoriesProvider.overrideWith(
          (ref) async => categories.where((c) => c.type == 'income').toList(),
        ),
      ],
    );
    await tester.tap(find.text('记一笔'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}

dynamic _baseOverrides(
  List<Record> records,
  List<Budget> budgets,
  List<Category> categories,
) {
  return [
    monthRecordsProvider.overrideWith((ref) async => records),
    monthBudgetsProvider.overrideWith((ref) async => budgets),
    allCategoriesProvider.overrideWith((ref) async => categories),
  ];
}

Future<void> _setPhoneSize(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(360, 800));
  addTearDown(() => tester.binding.setSurfaceSize(null));
}

Future<void> _pump(
  WidgetTester tester,
  Widget page, {
  required dynamic overrides,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides,
      child: MaterialApp(theme: AppTheme.byKey(AppThemeKey.pine), home: page),
    ),
  );
  await tester.pumpAndSettle();
}

Record _record(
  int id,
  DateTime date,
  String type,
  int amountCents,
  int categoryId,
  String note,
) {
  return Record(
    id: id,
    date: date,
    type: type,
    amountCents: amountCents,
    categoryId: categoryId,
    note: note,
    accountId: 1,
    source: 'manual',
    createdAt: date,
    updatedAt: date,
  );
}
