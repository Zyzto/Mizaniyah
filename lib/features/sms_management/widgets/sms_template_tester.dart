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
    });

    final testSms = _testSmsController.text.trim();
    if (testSms.isEmpty) {
      setState(() {
        _errorMessage = 'enter_sms_to_test'.tr();
      });
      return;
    }

    // Validate pattern
    try {
      final patternRegex = RegExp(widget.pattern, caseSensitive: false);
      _patternMatches = patternRegex.hasMatch(testSms);
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
        setState(() {
          _parsedData = parsed;
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
                        Text(
                          'template_matched_successfully'.tr(),
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildParsedDataRow('store_name'.tr(), _parsedData!.storeName),
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
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
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
}
