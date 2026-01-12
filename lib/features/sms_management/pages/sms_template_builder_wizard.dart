import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_logging_service/flutter_logging_service.dart';
import '../widgets/sms_text_selector.dart';
import '../../../core/services/sms_pattern_generator.dart';
import '../../../core/services/sms_parsing_service.dart';
import '../../../core/widgets/error_snackbar.dart';

/// Result returned from the wizard
class TemplateBuilderResult {
  final String pattern;
  final String extractionRules;

  TemplateBuilderResult({required this.pattern, required this.extractionRules});
}

/// Visual SMS Template Builder Wizard
/// Allows users to visually build SMS templates by selecting and labeling parts
class SmsTemplateBuilderWizard extends ConsumerStatefulWidget {
  final String? initialSms;

  const SmsTemplateBuilderWizard({super.key, this.initialSms});

  @override
  ConsumerState<SmsTemplateBuilderWizard> createState() =>
      _SmsTemplateBuilderWizardState();
}

class _SmsTemplateBuilderWizardState
    extends ConsumerState<SmsTemplateBuilderWizard> {
  int _currentStep = 0;
  final PageController _pageController = PageController();

  // Step 1 data
  final TextEditingController _smsController = TextEditingController();

  // Step 2 data
  List<SmsTextSelection> _selections = [];

  // Step 3 data
  String? _generatedPattern;
  String? _generatedExtractionRules;
  ParsedSmsData? _previewData;
  bool _isGenerating = false;
  final ScrollController _step3ScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    if (widget.initialSms != null && widget.initialSms!.isNotEmpty) {
      _smsController.text = widget.initialSms!;
      // Skip step 1 (SMS input) and go directly to step 2 (select parts)
      _currentStep = 1;
      // Jump to the correct page after the first frame is built
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_pageController.hasClients) {
          _pageController.jumpToPage(1);
        }
      });
    }
  }

  @override
  void dispose() {
    _smsController.dispose();
    _pageController.dispose();
    _step3ScrollController.dispose();
    super.dispose();
  }

  Future<void> _nextStep() async {
    if (_currentStep < 3) {
      final nextStep = _currentStep + 1;

      // Validate before moving to step 3
      if (nextStep == 2) {
        if (!_canProceedToStep3()) {
          // Show error message
          HapticFeedback.heavyImpact();
          ErrorSnackbar.show(context, 'required_fields_missing'.tr());
          return; // Don't proceed
        }

        // Generate pattern when moving to step 3 (review) - BEFORE updating state
        if (_generatedPattern == null) {
          final smsText = _smsController.text.trim();
          Log.debug(
            '[TemplateBuilder] Moving to step 3, generating pattern...',
          );
          Log.debug(
            '[TemplateBuilder] SMS text length: ${smsText.length}, Selections count: ${_selections.length}',
          );
          if (smsText.isNotEmpty && _selections.isNotEmpty) {
            // Generate pattern asynchronously and wait for it
            await _generatePattern();
            // Pattern generation will handle navigation to step 3
            return;
          } else {
            Log.warning(
              '[TemplateBuilder] Cannot generate: SMS empty=${smsText.isEmpty}, Selections empty=${_selections.isEmpty}',
            );
            HapticFeedback.heavyImpact();
            ErrorSnackbar.show(
              context,
              'template_generation_error'.tr(
                args: ['SMS text or selections are empty'],
              ),
            );
            return;
          }
        }
      }

      setState(() {
        _currentStep = nextStep;
      });

      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
        // Clear generated pattern when going back to step 2 (select parts)
        // so it regenerates if user changes selections
        if (_currentStep == 1) {
          _generatedPattern = null;
          _generatedExtractionRules = null;
          _previewData = null;
          Log.debug(
            '[TemplateBuilder] Went back to step 2, cleared generated pattern',
          );
        }
      });
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  bool _canProceedToStep2() {
    return _smsController.text.trim().isNotEmpty;
  }

  bool _canProceedToStep3() {
    // Check that required fields are selected
    final hasStoreName = _selections.any((s) => s.label == 'store_name');
    final hasAmount = _selections.any((s) => s.label == 'amount');
    return hasStoreName && hasAmount && _selections.isNotEmpty;
  }

  Future<void> _generatePattern() async {
    Log.debug('[TemplateBuilder] _generatePattern() called');

    // Set generating flag to true
    if (mounted) {
      setState(() {
        _isGenerating = true;
      });
    }

    final smsText = _smsController.text.trim();
    Log.debug(
      '[TemplateBuilder] SMS text: "${smsText.substring(0, smsText.length > 50 ? 50 : smsText.length)}..."',
    );
    Log.debug('[TemplateBuilder] Selections: ${_selections.length}');
    for (var i = 0; i < _selections.length; i++) {
      final s = _selections[i];
      Log.debug(
        '[TemplateBuilder]   Selection $i: label=${s.label}, start=${s.start}, end=${s.end}, group=${s.captureGroup}',
      );
    }

    if (smsText.isEmpty || _selections.isEmpty) {
      Log.warning(
        '[TemplateBuilder] Cannot generate - SMS empty=${smsText.isEmpty}, Selections empty=${_selections.isEmpty}',
      );
      // Reset generating flag
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
      }

      // Show error if trying to generate without required data
      if (mounted && context.mounted) {
        HapticFeedback.heavyImpact();
        ErrorSnackbar.show(
          context,
          'template_generation_error'.tr(
            args: ['SMS text or selections are empty'],
          ),
        );
      }
      return;
    }

    try {
      Log.debug(
        '[TemplateBuilder] Calling SmsPatternGenerator.generatePattern...',
      );
      final result = SmsPatternGenerator.generatePattern(smsText, _selections);
      Log.debug(
        '[TemplateBuilder] Pattern generated: "${result.pattern.substring(0, result.pattern.length > 100 ? 100 : result.pattern.length)}..."',
      );
      Log.debug('[TemplateBuilder] Pattern length: ${result.pattern.length}');
      Log.debug(
        '[TemplateBuilder] Extraction rules: ${result.extractionRules.substring(0, result.extractionRules.length > 100 ? 100 : result.extractionRules.length)}...',
      );

      // Validate that pattern was actually generated
      if (result.pattern.isEmpty) {
        throw Exception('Generated pattern is empty');
      }

      // Test the generated pattern
      Log.debug('[TemplateBuilder] Testing pattern...');
      final previewData = SmsParsingService.testPattern(
        smsText,
        result.pattern,
        result.extractionRules,
      );
      Log.debug(
        '[TemplateBuilder] Preview data: ${previewData != null ? "Generated" : "null"}',
      );

      // Update state with both pattern and preview data
      if (mounted) {
        Log.debug(
          '[TemplateBuilder] Updating state with pattern and extraction rules...',
        );
        setState(() {
          _generatedPattern = result.pattern;
          _generatedExtractionRules = result.extractionRules;
          _previewData = previewData;
          _isGenerating = false; // Generation complete
        });
        Log.info(
          '[TemplateBuilder] State updated. Pattern generated successfully (${_generatedPattern!.length} chars)',
        );

        // After pattern is generated, proceed to step 3
        if (_currentStep == 1) {
          // Use a small delay to ensure state is updated
          await Future.delayed(const Duration(milliseconds: 100));
          if (mounted) {
            setState(() {
              _currentStep = 2;
            });
            if (_pageController.hasClients) {
              _pageController.nextPage(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            }
          }
        }
      } else {
        Log.warning(
          '[TemplateBuilder] Widget not mounted, cannot update state',
        );
      }
    } catch (e, stackTrace) {
      // Log the error for debugging
      Log.error(
        '[TemplateBuilder] Pattern generation failed',
        error: e,
        stackTrace: stackTrace,
      );

      // Reset generating flag on error
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
      }

      if (!mounted || !context.mounted) {
        Log.warning('[TemplateBuilder] Widget not mounted, cannot show error');
        return;
      }
      HapticFeedback.heavyImpact();
      ErrorSnackbar.show(
        context,
        'template_generation_error'.tr(args: [e.toString()]),
      );
    }
  }

  void _onSelectionsChanged(List<SmsTextSelection> selections) {
    setState(() {
      _selections = selections;
      // Clear generated pattern when selections change, so it regenerates
      // when user clicks next again
      if (_generatedPattern != null) {
        _generatedPattern = null;
        _generatedExtractionRules = null;
        _previewData = null;
        Log.debug(
          '[TemplateBuilder] Selections changed, cleared generated pattern',
        );
      }
    });
  }

  void _returnToForm() {
    if (_generatedPattern != null && _generatedExtractionRules != null) {
      Log.info(
        '[TemplateBuilder] Returning pattern to form: ${_generatedPattern!.length} chars',
      );
      Log.debug(
        '[TemplateBuilder] Pattern: ${_generatedPattern!.substring(0, _generatedPattern!.length > 50 ? 50 : _generatedPattern!.length)}...',
      );
      Log.debug(
        '[TemplateBuilder] Extraction rules length: ${_generatedExtractionRules!.length}',
      );
      context.pop(
        TemplateBuilderResult(
          pattern: _generatedPattern!,
          extractionRules: _generatedExtractionRules!,
        ),
      );
    } else {
      Log.warning(
        '[TemplateBuilder] Cannot return: pattern=${_generatedPattern != null}, rules=${_generatedExtractionRules != null}',
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _currentStep == 0,
      onPopInvokedWithResult: (bool didPop, dynamic result) async {
        if (!didPop && _currentStep > 0) {
          // Show confirmation dialog if user tries to exit during wizard
          final shouldPop = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('exit_wizard'.tr()),
              content: Text('exit_wizard_confirmation'.tr()),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text('cancel'.tr()),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(true);
                    if (context.mounted) {
                      context.pop();
                    }
                  },
                  child: Text('exit'.tr()),
                ),
              ],
            ),
          );
          if (shouldPop == true && context.mounted) {
            context.pop();
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('visual_template_builder'.tr()),
          leading: IconButton(
            icon: const Icon(Icons.close),
            tooltip: 'close'.tr(),
            onPressed: () async {
              HapticFeedback.lightImpact();
              // Show confirmation if in progress
              if (_currentStep > 0) {
                final shouldPop = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text('exit_wizard'.tr()),
                    content: Text('exit_wizard_confirmation'.tr()),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: Text('cancel'.tr()),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: Text('exit'.tr()),
                      ),
                    ],
                  ),
                );
                if (shouldPop == true && context.mounted) {
                  context.pop();
                }
              } else {
                context.pop();
              }
            },
          ),
        ),
        body: Column(
          children: [
            // Step indicator
            _buildStepIndicator(),
            // Content
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildStep1(),
                  _buildStep2(),
                  _buildStep3(),
                  _buildStep4(),
                ],
              ),
            ),
            // Navigation buttons
            _buildNavigationButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          _buildStepIndicatorItem(0, 'sms_input'.tr()),
          _buildStepIndicatorItem(1, 'select_parts'.tr()),
          _buildStepIndicatorItem(2, 'review'.tr()),
          _buildStepIndicatorItem(3, 'complete'.tr()),
        ],
      ),
    );
  }

  Widget _buildStepIndicatorItem(int step, String label) {
    final isActive = step == _currentStep;
    final isCompleted = step < _currentStep;
    return Expanded(
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isActive
                      ? Theme.of(context).colorScheme.primary
                      : isCompleted
                      ? Theme.of(context).colorScheme.primaryContainer
                      : Theme.of(context).colorScheme.surfaceContainerHighest,
                ),
                child: Center(
                  child: isCompleted
                      ? Icon(
                          Icons.check,
                          size: 20,
                          color: Theme.of(
                            context,
                          ).colorScheme.onPrimaryContainer,
                        )
                      : Text(
                          '${step + 1}',
                          style: TextStyle(
                            color: isActive
                                ? Theme.of(context).colorScheme.onPrimary
                                : Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              if (step < 3)
                Expanded(
                  child: Container(
                    height: 2,
                    color: isCompleted
                        ? Theme.of(context).colorScheme.primaryContainer
                        : Theme.of(context).colorScheme.surfaceContainerHighest,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isActive
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep1() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'step_1_enter_sms'.tr(),
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'step_1_description'.tr(),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _smsController,
              decoration: InputDecoration(
                labelText: 'sms_message'.tr(),
                hintText: 'paste_sms_message'.tr(),
                border: const OutlineInputBorder(),
                helperText: 'step_1_helper'.tr(),
              ),
              maxLines: 8,
              keyboardType: TextInputType.multiline,
              textInputAction: TextInputAction.newline,
              onChanged: (_) => setState(() {}),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep2() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'step_2_select_parts'.tr(),
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 24),
          Expanded(
            child: SmsTextSelector(
              text: _smsController.text.trim(),
              selections: _selections,
              onSelectionsChanged: _onSelectionsChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep3() {
    Log.debug(
      '[TemplateBuilder] _buildStep3() called. Pattern is: ${_generatedPattern != null ? "SET (${_generatedPattern!.length} chars)" : "NULL"}',
    );
    // Pattern should already be generated in _nextStep() before reaching this step
    // If it's null here, it means something went wrong - show error state

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'step_3_review'.tr(),
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'step_3_description'.tr(),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Scrollbar(
              controller: _step3ScrollController,
              thumbVisibility: true,
              child: SingleChildScrollView(
                controller: _step3ScrollController,
                primary: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_generatedPattern != null &&
                        _generatedPattern!.isNotEmpty) ...[
                      // Selected fields summary
                      Text(
                        'selected_fields_summary'.tr(),
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _selections.map((selection) {
                          final displayNames = {
                            'store_name': 'label_store_name'.tr(),
                            'amount': 'label_amount'.tr(),
                            'currency': 'label_currency'.tr(),
                            'card_last4': 'label_card_last4'.tr(),
                            'intention': 'label_intention'.tr(),
                            'date': 'label_date'.tr(),
                            'purchase_source': 'label_purchase_source'.tr(),
                          };
                          final color =
                              {
                                'store_name': const Color(0xFFFF9800),
                                'amount': const Color(0xFF9C27B0),
                                'currency': const Color(0xFF2196F3),
                                'card_last4': const Color(0xFFF44336),
                                'intention': const Color(0xFF4CAF50),
                                'date': const Color(0xFFFFC107),
                                'purchase_source': const Color(0xFF00BCD4),
                              }[selection.label] ??
                              Theme.of(context).colorScheme.primary;
                          return Chip(
                            label: Text(
                              displayNames[selection.label] ?? selection.label,
                            ),
                            backgroundColor: color.withValues(alpha: 0.2),
                            side: BorderSide(color: color, width: 2),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),
                      // Pattern explanation
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.primaryContainer.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: Theme.of(
                                context,
                              ).colorScheme.onPrimaryContainer,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'pattern_explanation'.tr(),
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onPrimaryContainer,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'generated_pattern_label'.tr(),
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Theme.of(
                              context,
                            ).colorScheme.outline.withValues(alpha: 0.3),
                          ),
                        ),
                        child: SelectableText(
                          _generatedPattern!,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 13,
                            color: Theme.of(context).colorScheme.onSurface,
                            height: 1.4,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Extraction rules in a more readable format
                      Text(
                        'generated_extraction_rules'.tr(),
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Theme.of(
                              context,
                            ).colorScheme.outline.withValues(alpha: 0.3),
                          ),
                        ),
                        child: SelectableText(
                          _generatedExtractionRules ?? '',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 13,
                            color: Theme.of(context).colorScheme.onSurface,
                            height: 1.4,
                          ),
                        ),
                      ),
                      if (_previewData != null) ...[
                        const SizedBox(height: 24),
                        Text(
                          'preview'.tr(),
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          key: ValueKey(
                            'preview_${_generatedPattern}_${_selections.length}',
                          ),
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildPreviewRow(
                                'store'.tr(),
                                _previewData!.storeName,
                              ),
                              _buildPreviewRow(
                                'amount'.tr(),
                                _previewData!.amount != null
                                    ? '${_previewData!.amount!.toStringAsFixed(2)} ${_previewData!.currency ?? 'USD'}'
                                    : null,
                              ),
                              if (_previewData!.cardLast4Digits != null)
                                _buildPreviewRow(
                                  'card'.tr(),
                                  _previewData!.cardLast4Digits,
                                ),
                            ],
                          ),
                        ),
                      ] else if (_generatedPattern != null &&
                          _generatedPattern!.isNotEmpty) ...[
                        // Show message if pattern exists but preview couldn't be generated
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.errorContainer.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.warning,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onErrorContainer,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'preview_not_available'.tr(),
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onErrorContainer,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ] else
                      const Center(child: CircularProgressIndicator()),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(child: Text(value ?? 'N/A')),
        ],
      ),
    );
  }

  Widget _buildStep4() {
    // Get list of extracted fields
    final extractedFields = _selections
        .map((s) {
          final displayNames = {
            'store_name': 'label_store_name'.tr(),
            'amount': 'label_amount'.tr(),
            'currency': 'label_currency'.tr(),
            'card_last4': 'label_card_last4'.tr(),
            'intention': 'label_intention'.tr(),
            'date': 'label_date'.tr(),
            'purchase_source': 'label_purchase_source'.tr(),
          };
          return displayNames[s.label] ?? s.label;
        })
        .join(', ');

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle,
            size: 64,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 24),
          Text(
            'template_generated_successfully'.tr(),
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'pattern_ready_to_save'.tr(),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.primaryContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'fields_extracted'.tr(args: [extractedFields]),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ],
                ),
                if (_generatedPattern != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    'pattern_length_info'.tr(
                      args: ['${_generatedPattern!.length}'],
                    ),
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
          Container(
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
                  Icons.arrow_back,
                  color: Theme.of(context).colorScheme.primary,
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
        ],
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (_currentStep > 0)
            TextButton.icon(
              onPressed: () {
                HapticFeedback.lightImpact();
                _previousStep();
              },
              icon: const Icon(Icons.arrow_back),
              label: Text('previous'.tr()),
            )
          else
            const SizedBox.shrink(),
          if (_currentStep < 3)
            Builder(
              builder: (context) {
                final canProceed = _currentStep == 0
                    ? _canProceedToStep2()
                    : _currentStep == 1
                    ? _canProceedToStep3()
                    : true;
                final isGenerating = _isGenerating;

                return Tooltip(
                  message: _currentStep == 1 && !canProceed
                      ? 'required_fields_missing'.tr()
                      : '',
                  child: ElevatedButton.icon(
                    onPressed: canProceed && !isGenerating
                        ? () async {
                            HapticFeedback.lightImpact();
                            if (_currentStep == 0 && _canProceedToStep2()) {
                              await _nextStep();
                            } else if (_currentStep == 1 &&
                                _canProceedToStep3()) {
                              await _nextStep();
                            } else if (_currentStep == 2) {
                              await _nextStep();
                            }
                          }
                        : null,
                    icon: isGenerating
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.arrow_forward),
                    label: Text(isGenerating ? 'generating'.tr() : 'next'.tr()),
                  ),
                );
              },
            )
          else
            ElevatedButton.icon(
              onPressed: () {
                HapticFeedback.heavyImpact();
                _returnToForm();
              },
              icon: const Icon(Icons.check),
              label: Text('use_this_template'.tr()),
            ),
        ],
      ),
    );
  }
}
