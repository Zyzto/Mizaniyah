import 'package:flutter/material.dart';

/// Utility class for working with Material icons stored as strings
class IconUtils {
  /// Common Material icons that can be used for categories
  static final List<IconData> commonIcons = [
    Icons.shopping_cart,
    Icons.restaurant,
    Icons.local_gas_station,
    Icons.home,
    Icons.directions_car,
    Icons.flight,
    Icons.hotel,
    Icons.fitness_center,
    Icons.local_hospital,
    Icons.school,
    Icons.work,
    Icons.movie,
    Icons.music_note,
    Icons.book,
    Icons.sports_soccer,
    Icons.local_dining,
    Icons.coffee,
    Icons.shopping_bag,
    Icons.category,
    Icons.label,
    Icons.star,
    Icons.favorite,
  ];

  /// Map of icon names to IconData
  static final Map<String, IconData> _iconMap = {
    'shopping_cart': Icons.shopping_cart,
    'restaurant': Icons.restaurant,
    'local_gas_station': Icons.local_gas_station,
    'home': Icons.home,
    'directions_car': Icons.directions_car,
    'flight': Icons.flight,
    'hotel': Icons.hotel,
    'fitness_center': Icons.fitness_center,
    'local_hospital': Icons.local_hospital,
    'school': Icons.school,
    'work': Icons.work,
    'movie': Icons.movie,
    'music_note': Icons.music_note,
    'book': Icons.book,
    'sports_soccer': Icons.sports_soccer,
    'local_dining': Icons.local_dining,
    'coffee': Icons.coffee,
    'shopping_bag': Icons.shopping_bag,
    'category': Icons.category,
    'label': Icons.label,
    'star': Icons.star,
    'favorite': Icons.favorite,
  };

  /// Get IconData from icon name string
  static IconData getIconData(String iconName) {
    return _iconMap[iconName] ?? Icons.category;
  }

  /// Get icon name from IconData (for storing in database)
  static String? getIconName(IconData iconData) {
    for (final entry in _iconMap.entries) {
      if (entry.value.codePoint == iconData.codePoint) {
        return entry.key;
      }
    }
    return null;
  }
}
