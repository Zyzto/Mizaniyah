import 'package:flutter_logging_service/flutter_logging_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for managing SMS sender whitelist and blacklist
class SenderFilterService with Loggable {
  static const String _whitelistKey = 'sms_sender_whitelist';
  static const String _blacklistKey = 'sms_sender_blacklist';
  static const String _filterModeKey =
      'sms_sender_filter_mode'; // 'none', 'whitelist', 'blacklist'

  final SharedPreferences _prefs;

  SenderFilterService(this._prefs);

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
    logInfo('Filter mode set to: $mode');
    return result;
  }

  /// Get whitelist of senders
  List<String> getWhitelist() {
    return _prefs.getStringList(_whitelistKey) ?? [];
  }

  /// Add sender to whitelist
  Future<bool> addToWhitelist(String sender) {
    final whitelist = getWhitelist();
    if (whitelist.contains(sender)) {
      return Future.value(true); // Already in list
    }
    whitelist.add(sender);
    logInfo('Added sender to whitelist: $sender');
    return _prefs.setStringList(_whitelistKey, whitelist);
  }

  /// Remove sender from whitelist
  Future<bool> removeFromWhitelist(String sender) {
    final whitelist = getWhitelist();
    whitelist.remove(sender);
    logInfo('Removed sender from whitelist: $sender');
    return _prefs.setStringList(_whitelistKey, whitelist);
  }

  /// Get blacklist of senders
  List<String> getBlacklist() {
    return _prefs.getStringList(_blacklistKey) ?? [];
  }

  /// Add sender to blacklist
  Future<bool> addToBlacklist(String sender) {
    final blacklist = getBlacklist();
    if (blacklist.contains(sender)) {
      return Future.value(true); // Already in list
    }
    blacklist.add(sender);
    logInfo('Added sender to blacklist: $sender');
    return _prefs.setStringList(_blacklistKey, blacklist);
  }

  /// Remove sender from blacklist
  Future<bool> removeFromBlacklist(String sender) {
    final blacklist = getBlacklist();
    blacklist.remove(sender);
    logInfo('Removed sender from blacklist: $sender');
    return _prefs.setStringList(_blacklistKey, blacklist);
  }

  /// Check if sender should be filtered (returns true if should be filtered/blocked)
  bool shouldFilterSender(String sender) {
    final mode = getFilterMode();
    if (mode == 'none') {
      return false; // No filtering
    }

    final normalizedSender = sender.toLowerCase().trim();

    if (mode == 'whitelist') {
      final whitelist = getWhitelist();
      if (whitelist.isEmpty) {
        // Empty whitelist means allow all
        return false;
      }
      // Check if sender matches any whitelist entry (supports partial matching)
      final isAllowed = whitelist.any((allowed) {
        final normalizedAllowed = allowed.toLowerCase().trim();
        return normalizedSender.contains(normalizedAllowed) ||
            normalizedAllowed.contains(normalizedSender);
      });
      return !isAllowed; // Filter if not in whitelist
    }

    if (mode == 'blacklist') {
      final blacklist = getBlacklist();
      // Check if sender matches any blacklist entry (supports partial matching)
      final isBlocked = blacklist.any((blocked) {
        final normalizedBlocked = blocked.toLowerCase().trim();
        return normalizedSender.contains(normalizedBlocked) ||
            normalizedBlocked.contains(normalizedSender);
      });
      return isBlocked; // Filter if in blacklist
    }

    return false;
  }
}
