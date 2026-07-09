import 'package:drift/drift.dart';

/// 流水明细表。
///
/// 金额用 [amountCents]（int 分），禁止 double。
/// [sourceId] 是导入去重键，DB 唯一约束：手记为 null（SQLite NULL 不冲突），
/// 导入非空被 DB 直接拦截。
class Records extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get date => dateTime()();
  TextColumn get type => text().withDefault(const Constant('expense'))();
  IntColumn get amountCents => integer()();
  IntColumn get categoryId => integer().nullable()();
  TextColumn get note => text().nullable()();
  IntColumn get accountId => integer().withDefault(const Constant(1))();
  TextColumn get source => text().withDefault(const Constant('manual'))();
  TextColumn get sourceId => text().nullable()();
  TextColumn get merchant => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  List<Set<Column>> get uniqueKeys => [
    {sourceId},
  ];
}

/// 收支分类表。同名同类型唯一，archived 软删除。
class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 20)();
  TextColumn get icon => text()();
  IntColumn get color => integer().withDefault(const Constant(0xFF1D9E75))();
  TextColumn get type => text().withDefault(const Constant('expense'))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  BoolColumn get archived => boolean().withDefault(const Constant(false))();

  @override
  List<Set<Column>> get uniqueKeys => [
    {name, type},
  ];
}

/// 资金账户表。余额用 [balanceCents]（int 分），archived 软删除。
class Accounts extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 20)();
  IntColumn get balanceCents => integer().withDefault(const Constant(0))();
  TextColumn get icon => text().withDefault(const Constant('💰'))();
  BoolColumn get archived => boolean().withDefault(const Constant(false))();

  @override
  List<Set<Column>> get uniqueKeys => [
    {name},
  ];
}

/// 预算表。
///
/// [categoryId] = 0 表示总预算（NOT NULL DEFAULT 0），真实分类 id 从 1 开始。
/// 避免 SQLite NULL 在 UNIQUE 约束中不冲突导致多条总预算共存。
class Budgets extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get month => integer()();
  IntColumn get amountCents => integer()();
  IntColumn get categoryId => integer().withDefault(const Constant(0))();

  @override
  List<Set<Column>> get uniqueKeys => [
    {month, categoryId},
  ];
}
