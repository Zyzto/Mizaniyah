import 'package:drift/drift.dart';
import '../app_database.dart';
import '../models/category_mappings.dart';
import 'package:flutter_logging_service/flutter_logging_service.dart';
import 'base_dao_mixin.dart';

part 'category_mapping_dao.g.dart';

@DriftAccessor(tables: [CategoryMappings])
class CategoryMappingDao extends DatabaseAccessor<AppDatabase>
    with _$CategoryMappingDaoMixin, Loggable, BaseDaoMixin {
  CategoryMappingDao(super.db);

  /// Get all active category mappings
  Future<List<CategoryMapping>> getActiveMappings() async {
    return executeWithErrorHandling<List<CategoryMapping>>(
      operationName: 'getActiveMappings',
      operation: () async {
        final result =
            await (select(db.categoryMappings)
                  ..where((m) => m.isActive.equals(true))
                  ..orderBy([(m) => OrderingTerm.desc(m.confidence)]))
                .get();
        logInfo('getActiveMappings() returned ${result.length} mappings');
        return result;
      },
      onError: () => <CategoryMapping>[],
    );
  }

  /// Get all category mappings (including inactive)
  Future<List<CategoryMapping>> getAllMappings() async {
    return executeWithErrorHandling<List<CategoryMapping>>(
      operationName: 'getAllMappings',
      operation: () async {
        final result = await (select(
          db.categoryMappings,
        )..orderBy([(m) => OrderingTerm.desc(m.confidence)])).get();
        logInfo('getAllMappings() returned ${result.length} mappings');
        return result;
      },
      onError: () => <CategoryMapping>[],
    );
  }

  /// Get mappings for a specific category
  Future<List<CategoryMapping>> getMappingsByCategory(int categoryId) async {
    return executeWithErrorHandling<List<CategoryMapping>>(
      operationName: 'getMappingsByCategory',
      operation: () async {
        final result =
            await (select(db.categoryMappings)
                  ..where((m) => m.categoryId.equals(categoryId))
                  ..orderBy([(m) => OrderingTerm.desc(m.confidence)]))
                .get();
        logInfo(
          'getMappingsByCategory(categoryId=$categoryId) returned ${result.length} mappings',
        );
        return result;
      },
      onError: () => <CategoryMapping>[],
    );
  }

  /// Find matching category for a store name
  /// Returns the category ID if a match is found, null otherwise
  Future<int?> findCategoryForStoreName(String storeName) async {
    return executeWithErrorHandling<int?>(
      operationName: 'findCategoryForStoreName',
      operation: () async {
        final mappings = await getActiveMappings();
        if (mappings.isEmpty) {
          return null;
        }

        final storeNameLower = storeName.toLowerCase().trim();

        // Try exact match first
        for (final mapping in mappings) {
          final pattern = mapping.storeNamePattern.toLowerCase().trim();
          if (storeNameLower == pattern) {
            logInfo(
              'Exact match found: storeName=$storeName, categoryId=${mapping.categoryId}',
            );
            return mapping.categoryId;
          }
        }

        // Try contains match
        for (final mapping in mappings) {
          final pattern = mapping.storeNamePattern.toLowerCase().trim();
          if (storeNameLower.contains(pattern) ||
              pattern.contains(storeNameLower)) {
            logInfo(
              'Contains match found: storeName=$storeName, pattern=$pattern, categoryId=${mapping.categoryId}',
            );
            return mapping.categoryId;
          }
        }

        // Try fuzzy match (simple word-based matching)
        final storeWords = storeNameLower.split(RegExp(r'[\s\-_.,()&@#]+'))
          ..removeWhere((w) => w.length < 3); // Remove short words

        for (final mapping in mappings) {
          final pattern = mapping.storeNamePattern.toLowerCase().trim();
          final patternWords = pattern.split(RegExp(r'[\s\-_.,()&@#]+'))
            ..removeWhere((w) => w.length < 3);

          // Check if significant words match
          int matchCount = 0;
          for (final word in storeWords) {
            if (patternWords.contains(word)) {
              matchCount++;
            }
          }

          // If at least 50% of words match, consider it a match
          if (patternWords.isNotEmpty &&
              matchCount >= (patternWords.length * 0.5).ceil()) {
            logInfo(
              'Fuzzy match found: storeName=$storeName, pattern=$pattern, categoryId=${mapping.categoryId}',
            );
            return mapping.categoryId;
          }
        }

        return null;
      },
      onError: () => null,
    );
  }

  /// Insert a new category mapping
  Future<int> insertMapping(CategoryMappingsCompanion mapping) async {
    return executeWithErrorHandling<int>(
      operationName: 'insertMapping',
      operation: () async {
        final id = await into(db.categoryMappings).insert(mapping);
        logInfo('insertMapping() inserted mapping with id=$id');
        return id;
      },
    );
  }

  /// Update an existing category mapping
  Future<bool> updateMapping(CategoryMappingsCompanion mapping) async {
    final id = mapping.id.value;
    return executeWithErrorHandling<bool>(
      operationName: 'updateMapping',
      operation: () async {
        final result = await update(db.categoryMappings).replace(mapping);
        logInfo('updateMapping(id=$id) updated successfully');
        return result;
      },
    );
  }

  /// Delete a category mapping
  Future<int> deleteMapping(int id) async {
    return executeWithErrorHandling<int>(
      operationName: 'deleteMapping',
      operation: () async {
        final result = await (delete(
          db.categoryMappings,
        )..where((m) => m.id.equals(id))).go();
        logInfo('deleteMapping(id=$id) deleted $result rows');
        return result;
      },
    );
  }

  /// Toggle active status of a mapping
  Future<bool> toggleActive(int id, bool isActive) async {
    return executeWithErrorHandling<bool>(
      operationName: 'toggleActive',
      operation: () async {
        await (update(
          db.categoryMappings,
        )..where((m) => m.id.equals(id))).write(
          CategoryMappingsCompanion(
            isActive: Value(isActive),
            updatedAt: Value(DateTime.now()),
          ),
        );
        logInfo(
          'toggleActive(id=$id, isActive=$isActive) updated successfully',
        );
        return true;
      },
    );
  }
}
