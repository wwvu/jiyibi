import 'package:drift/drift.dart';

import '../database/app_database.dart';

/// 账户数据访问层。默认过滤 archived，管理页可传 includeArchived。
class AccountRepository {
  AccountRepository(this._db);

  final AppDatabase _db;

  /// 查账户列表。includeArchived=false 时只返回未归档。
  Future<List<Account>> getAll({bool includeArchived = false}) {
    final query = _db.select(_db.accounts)
      ..orderBy([(a) => OrderingTerm.asc(a.id)]);

    if (!includeArchived) {
      query.where((a) => a.archived.equals(false));
    }

    return query.get();
  }

  Future<Account?> getById(int id) {
    return (_db.select(
      _db.accounts,
    )..where((a) => a.id.equals(id))).getSingleOrNull();
  }

  /// 新增账户。同名账户已存在会抛唯一约束异常。
  Future<int> insert(AccountsCompanion data) {
    return _db.into(_db.accounts).insert(data);
  }

  Future<int> update(int id, AccountsCompanion patch) {
    return (_db.update(
      _db.accounts,
    )..where((a) => a.id.equals(id))).write(patch);
  }

  /// 归档账户（软删除），不物理删除。
  Future<int> archive(int id) {
    return (_db.update(_db.accounts)..where((a) => a.id.equals(id))).write(
      const AccountsCompanion(archived: Value(true)),
    );
  }
}
