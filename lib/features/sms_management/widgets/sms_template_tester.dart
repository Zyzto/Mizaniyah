import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import 'dart:convert';
import '../../../core/services/sms_parsing_service.dart';

/// Widget for testing SMS templates before saving
class SmsTemplateTester extends StatefulWidget {
  final String pattern;
  final String extractionRules;

  const SmsTemplateTester({
    super.key,
    required this.pattern,
    required this.extractionRules,
  });

  @override
  State<SmsTemplateTester> createState() => _SmsTemplateTesterState();
}

class _SmsTemplateTesterState extends State<SmsTemplateTester> {
  final TextEditingController _testSmsController = TextEditingController();
  ParsedSmsData? _parsedData;
  String? _errorMessage;
  bool _patternMatches = false;
  double? _confidenceScore;
  int _captureGroupCount = 0;

  @override
  void dispose() {
    _testSmsController.dispose();
    super.dispose();
  }

  void _testPattern() {
    setState(() {
      _parsedData = null;
      _errorMessage = null;
      _patternMatches = false;
      _confidenceScore = null;
      _captureGroupCount = 0;
    });

    final testSms = _testSmsController.text.trim();
    if (testSms.isEmpty) {
      setState(() {
        _errorMessage = 'enter_sms_to_test'.tr();
      });
      return;
    }

    // Validate pattern
    RegExpMatch? regexMatch;
    try {
      final patternRegex = RegExp(
        widget.pattern,
        caseSensitive: false,
        multiLine: true,
        dotAll: true,
      );
      regexMatch = patternRegex.firstMatch(testSms);
      _patternMatches = regexMatch != null;
      if (regexMatch != null) {
        _captureGroupCount = regexMatch.groupCount;
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'invalid_pattern_regex'.tr(args: [e.toString()]);
      });
      return;
    }

    if (!_patternMatches) {
      setState(() {
        _errorMessage = 'sms_no_match'.tr();
      });
      return;
    }

    // Validate extraction rules JSON
    try {
      jsonDecode(widget.extractionRules);
    } catch (e) {
      setState(() {
        _errorMessage = 'invalid_extraction_rules'.tr(args: [e.toString()]);
      });
      return;
    }

    // Test parsing
    try {
      final parsed = SmsParsingService.testPattern(
        testSms,
        widget.pattern,
        widget.extractionRules,
      );

      if (parsed == null) {
        setState(() {
          _errorMessage = 'parse_failed'.tr();
        });
      } else {
        // Calculate confidence score
        double confidence = 0.5; // Base confidence
        
        // Higher confidence if pattern matches a significant portion
        if (regexMatch != null) {
          final matchLength = regexMatch.end - regexMatch.start;
          final smsLength = testSms.length;
          if (smsLength > 0) {
            confidence += (matchLength / smsLength) * 0.2;
          }
          // Bonus for capture groups
          confidence += (_captureGroupCount / 10.0).clamp(0.0, 0.15);
        }
        
        // Bonus for extracted fields
        int extractedFields = 0;
        if (parsed.storeName != null && parsed.storeName!.isNotEmpty) extractedFields++;
        if (parsed.amount != null && parsed.amount! > 0) extractedFields++;
        if (parsed.currency != null && parsed.currency!.isNotEmpty) extractedFields++;
        if (parsed.cardLast4Digits != null) extractedFields++;
        confidence += (extractedFields / 4.0) * 0.15;
        
        setState(() {
          _parsedData = parsed;
          _confidenceScore = confidence.clamp(0.0, 1.0);
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'test_template_error'.tr(args: [e.toString()]);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.bug_report, size: 20),
                const SizedBox(width: 8),
                Text(
                  'test_template'.tr(),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _testSmsController,
              decoration: InputDecoration(
                labelText: 'test_sms_message'.tr(),
                hintText: 'paste_sms_to_test'.tr(),
                border: const OutlineInputBorder(),
              ),
              maxLines: 3,
              keyboardType: TextInputType.multiline,
              textInputAction: TextInputAction.newline,
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  _testPattern();
                },
                icon: const Icon(Icons.play_arrow),
                label: Text('test_template'.tr()),
              ),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: Theme.of(context).colorScheme.onErrorContainer,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (_patternMatches && _parsedData != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: Theme.of(
                            context,
                          ).colorScheme.onPrimaryContainer,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'template_matched_successfully'.tr(),
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        // Confidence badge
                        if (_confidenceScore != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _getConfidenceColor(_confidenceScore!),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${(_confidenceScore! * 100).toStringAsFixed(0)}%',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ],
                    ),
                    // Capture groups info
                    if (_captureGroupCount > 0) ...[
                      const SizedBox(height: 8),
                      Text(
                        'capture_groups_found'.tr(args: ['$_captureGroupCount']),
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(
                            context,
                          ).colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    _buildParsedDataRow(
                      'store_name'.tr(),
                      _parsedData!.storeName,
                    ),
                    _buildParsedDataRow(
                      'amount'.tr(),
                      _parsedData!.amount != null
                          ? '${_parsedData!.amount!.toStringAsFixed(2)} ${_parsedData!.currency ?? 'USD'}'
                          : null,
                    ),
                    if (_parsedData!.cardLast4Digits != null)
                      _buildParsedDataRow(
                        'card_last4'.tr(),
                        _parsedData!.cardLast4Digits,
                      ),
                    if (_parsedData!.transactionDate != null)
                      _buildParsedDataRow(
                        'date'.tr(),
                        DateFormat('yyyy-MM-dd').format(_parsedData!.transactionDate!),
                      ),
                  ],
                ),
              ),
            ],
            if (_patternMatches &&
                _parsedData == null &&
                _errorMessage == null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Theme.of(context).colorScheme.onSecondaryContainer,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'template_match_extraction_failed'.tr(),
                        style: TextStyle(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSecondaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildParsedDataRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 80, maxWidth: 120),
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value ?? 'N/A',
              style: TextStyle(
                color: value != null
                    ? null
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getConfidenceColor(double confidence) {
    final colorScheme = Theme.of(context).colorScheme;
    if (confidence >= 0.7) {
      return colorScheme.primary;
    } else if (confidence >= 0.5) {
      return colorScheme.secondary;
    } else {
      return colorScheme.error;
    }
  }
}
