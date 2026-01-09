import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import 'dart:convert';
import '../providers/bank_providers.dart';
import '../../../core/database/app_database.dart' as db;
import '../../../core/widgets/error_snackbar.dart';
import '../../../core/widgets/bank_selector.dart';
import '../../../core/services/sms_parsing_service.dart';
import '../widgets/sms_pattern_tester.dart';
import 'sms_pattern_builder_wizard.dart';

class SmsTemplateFormPage extends ConsumerStatefulWidget {
  final db.SmsTemplate? template;
  final int? bankId; // Pre-select bank if provided

  const SmsTemplateFormPage({super.key, this.template, this.bankId});

  @override
  ConsumerState<SmsTemplateFormPage> createState() =>
      _SmsTemplateFormPageState();
}

class _SmsTemplateFormPageState extends ConsumerState<SmsTemplateFormPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _patternController;
  late TextEditingController _extractionRulesController;
  int? _selectedBankId;
  int _priority = 0;
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    _patternController = TextEditingController(
      text: widget.template?.pattern ?? '',
    );
    _extractionRulesController = TextEditingController(
      text: widget.template?.extractionRules ?? _getDefaultExtractionRules(),
    );
    _selectedBankId = widget.template?.bankId ?? widget.bankId;
    _priority = widget.template?.priority ?? 0;
    _isActive = widget.template?.isActive ?? true;

    // Add listeners to rebuild when text changes (for pattern tester visibility)
    _patternController.addListener(() {
      setState(() {});
    });
    _extractionRulesController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _patternController.dispose();
    _extractionRulesController.dispose();
    super.dispose();
  }

  String _getDefaultExtractionRules() {
    return jsonEncode({
      'store_name': {'group': 1},
      'amount': {'group': 2},
      'currency': 'USD',
      'card_last4': {'group': 3},
    });
  }

  Future<void> _launchPatternBuilder() async {
    final result = await Navigator.of(context).push<PatternBuilderResult>(
      MaterialPageRoute(
        builder: (context) => SmsPatternBuilderWizard(bankId: _selectedBankId),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _patternController.text = result.pattern;
        _extractionRulesController.text = result.extractionRules;
      });
      ErrorSnackbar.showSuccess(
        context,
        'Pattern generated from visual builder',
      );
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedBankId == null) {
      ErrorSnackbar.show(context, 'Please select a bank');
      return;
    }

    try {
      final repository = ref.read(bankRepositoryProvider);

      // Validate pattern and extraction rules
      final pattern = _patternController.text.trim();
      final extractionRules = _extractionRulesController.text.trim();

      // Validate extraction rules JSON
      try {
        jsonDecode(extractionRules);
      } catch (e) {
        ErrorSnackbar.show(context, 'Invalid extraction rules JSON: $e');
        return;
      }

      // Validate template using parsing service
      final validationErrors = SmsParsingService.validateTemplate(
        pattern,
        extractionRules,
      );
      if (validationErrors.isNotEmpty) {
        ErrorSnackbar.show(
          context,
          'Template validation failed:\n${validationErrors.join('\n')}',
        );
        return;
      }

      if (widget.template == null) {
        // Create new template
        await repository.createTemplate(
          db.SmsTemplatesCompanion(
            bankId: drift.Value(_selectedBankId!),
            pattern: drift.Value(_patternController.text.trim()),
            extractionRules: drift.Value(
              _extractionRulesController.text.trim(),
            ),
            priority: drift.Value(_priority),
            isActive: drift.Value(_isActive),
          ),
        );
        if (mounted) {
          ErrorSnackbar.showSuccess(context, 'SMS template created');
          Navigator.of(context).pop();
        }
      } else {
        // Update existing template
        await repository.updateTemplate(
          db.SmsTemplatesCompanion(
            id: drift.Value(widget.template!.id),
            bankId: drift.Value(_selectedBankId!),
            pattern: drift.Value(_patternController.text.trim()),
            extractionRules: drift.Value(
              _extractionRulesController.text.trim(),
            ),
            priority: drift.Value(_priority),
            isActive: drift.Value(_isActive),
          ),
        );
        if (mounted) {
          ErrorSnackbar.showSuccess(context, 'SMS template updated');
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      if (mounted) {
        ErrorSnackbar.show(context, 'Failed to save template: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.template == null ? 'New SMS Template' : 'Edit SMS Template',
        ),
        actions: [IconButton(icon: const Icon(Icons.save), onPressed: _save)],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            BankSelector(
              selectedBankId: _selectedBankId,
              onBankSelected: (bankId) {
                setState(() {
                  _selectedBankId = bankId;
                });
              },
              label: 'Bank',
              enabled:
                  widget.template ==
                  null, // Can't change bank for existing template
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _patternController,
                    decoration: const InputDecoration(
                      labelText: 'Pattern (Regex)',
                      hintText: 'e.g., .*Amount:\\s*(\\d+\\.\\d+).*',
                      helperText:
                          'Regular expression pattern to match SMS body. Use capture groups for extraction.',
                    ),
                    maxLines: 3,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Pattern is required';
                      }
                      try {
                        RegExp(value.trim());
                      } catch (e) {
                        return 'Invalid regular expression: $e';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.auto_fix_high),
                  tooltip: 'Visual Pattern Builder',
                  onPressed: () => _launchPatternBuilder(),
                ),
              ],
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _extractionRulesController,
              decoration: const InputDecoration(
                labelText: 'Extraction Rules (JSON)',
                hintText: 'JSON object with extraction rules',
                helperText:
                    'Supports three formats:\n'
                    '• Capture groups: {"store_name": {"group": 1}} - uses capture group from pattern\n'
                    '• Regex patterns: {"amount": {"pattern": "Amount:\\s*([\\d,]+)"}} - uses separate regex\n'
                    '• Fixed values: {"currency": "USD"} - uses fixed string\n'
                    'Required fields: store_name, amount',
              ),
              maxLines: 12,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Extraction rules are required';
                }
                try {
                  jsonDecode(value.trim());
                } catch (e) {
                  return 'Invalid JSON: $e';
                }
                // Additional validation will be done in _save()
                return null;
              },
            ),
            const SizedBox(height: 24),
            // Pattern tester widget
            if (_patternController.text.trim().isNotEmpty &&
                _extractionRulesController.text.trim().isNotEmpty)
              SmsPatternTester(
                pattern: _patternController.text.trim(),
                extractionRules: _extractionRulesController.text.trim(),
              ),
            const SizedBox(height: 24),
            TextFormField(
              initialValue: _priority.toString(),
              decoration: const InputDecoration(
                labelText: 'Priority',
                hintText: '0',
                helperText:
                    'Higher priority templates are checked first. Default is 0.',
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                _priority = int.tryParse(value) ?? 0;
              },
            ),
            const SizedBox(height: 24),
            SwitchListTile(
              title: const Text('Active'),
              subtitle: const Text(
                'Inactive templates won\'t be used for SMS parsing',
              ),
              value: _isActive,
              onChanged: (value) {
                setState(() {
                  _isActive = value;
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}
