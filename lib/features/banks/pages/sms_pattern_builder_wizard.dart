import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import '../widgets/sms_text_selector.dart';
import '../../../core/services/sms_pattern_generator.dart';
import '../../../core/services/sms_parsing_service.dart';
import '../../../core/widgets/error_snackbar.dart';

/// Result returned from the wizard
class PatternBuilderResult {
  final String pattern;
  final String extractionRules;

  PatternBuilderResult({required this.pattern, required this.extractionRules});
}

/// Visual SMS Pattern Builder Wizard
/// Allows users to visually build SMS patterns by selecting and labeling parts
class SmsPatternBuilderWizard extends ConsumerStatefulWidget {
  final String? initialSms;
  final int? bankId;

  const SmsPatternBuilderWizard({super.key, this.initialSms, this.bankId});

  @override
  ConsumerState<SmsPatternBuilderWizard> createState() =>
      _SmsPatternBuilderWizardState();
}

class _SmsPatternBuilderWizardState
    extends ConsumerState<SmsPatternBuilderWizard> {
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

  @override
  void initState() {
    super.initState();
    if (widget.initialSms != null) {
      _smsController.text = widget.initialSms!;
    }
  }

  @override
  void dispose() {
    _smsController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < 3) {
      setState(() {
        _currentStep++;
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

  void _generatePattern() {
    final smsText = _smsController.text.trim();
    if (smsText.isEmpty || _selections.isEmpty) return;

    try {
      final result = SmsPatternGenerator.generatePattern(smsText, _selections);
      setState(() {
        _generatedPattern = result.pattern;
        _generatedExtractionRules = result.extractionRules;
      });

      // Test the generated pattern
      _previewData = SmsParsingService.testPattern(
        smsText,
        _generatedPattern!,
        _generatedExtractionRules!,
      );
    } catch (e) {
      if (!mounted || !context.mounted) return;
      HapticFeedback.heavyImpact();
      ErrorSnackbar.show(
        context,
        'pattern_generation_error'.tr(args: [e.toString()]),
      );
    }
  }

  void _onSelectionsChanged(List<SmsTextSelection> selections) {
    setState(() {
      _selections = selections;
    });
  }

  void _returnToForm() {
    if (_generatedPattern != null && _generatedExtractionRules != null) {
      context.pop(
        PatternBuilderResult(
          pattern: _generatedPattern!,
          extractionRules: _generatedExtractionRules!,
        ),
      );
    } else {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('visual_pattern_builder'.tr()),
        leading: IconButton(
          icon: const Icon(Icons.close),
          tooltip: 'close'.tr(),
          onPressed: () {
            HapticFeedback.lightImpact();
            context.pop();
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
                                : Theme.of(context).colorScheme.onSurfaceVariant,
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
          const SizedBox(height: 8),
          Text(
            'step_2_description'.tr(),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
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
    // Generate pattern when entering step 3
    if (_generatedPattern == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _generatePattern();
      });
    }

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
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_generatedPattern != null) ...[
                    Text(
                      'generated_pattern_label'.tr(),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                        ),
                      ),
                      child: SelectableText(
                        _generatedPattern!,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'generated_extraction_rules'.tr(),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                        ),
                      ),
                      child: SelectableText(
                        _generatedExtractionRules ?? '',
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
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
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildPreviewRow('store'.tr(), _previewData!.storeName),
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
                    ],
                  ] else
                    const Center(child: CircularProgressIndicator()),
                ],
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
            'pattern_generated_successfully'.tr(),
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          Text(
            'pattern_generated_description'.tr(),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
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
            ElevatedButton.icon(
              onPressed: () {
                HapticFeedback.lightImpact();
                if (_currentStep == 0 && _canProceedToStep2()) {
                  _nextStep();
                } else if (_currentStep == 1 && _canProceedToStep3()) {
                  _nextStep();
                } else if (_currentStep == 2) {
                  _nextStep();
                }
              },
              icon: const Icon(Icons.arrow_forward),
              label: Text('next'.tr()),
            )
          else
            ElevatedButton.icon(
              onPressed: () {
                HapticFeedback.heavyImpact();
                _returnToForm();
              },
              icon: const Icon(Icons.check),
              label: Text('use_this_pattern'.tr()),
            ),
        ],
      ),
    );
  }
}
