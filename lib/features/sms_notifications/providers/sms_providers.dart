import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:another_telephony/telephony.dart';
import 'package:flutter_logging_service/flutter_logging_service.dart';
import '../../../core/services/sms_reader_service.dart';
import '../../../core/services/sms_parsing_service.dart';
import '../../../core/database/providers/dao_providers.dart';

/// SMS with parsing status
class SmsWithStatus {
  final SmsMessage sms;
  final Map<String, dynamic>? matchResult;
  final bool isMatched;
  final bool isParsing; // True while parsing is in progress

  SmsWithStatus({
    required this.sms,
    this.matchResult,
    required this.isMatched,
    this.isParsing = false,
  });

  SmsWithStatus copyWith({
    SmsMessage? sms,
    Map<String, dynamic>? matchResult,
    bool? isMatched,
    bool? isParsing,
  }) {
    return SmsWithStatus(
      sms: sms ?? this.sms,
      matchResult: matchResult ?? this.matchResult,
      isMatched: isMatched ?? this.isMatched,
      isParsing: isParsing ?? this.isParsing,
    );
  }
}

/// Provider for SMS list with parsing status
/// Uses progressive loading: shows SMS immediately, parses in background
final smsListProvider = NotifierProvider<SmsListNotifier, AsyncValue<List<SmsWithStatus>>>(() {
  return SmsListNotifier();
});

class SmsListNotifier extends Notifier<AsyncValue<List<SmsWithStatus>>> {
  final SmsReaderService _smsReaderService = SmsReaderService.instance;
  final Map<String, SmsWithStatus> _parsingCache = {};
  bool _isLoading = false;
  bool _isParsing = false;
  int _loadedCount = 0;
  static const _pageSize = 50;

  @override
  AsyncValue<List<SmsWithStatus>> build() {
    // Keep provider alive to persist state across navigation
    ref.keepAlive();
    // Load initial SMS when provider is first accessed
    Future.microtask(() => _loadInitialSms());
    return const AsyncValue.loading();
  }

  Future<void> _loadInitialSms() async {
    if (_isLoading) return;
    _isLoading = true;

    try {
      await _smsReaderService.init();
      final sms = await _smsReaderService.getInboxSms(
        limit: _pageSize,
        offset: 0,
        forceRefresh: false,
      );

      // Show SMS immediately without parsing
      final smsWithStatus = sms.map((s) => SmsWithStatus(
        sms: s,
        isMatched: false,
        isParsing: true,
      )).toList();

      state = AsyncValue.data(smsWithStatus);
      _loadedCount = sms.length;

      // Parse in background
      _parseSmsInBackground(smsWithStatus);
    } catch (e, stackTrace) {
      Log.error(
        'Error loading SMS',
        error: e,
        stackTrace: stackTrace,
      );
      state = AsyncValue.error(e, stackTrace);
    } finally {
      _isLoading = false;
    }
  }

  Future<void> _parseSmsInBackground(List<SmsWithStatus> smsList, {int startIndex = 0}) async {
    // Prevent concurrent parsing
    if (_isParsing) return;
    _isParsing = true;

    try {
      // Get active templates from DAO
      final smsTemplateDao = ref.read(smsTemplateDaoProvider);
      final templates = await smsTemplateDao.getActiveTemplates();
    
    if (templates.isEmpty) {
      // No templates, mark all as not matched
      _updateParsingResults(
        smsList.map((s) => s.copyWith(isMatched: false, isParsing: false)).toList(),
        startIndex: startIndex,
      );
      return;
    }

    // Parse in batches to avoid blocking
    const batchSize = 10;
    for (int i = 0; i < smsList.length; i += batchSize) {
      final batch = smsList.sublist(
        i,
        (i + batchSize).clamp(0, smsList.length),
      );

      // Process batch
      final results = <SmsWithStatus>[];
      for (final smsWithStatus in batch) {
        final body = smsWithStatus.sms.body ?? '';
        if (body.isEmpty) {
          results.add(smsWithStatus.copyWith(isMatched: false, isParsing: false));
          continue;
        }

        // Check cache first
        final cacheKey = '${smsWithStatus.sms.date}_${smsWithStatus.sms.address}';
        if (_parsingCache.containsKey(cacheKey)) {
          results.add(_parsingCache[cacheKey]!);
          continue;
        }

        // Parse SMS
        final match = SmsParsingService.findMatchingTemplate(body, templates);
        final parsed = smsWithStatus.copyWith(
          matchResult: match,
          isMatched: match != null,
          isParsing: false,
        );

        // Cache result
        _parsingCache[cacheKey] = parsed;
        results.add(parsed);
      }

      // Update state progressively
      if (state.hasValue) {
        final currentList = List<SmsWithStatus>.from(state.value!);
        // Replace parsed items using correct starting index
        for (int j = 0; j < results.length; j++) {
          final index = startIndex + i + j;
          if (index < currentList.length) {
            currentList[index] = results[j];
          }
        }
        state = AsyncValue.data(currentList);
      }

      // Small delay to allow UI to update
      await Future.delayed(const Duration(milliseconds: 50));
    }
    } finally {
      _isParsing = false;
    }
  }

  void _updateParsingResults(List<SmsWithStatus> results, {int startIndex = 0}) {
    if (state.hasValue) {
      final currentList = List<SmsWithStatus>.from(state.value!);
      // Merge results using correct starting index
      for (int i = 0; i < results.length; i++) {
        final index = startIndex + i;
        if (index < currentList.length) {
          currentList[index] = results[i];
        }
      }
      state = AsyncValue.data(currentList);
    }
  }

  Future<void> loadMore() async {
    if (_isLoading || !state.hasValue) return;
    _isLoading = true;

    try {
      final sms = await _smsReaderService.getInboxSms(
        limit: _pageSize,
        offset: _loadedCount,
        forceRefresh: false,
      );

      if (sms.isEmpty) return; // No more SMS

      final smsWithStatus = sms.map((s) => SmsWithStatus(
        sms: s,
        isMatched: false,
        isParsing: true,
      )).toList();

      final currentList = List<SmsWithStatus>.from(state.value!);
      final startIndex = currentList.length;
      currentList.addAll(smsWithStatus);
      state = AsyncValue.data(currentList);
      _loadedCount += sms.length;

      // Parse in background with correct starting index
      _parseSmsInBackground(smsWithStatus, startIndex: startIndex);
    } catch (e, stackTrace) {
      Log.error(
        'Error loading more SMS',
        error: e,
        stackTrace: stackTrace,
      );
    } finally {
      _isLoading = false;
    }
  }

  Future<void> refresh() async {
    _loadedCount = 0;
    _parsingCache.clear();
    _smsReaderService.clearCache();
    state = const AsyncValue.loading();
    await _loadInitialSms();
  }

  Future<void> filterByMatchedSms(bool showMatchedSmsOnly) async {
    if (_isLoading) return;
    _isLoading = true;
    state = const AsyncValue.loading();

    try {
      await _smsReaderService.init();
      List<SmsMessage> sms;

      if (showMatchedSmsOnly) {
        final smsTemplateDao = ref.read(smsTemplateDaoProvider);
        sms = await _smsReaderService.filterSmsByTemplates(
          smsTemplateDao,
          limit: _pageSize,
          offset: 0,
        );
      } else {
        sms = await _smsReaderService.getInboxSms(
          limit: _pageSize,
          offset: 0,
          forceRefresh: false,
        );
      }

      final smsWithStatus = sms.map((s) => SmsWithStatus(
        sms: s,
        isMatched: false,
        isParsing: true,
      )).toList();

      state = AsyncValue.data(smsWithStatus);
      _loadedCount = sms.length;

      // Parse in background
      _parseSmsInBackground(smsWithStatus);
    } catch (e, stackTrace) {
      Log.error(
        'Error filtering SMS',
        error: e,
        stackTrace: stackTrace,
      );
      state = AsyncValue.error(e, stackTrace);
    } finally {
      _isLoading = false;
    }
  }
}
