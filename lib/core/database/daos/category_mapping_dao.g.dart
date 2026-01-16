// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'category_mapping_dao.dart';

// ignore_for_file: type=lint
mixin _$CategoryMappingDaoMixin on DatabaseAccessor<AppDatabase> {
  $CategoriesTable get categories => attachedDatabase.categories;
  $CategoryMappingsTable get categoryMappings =>
      attachedDatabase.categoryMappings;
  CategoryMappingDaoManager get managers => CategoryMappingDaoManager(this);
}

class CategoryMappingDaoManager {
  final _$CategoryMappingDaoMixin _db;
  CategoryMappingDaoManager(this._db);
  $$CategoriesTableTableManager get categories =>
      $$CategoriesTableTableManager(_db.attachedDatabase, _db.categories);
  $$CategoryMappingsTableTableManager get categoryMappings =>
      $$CategoryMappingsTableTableManager(
        _db.attachedDatabase,
        _db.categoryMappings,
      );
}
