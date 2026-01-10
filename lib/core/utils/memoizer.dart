import 'dart:collection';

/// Simple memoization utility for caching expensive function results
class Memoizer<K, V> {
  final V Function(K key) _compute;
  final LinkedHashMap<K, V> _cache;
  final int? maxSize;

  Memoizer(
    this._compute, {
    this.maxSize,
  }) : _cache = LinkedHashMap<K, V>();

  /// Get or compute the value for the given key
  V get(K key) {
    if (_cache.containsKey(key)) {
      // Move to end (LRU)
      final value = _cache.remove(key);
      if (value != null) {
        _cache[key] = value;
        return value;
      }
    }

    final value = _compute(key);
    _cache[key] = value;

    // Evict oldest if cache is too large
    if (maxSize != null && _cache.length > maxSize!) {
      _cache.remove(_cache.keys.first);
    }

    return value;
  }

  /// Clear the cache
  void clear() {
    _cache.clear();
  }

  /// Remove a specific key from cache
  void invalidate(K key) {
    _cache.remove(key);
  }

  /// Get cache size
  int get size => _cache.length;
}
