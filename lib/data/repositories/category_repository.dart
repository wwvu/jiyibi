import 'package:drift/drift.dart';

import '../database/app_database.dart';

/// 分类数据访问层。默认过滤 archived，管理页可传 includeArchived。
class CategoryRepository {
  CategoryRepository(this._db);

  final AppDatabase _db;

  /// 查分类列表。includeArchived=false 时只返回未归档。
  Future<List<Category>> getAll({
    required String type,
    bool includeArchived = false,
  }) {
    final query = _db.select(_db.categories)
      ..where((c) => c.type.equals(type))
      ..orderBy([(c) => OrderingTerm.asc(c.sortOrder)]);

    if (!includeArchived) {
      query.where((c) => c.archived.equals(false));
    }

    return query.get();
  }

  Future<Category?> getById(int id) {
    return (_db.select(
      _db.categories,
    )..where((c) => c.id.equals(id))).getSingleOrNull();
  }

  /// 新增分类。同 (name, type) 已存在会抛唯一约束异常。
  Future<int> insert(CategoriesCompanion data) {
    return _db.into(_db.categories).insert(data);
  }

  Future<int> update(int id, CategoriesCompanion patch) {
    return (_db.update(
      _db.categories,
    )..where((c) => c.id.equals(id))).write(patch);
  }

  /// 归档分类（软删除），不物理删除。
  Future<int> archive(int id) {
    return (_db.update(_db.categories)..where((c) => c.id.equals(id))).write(
      const CategoriesCompanion(archived: Value(true)),
    );
  }
}
