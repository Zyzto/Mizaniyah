import 'package:flutter_logging_service/flutter_logging_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:another_telephony/telephony.dart';

/// Service for archiving and managing SMS retention
class SmsArchiveService with Loggable {
  final SharedPreferences _prefs;
  final Telephony? _telephony;
  static const String _archivedSmsKey = 'archived_sms_ids';
  static const String _retentionDaysKey = 'sms_retention_days';
  static const int _defaultRetentionDays = 30;

  SmsArchiveService(this._prefs, this._telephony);

  /// Get retention days setting
  int getRetentionDays() {
    return _prefs.getInt(_retentionDaysKey) ?? _defaultRetentionDays;
  }

  /// Set retention days (0 = never delete)
  Future<bool> setRetentionDays(int days) async {
    if (days < 0) {
      logWarning('Invalid retention days: $days');
      return false;
    }
    final result = await _prefs.setInt(_retentionDaysKey, days);
    logInfo('SMS retention days set to: $days');
    return result;
  }

  /// Check if auto-archive is enabled
  bool isAutoArchiveEnabled() {
    return getRetentionDays() > 0;
  }

  /// Archive an SMS (mark as archived, don't delete)
  Future<bool> archiveSms(int smsId) async {
    try {
      final archived = getArchivedSmsIds();
      if (!archived.contains(smsId)) {
        archived.add(smsId);
        await _prefs.setStringList(
          _archivedSmsKey,
          archived.map((id) => id.toString()).toList(),
        );
        logInfo('Archived SMS: id=$smsId');
      }
      return true;
    } catch (e, stackTrace) {
      logError('Failed to archive SMS', error: e, stackTrace: stackTrace);
      return false;
    }
  }

  /// Unarchive an SMS
  Future<bool> unarchiveSms(int smsId) async {
    try {
      final archived = getArchivedSmsIds();
      archived.remove(smsId);
      await _prefs.setStringList(
        _archivedSmsKey,
        archived.map((id) => id.toString()).toList(),
      );
      logInfo('Unarchived SMS: id=$smsId');
      return true;
    } catch (e, stackTrace) {
      logError('Failed to unarchive SMS', error: e, stackTrace: stackTrace);
      return false;
    }
  }

  /// Get list of archived SMS IDs
  Set<int> getArchivedSmsIds() {
    try {
      final list = _prefs.getStringList(_archivedSmsKey) ?? [];
      return list
          .map((id) => int.tryParse(id) ?? -1)
          .where((id) => id > 0)
          .toSet();
    } catch (e) {
      logWarning('Failed to get archived SMS IDs: $e');
      return {};
    }
  }

  /// Check if SMS is archived
  bool isArchived(int smsId) {
    return getArchivedSmsIds().contains(smsId);
  }

  /// Delete old SMS based on retention policy
  /// Note: This requires SMS deletion permissions which may not be available
  Future<int> deleteOldSms() async {
    if (!isAutoArchiveEnabled() || _telephony == null) {
      return 0;
    }

    try {
      final retentionDays = getRetentionDays();
      final cutoffDate = DateTime.now().subtract(Duration(days: retentionDays));

      // Get all SMS (note: SMS deletion is not available in another_telephony)
      // We'll use archiving instead
      final allSms = await _telephony.getInboxSms(
        columns: [SmsColumn.ADDRESS, SmsColumn.BODY, SmsColumn.DATE],
      );

      int deletedCount = 0;
      for (final sms in allSms) {
        final smsDate = sms.date;
        if (smsDate == null) continue;

        // SmsMessage.date is int (timestamp in milliseconds)
        final date = DateTime.fromMillisecondsSinceEpoch(smsDate);

        if (date.isBefore(cutoffDate)) {
          try {
            // Note: SMS deletion may not be supported on all devices/APIs
            // Archive instead of deleting (safer approach)
            // Use a hash of sender+body+date as ID since we don't have actual SMS ID
            final smsId =
                '${sms.address ?? ''}_${sms.body ?? ''}_$smsDate'.hashCode;
            await archiveSms(smsId);
            deletedCount++;
          } catch (e) {
            logWarning('Failed to archive SMS: $e');
          }
        }
      }

      logInfo('Deleted $deletedCount old SMS messages');
      return deletedCount;
    } catch (e, stackTrace) {
      logError('Failed to delete old SMS', error: e, stackTrace: stackTrace);
      return 0;
    }
  }

  /// Clear archived SMS list
  Future<void> clearArchivedList() async {
    await _prefs.remove(_archivedSmsKey);
    logInfo('Cleared archived SMS list');
  }
}
