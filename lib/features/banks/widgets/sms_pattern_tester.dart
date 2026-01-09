import 'package:flutter/material.dart';
import 'dart:convert';
import '../../../core/services/sms_parsing_service.dart';

/// Widget for testing SMS patterns before saving templates
class SmsPatternTester extends StatefulWidget {
  final String pattern;
  final String extractionRules;

  const SmsPatternTester({
    super.key,
    required this.pattern,
    required this.extractionRules,
  });

  @override
  State<SmsPatternTester> createState() => _SmsPatternTesterState();
}

class _SmsPatternTesterState extends State<SmsPatternTester> {
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
        _errorMessage = 'Please enter an SMS message to test';
      });
      return;
    }

    // Validate pattern
    try {
      final patternRegex = RegExp(widget.pattern, caseSensitive: false);
      _patternMatches = patternRegex.hasMatch(testSms);
    } catch (e) {
      setState(() {
        _errorMessage = 'Invalid pattern regex: $e';
      });
      return;
    }

    if (!_patternMatches) {
      setState(() {
        _errorMessage = 'SMS does not match the pattern';
      });
      return;
    }

    // Validate extraction rules JSON
    try {
      jsonDecode(widget.extractionRules);
    } catch (e) {
      setState(() {
        _errorMessage = 'Invalid extraction rules JSON: $e';
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
          _errorMessage =
              'Failed to parse SMS. Check that required fields (store_name, amount) are extracted correctly.';
        });
      } else {
        setState(() {
          _parsedData = parsed;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error testing pattern: $e';
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
                  'Test Pattern',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _testSmsController,
              decoration: const InputDecoration(
                labelText: 'Test SMS Message',
                hintText: 'Paste an SMS message to test the pattern',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _testPattern,
                icon: const Icon(Icons.play_arrow),
                label: const Text('Test Pattern'),
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
                          'Pattern matched successfully!',
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
                    _buildParsedDataRow('Store Name', _parsedData!.storeName),
                    _buildParsedDataRow(
                      'Amount',
                      _parsedData!.amount != null
                          ? '${_parsedData!.amount!.toStringAsFixed(2)} ${_parsedData!.currency ?? 'USD'}'
                          : null,
                    ),
                    if (_parsedData!.cardLast4Digits != null)
                      _buildParsedDataRow(
                        'Card (Last 4)',
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
                        'Pattern matches, but extraction failed. Check your extraction rules.',
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
              style: TextStyle(color: value != null ? null : Colors.grey),
            ),
          ),
        ],
      ),
    );
  }
}
