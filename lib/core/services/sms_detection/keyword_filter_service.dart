import 'package:flutter_logging_service/flutter_logging_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for filtering SMS by keywords (whitelist/blacklist)
class KeywordFilterService with Loggable {
  static const String _whitelistKey = 'sms_keyword_whitelist';
  static const String _blacklistKey = 'sms_keyword_blacklist';
  static const String _filterModeKey =
      'sms_keyword_filter_mode'; // 'none', 'whitelist', 'blacklist'

  final SharedPreferences _prefs;

  KeywordFilterService(this._prefs);

  /// Get current filter mode
  String getFilterMode() {
    return _prefs.getString(_filterModeKey) ?? 'none';
  }

  /// Set filter mode ('none', 'whitelist', 'blacklist')
  Future<bool> setFilterMode(String mode) async {
    if (!['none', 'whitelist', 'blacklist'].contains(mode)) {
      logWarning('Invalid filter mode: $mode');
      return false;
    }
    final result = await _prefs.setString(_filterModeKey, mode);
    logInfo('Keyword filter mode set to: $mode');
    return result;
  }

  /// Get whitelist of keywords
  List<String> getWhitelist() {
    return _prefs.getStringList(_whitelistKey) ?? [];
  }

  /// Add keyword to whitelist
  Future<bool> addToWhitelist(String keyword) {
    final whitelist = getWhitelist();
    if (whitelist.contains(keyword)) {
      return Future.value(true); // Already in list
    }
    whitelist.add(keyword);
    logInfo('Added keyword to whitelist: $keyword');
    return _prefs.setStringList(_whitelistKey, whitelist);
  }

  /// Remove keyword from whitelist
  Future<bool> removeFromWhitelist(String keyword) {
    final whitelist = getWhitelist();
    whitelist.remove(keyword);
    logInfo('Removed keyword from whitelist: $keyword');
    return _prefs.setStringList(_whitelistKey, whitelist);
  }

  /// Get blacklist of keywords
  List<String> getBlacklist() {
    return _prefs.getStringList(_blacklistKey) ?? [];
  }

  /// Add keyword to blacklist
  Future<bool> addToBlacklist(String keyword) {
    final blacklist = getBlacklist();
    if (blacklist.contains(keyword)) {
      return Future.value(true); // Already in list
    }
    blacklist.add(keyword);
    logInfo('Added keyword to blacklist: $keyword');
    return _prefs.setStringList(_blacklistKey, blacklist);
  }

  /// Remove keyword from blacklist
  Future<bool> removeFromBlacklist(String keyword) {
    final blacklist = getBlacklist();
    blacklist.remove(keyword);
    logInfo('Removed keyword from blacklist: $keyword');
    return _prefs.setStringList(_blacklistKey, blacklist);
  }

  /// Check if SMS should be filtered based on keywords
  /// Returns true if SMS should be filtered/blocked
  bool shouldFilterSms(String smsBody) {
    final mode = getFilterMode();
    if (mode == 'none') {
      return false; // No filtering
    }

    final bodyLower = smsBody.toLowerCase();

    if (mode == 'whitelist') {
      final whitelist = getWhitelist();
      if (whitelist.isEmpty) {
        // Empty whitelist means allow all
        return false;
      }
      // Check if SMS contains any whitelist keyword
      final isAllowed = whitelist.any((keyword) {
        final keywordLower = keyword.toLowerCase();
        // Support regex patterns (if keyword starts with / and ends with /)
        if (keyword.startsWith('/') &&
            keyword.endsWith('/') &&
            keyword.length > 2) {
          try {
            final pattern = keyword.substring(1, keyword.length - 1);
            return RegExp(pattern, caseSensitive: false).hasMatch(bodyLower);
          } catch (e) {
            logWarning('Invalid regex pattern in whitelist: $keyword');
            return false;
          }
        }
        // Simple contains match
        return bodyLower.contains(keywordLower);
      });
      return !isAllowed; // Filter if not in whitelist
    }

    if (mode == 'blacklist') {
      final blacklist = getBlacklist();
      // Check if SMS contains any blacklist keyword
      final isBlocked = blacklist.any((keyword) {
        final keywordLower = keyword.toLowerCase();
        // Support regex patterns
        if (keyword.startsWith('/') &&
            keyword.endsWith('/') &&
            keyword.length > 2) {
          try {
            final pattern = keyword.substring(1, keyword.length - 1);
            return RegExp(pattern, caseSensitive: false).hasMatch(bodyLower);
          } catch (e) {
            logWarning('Invalid regex pattern in blacklist: $keyword');
            return false;
          }
        }
        // Simple contains match
        return bodyLower.contains(keywordLower);
      });
      return isBlocked; // Filter if in blacklist
    }

    return false;
  }
}
