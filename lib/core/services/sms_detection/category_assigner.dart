import 'package:flutter_logging_service/flutter_logging_service.dart';
import 'package:mizaniyah/core/database/daos/category_mapping_dao.dart';

/// Service responsible for auto-assigning categories based on store name patterns
class CategoryAssigner with Loggable {
  final CategoryMappingDao _categoryMappingDao;

  CategoryAssigner(this._categoryMappingDao);

  /// Find and assign category for a store name
  /// Returns category ID if match found, null otherwise
  Future<int?> assignCategory(String? storeName) async {
    if (storeName == null || storeName.trim().isEmpty) {
      logDebug('Cannot assign category: store name is empty');
      return null;
    }

    try {
      final categoryId = await _categoryMappingDao.findCategoryForStoreName(
        storeName,
      );
      if (categoryId != null) {
        logInfo('Auto-assigned category $categoryId for store: $storeName');
      } else {
        logDebug('No category mapping found for store: $storeName');
      }
      return categoryId;
    } catch (e, stackTrace) {
      logError(
        'Failed to assign category for store: $storeName',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }
}
