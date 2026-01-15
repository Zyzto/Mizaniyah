import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:drift/drift.dart' as drift;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_logging_service/flutter_logging_service.dart';
import 'dart:convert';
import '../../../core/database/app_database.dart' as db;
import '../../../core/database/providers/dao_providers.dart';
import '../../../core/widgets/error_snackbar.dart';
import '../../../core/widgets/enhanced_text_form_field.dart';
import '../../../core/widgets/loading_button.dart';
import '../../../core/services/sms_parsing_service.dart';
import '../../../core/navigation/route_paths.dart';
import '../widgets/sms_template_tester.dart';
import 'sms_template_builder_wizard.dart';

class SmsTemplateFormPage extends ConsumerStatefulWidget {
  final db.SmsTemplate? template;
  final String? initialSms;
  final String? initialSender;

  const SmsTemplateFormPage({
    super.key,
    this.template,
    this.initialSms,
    this.initialSender,
  });

  @override
  ConsumerState<SmsTemplateFormPage> createState() =>
      _SmsTemplateFormPageState();
}

class _SmsTemplateFormPageState extends ConsumerState<SmsTemplateFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  final _patternFieldKey = GlobalKey();
  late TextEditingController _senderPatternController;
  late TextEditingController _patternController;
  late TextEditingController _extractionRulesController;
  late TextEditingController _priorityController;
  bool _isActive = true;
  bool _isSaving = false;
  bool _patternReceivedFromWizard = false;
  bool _showSaveReminder = false;

  @override
  void initState() {
    super.initState();
    _senderPatternController = TextEditingController(
      text: widget.template?.senderPattern ?? '',
    );
    _patternController = TextEditingController(
      text: widget.template?.pattern ?? '',
    );
    _extractionRulesController = TextEditingController(
      text: widget.template?.extractionRules ?? _getDefaultExtractionRules(),
    );
    _priorityController = TextEditingController(
      text: (widget.template?.priority ?? 0).toString(),
    );
    _isActive = widget.template?.isActive ?? true;

    // Pre-fill sender pattern with exact sender name if provided
    if (widget.initialSender != null && widget.initialSender!.isNotEmpty) {
      // Escape regex special characters for exact match
      final escapedSender = widget.initialSender!.replaceAllMapped(
        RegExp(r'[.*+?^${}()|[\]\\]'),
        (match) => '\\${match.group(0)}',
      );
      _senderPatternController.text = escapedSender;
    }

    // Add listeners to rebuild when text changes (for pattern tester visibility)
    _patternController.addListener(() {
      setState(() {});
    });
    _extractionRulesController.addListener(() {
      setState(() {});
    });

    // Auto-launch visual builder if initialSms is provided
    if (widget.initialSms != null && widget.initialSms!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _launchPatternBuilder();
        }
      });
    }
  }

  @override
  void dispose() {
    _senderPatternController.dispose();
    _patternController.dispose();
    _extractionRulesController.dispose();
    _priorityController.dispose();
    _scrollController.dispose();
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
    HapticFeedback.lightImpact();
    final result = await context.push<TemplateBuilderResult>(
      widget.initialSms != null && widget.initialSms!.isNotEmpty
          ? '${RoutePaths.smsTemplateBuilder}?initialSms=${Uri.encodeComponent(widget.initialSms!)}'
          : RoutePaths.smsTemplateBuilder,
    );

    if (result != null && mounted && context.mounted) {
      HapticFeedback.heavyImpact();
      setState(() {
        _patternController.text = result.pattern;
        _extractionRulesController.text = result.extractionRules;
        _patternReceivedFromWizard = true;
        _showSaveReminder = true;
      });
      // Log to verify pattern was received
      Log.info(
        '[TemplateForm] Pattern received: ${result.pattern.length} chars',
      );
      Log.debug(
        '[TemplateForm] Pattern: ${result.pattern.substring(0, result.pattern.length > 50 ? 50 : result.pattern.length)}...',
      );
      Log.debug(
        '[TemplateForm] Extraction rules: ${result.extractionRules.length} chars',
      );

      // Auto-scroll to pattern field after a short delay
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _patternFieldKey.currentContext != null) {
          Scrollable.ensureVisible(
            _patternFieldKey.currentContext!,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
        }
      });

      // Show success message
      ErrorSnackbar.showSuccess(context, 'pattern_received_from_wizard'.tr());

      // Hide the banner after 5 seconds
      Future.delayed(const Duration(seconds: 5), () {
        if (mounted) {
          setState(() {
            _patternReceivedFromWizard = false;
          });
        }
      });
    } else {
      Log.warning('[TemplateForm] No pattern result returned from wizard');
    }
  }

  Future<void> _save() async {
    final formState = _formKey.currentState;
    if (formState == null || !formState.validate()) {
      HapticFeedback.mediumImpact();
      return;
    }

    if (!mounted) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final dao = ref.read(smsTemplateDaoProvider);

      // Validate pattern and extraction rules
      final pattern = _patternController.text.trim();
      final extractionRules = _extractionRulesController.text.trim();

      // Validate extraction rules JSON
      try {
        jsonDecode(extractionRules);
      } catch (e) {
        if (!mounted || !context.mounted) return;
        HapticFeedback.heavyImpact();
        ErrorSnackbar.show(
          context,
          'invalid_extraction_rules'.tr(args: [e.toString()]),
        );
        return;
      }

      // Validate template using parsing service
      final validationErrors = SmsParsingService.validateTemplate(
        pattern,
        extractionRules,
      );
      if (validationErrors.isNotEmpty) {
        if (!mounted || !context.mounted) return;
        HapticFeedback.heavyImpact();
        ErrorSnackbar.show(
          context,
          'template_validation_failed'.tr(args: [validationErrors.join('\n')]),
        );
        return;
      }

      final senderPattern = _senderPatternController.text.trim();
      final senderPatternValue = senderPattern.isEmpty
          ? const drift.Value<String?>.absent()
          : drift.Value<String?>(senderPattern);

      if (widget.template == null) {
        // Create new template
        await dao.insertTemplate(
          db.SmsTemplatesCompanion(
            senderPattern: senderPatternValue,
            pattern: drift.Value(_patternController.text.trim()),
            extractionRules: drift.Value(
              _extractionRulesController.text.trim(),
            ),
            priority: drift.Value(int.tryParse(_priorityController.text) ?? 0),
            isActive: drift.Value(_isActive),
          ),
        );
        if (!mounted || !context.mounted) return;
        HapticFeedback.heavyImpact();
        ErrorSnackbar.showSuccess(context, 'sms_template_created'.tr());
        setState(() {
          _showSaveReminder = false;
        });
        context.pop();
      } else {
        // Update existing template
        await dao.updateTemplate(
          db.SmsTemplatesCompanion(
            id: drift.Value(widget.template!.id),
            senderPattern: senderPatternValue,
            pattern: drift.Value(_patternController.text.trim()),
            extractionRules: drift.Value(
              _extractionRulesController.text.trim(),
            ),
            priority: drift.Value(int.tryParse(_priorityController.text) ?? 0),
            isActive: drift.Value(_isActive),
          ),
        );
        if (!mounted || !context.mounted) return;
        HapticFeedback.heavyImpact();
        ErrorSnackbar.showSuccess(context, 'sms_template_updated'.tr());
        context.pop();
      }
    } catch (e) {
      if (!mounted || !context.mounted) return;
      HapticFeedback.heavyImpact();
      ErrorSnackbar.show(
        context,
        'template_save_failed'.tr(args: [e.toString()]),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.template == null
              ? 'new_sms_template'.tr()
              : 'edit_sms_template'.tr(),
        ),
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.save),
              tooltip: 'save'.tr(),
              onPressed: _save,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          controller: _scrollController,
          padding: const EdgeInsets.all(16),
          children: [
            // Success banner when pattern is received from wizard
            if (_patternReceivedFromWizard)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary,
                    width: 2,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'pattern_received_from_wizard'.tr(),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(
                                context,
                              ).colorScheme.onPrimaryContainer,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'click_save_to_create_template'.tr(),
                            style: TextStyle(
                              fontSize: 13,
                              color: Theme.of(
                                context,
                              ).colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        setState(() {
                          _patternReceivedFromWizard = false;
                        });
                      },
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ],
                ),
              ),
            // Save reminder banner
            if (_showSaveReminder &&
                !_patternReceivedFromWizard &&
                _patternController.text.trim().isNotEmpty)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(
                      context,
                    ).colorScheme.outline.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'click_save_to_create_template'.tr(),
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            // Sender pattern (optional)
            EnhancedTextFormField(
              controller: _senderPatternController,
              labelText: 'sender_pattern'.tr(),
              hintText: 'sender_pattern_hint'.tr(),
              textInputAction: TextInputAction.next,
              semanticLabel: 'sender_pattern'.tr(),
              helperText: 'sender_pattern_helper'.tr(),
              validator: (value) {
                if (value != null && value.trim().isNotEmpty) {
                  try {
                    RegExp(value.trim());
                  } catch (e) {
                    return 'invalid_regex'.tr(args: [e.toString()]);
                  }
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: EnhancedTextFormField(
                    key: _patternFieldKey,
                    controller: _patternController,
                    labelText: 'pattern_regex'.tr(),
                    hintText: 'pattern_regex_hint'.tr(),
                    textInputAction: TextInputAction.next,
                    maxLines: 3,
                    semanticLabel: 'pattern_regex'.tr(),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'pattern_required'.tr();
                      }
                      try {
                        RegExp(value.trim());
                      } catch (e) {
                        return 'invalid_regex'.tr(args: [e.toString()]);
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.auto_fix_high),
                  tooltip: 'visual_pattern_builder'.tr(),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    _launchPatternBuilder();
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'pattern_helper'.tr(),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: 24),
            EnhancedTextFormField(
              controller: _extractionRulesController,
              labelText: 'extraction_rules_json'.tr(),
              hintText: 'extraction_rules_hint'.tr(),
              textInputAction: TextInputAction.next,
              maxLines: 12,
              semanticLabel: 'extraction_rules_json'.tr(),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'extraction_rules_required'.tr();
                }
                try {
                  jsonDecode(value.trim());
                } catch (e) {
                  return 'invalid_json'.tr(args: [e.toString()]);
                }
                // Additional validation will be done in _save()
                return null;
              },
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'extraction_rules_helper'.tr(),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Pattern tester widget
            if (_patternController.text.trim().isNotEmpty &&
                _extractionRulesController.text.trim().isNotEmpty)
              SmsTemplateTester(
                pattern: _patternController.text.trim(),
                extractionRules: _extractionRulesController.text.trim(),
              ),
            if (_patternController.text.trim().isNotEmpty &&
                _extractionRulesController.text.trim().isNotEmpty)
              const SizedBox(height: 24),
            EnhancedTextFormField(
              controller: _priorityController,
              labelText: 'priority'.tr(),
              hintText: '0',
              textInputAction: TextInputAction.done,
              keyboardType: TextInputType.number,
              semanticLabel: 'priority'.tr(),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'priority_helper'.tr(),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: 24),
            SwitchListTile(
              title: Text('active'.tr()),
              subtitle: Text('active_template_description'.tr()),
              value: _isActive,
              onChanged: (value) {
                HapticFeedback.lightImpact();
                setState(() {
                  _isActive = value;
                });
              },
            ),
            const SizedBox(height: 32),
            LoadingButton(
              onPressed: _isSaving ? null : _save,
              text: 'save_template'.tr(),
              icon: Icons.save,
              isLoading: _isSaving,
              semanticLabel: 'save_template'.tr(),
            ),
          ],
        ),
      ),
    );
  }
}
