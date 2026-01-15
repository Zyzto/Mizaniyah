import 'package:flutter/material.dart';
import 'package:flutter_logging_service/flutter_logging_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for managing quiet hours (when notifications should be queued)
class QuietHoursService with Loggable {
  static const String _enabledKey = 'quiet_hours_enabled';
  static const String _startTimeKey = 'quiet_hours_start';
  static const String _endTimeKey = 'quiet_hours_end';

  final SharedPreferences _prefs;

  QuietHoursService(this._prefs);

  /// Check if quiet hours are enabled
  bool isEnabled() {
    return _prefs.getBool(_enabledKey) ?? false;
  }

  /// Enable or disable quiet hours
  Future<bool> setEnabled(bool enabled) async {
    logInfo('Quiet hours ${enabled ? "enabled" : "disabled"}');
    return _prefs.setBool(_enabledKey, enabled);
  }

  /// Get quiet hours start time (HH:mm format)
  String getStartTime() {
    return _prefs.getString(_startTimeKey) ?? '22:00';
  }

  /// Set quiet hours start time (HH:mm format)
  Future<bool> setStartTime(String time) async {
    if (!_isValidTimeFormat(time)) {
      logWarning('Invalid time format: $time');
      return false;
    }
    logInfo('Quiet hours start time set to: $time');
    return _prefs.setString(_startTimeKey, time);
  }

  /// Get quiet hours end time (HH:mm format)
  String getEndTime() {
    return _prefs.getString(_endTimeKey) ?? '08:00';
  }

  /// Set quiet hours end time (HH:mm format)
  Future<bool> setEndTime(String time) async {
    if (!_isValidTimeFormat(time)) {
      logWarning('Invalid time format: $time');
      return false;
    }
    logInfo('Quiet hours end time set to: $time');
    return _prefs.setString(_endTimeKey, time);
  }

  /// Check if current time is within quiet hours
  bool isQuietHours(DateTime now) {
    if (!isEnabled()) {
      return false;
    }

    final startTime = getStartTime();
    final endTime = getEndTime();
    final start = _parseTime(startTime);
    final end = _parseTime(endTime);

    if (start == null || end == null) {
      return false;
    }

    final currentTime = TimeOfDay.fromDateTime(now);

    // Handle case where quiet hours span midnight
    if (start.hour > end.hour ||
        (start.hour == end.hour && start.minute >= end.minute)) {
      // Quiet hours span midnight (e.g., 22:00 to 08:00)
      return _isTimeAfterOrEqual(currentTime, start) ||
          _isTimeBefore(currentTime, end);
    } else {
      // Quiet hours within same day (e.g., 22:00 to 23:00)
      return _isTimeAfterOrEqual(currentTime, start) &&
          _isTimeBefore(currentTime, end);
    }
  }

  /// Check if time is after or equal to target
  bool _isTimeAfterOrEqual(TimeOfDay time, TimeOfDay target) {
    if (time.hour > target.hour) return true;
    if (time.hour < target.hour) return false;
    return time.minute >= target.minute;
  }

  /// Check if time is before target
  bool _isTimeBefore(TimeOfDay time, TimeOfDay target) {
    if (time.hour < target.hour) return true;
    if (time.hour > target.hour) return false;
    return time.minute < target.minute;
  }

  /// Parse time string (HH:mm) to TimeOfDay
  TimeOfDay? _parseTime(String timeStr) {
    try {
      final parts = timeStr.split(':');
      if (parts.length != 2) return null;
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      if (hour < 0 || hour > 23 || minute < 0 || minute > 59) {
        return null;
      }
      return TimeOfDay(hour: hour, minute: minute);
    } catch (e) {
      logWarning('Failed to parse time: $timeStr, error: $e');
      return null;
    }
  }

  /// Validate time format (HH:mm)
  bool _isValidTimeFormat(String time) {
    final parsed = _parseTime(time);
    return parsed != null;
  }
}
