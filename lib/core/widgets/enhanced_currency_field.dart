import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Enhanced currency input field with real-time validation and animations
class EnhancedCurrencyField extends StatefulWidget {
  final TextEditingController? controller;
  final String? labelText;
  final String? hintText;
  final String currencyCode;
  final double? initialValue;
  final ValueChanged<double?>? onChanged;
  final String? Function(double?)? validator;
  final bool enabled;
  final String? semanticLabel;

  const EnhancedCurrencyField({
    super.key,
    this.controller,
    this.labelText,
    this.hintText,
    this.currencyCode = 'USD',
    this.initialValue,
    this.onChanged,
    this.validator,
    this.enabled = true,
    this.semanticLabel,
  });

  @override
  State<EnhancedCurrencyField> createState() => _EnhancedCurrencyFieldState();
}

class _EnhancedCurrencyFieldState extends State<EnhancedCurrencyField>
    with SingleTickerProviderStateMixin {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  bool _isFocused = false;
  bool _hasError = false;
  String? _errorText;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ??
        TextEditingController(
          text: widget.initialValue?.toStringAsFixed(2) ?? '',
        );
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    _focusNode.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
    if (_isFocused) {
      _animationController.forward();
      HapticFeedback.selectionClick();
    } else {
      _animationController.reverse();
      _validate();
    }
  }

  void _validate() {
    final value = _controller.text;
    double? amount;
    if (value.isNotEmpty) {
      amount = double.tryParse(value.replaceAll(',', ''));
    }

    String? error;
    if (widget.validator != null) {
      error = widget.validator!(amount);
    } else if (value.isNotEmpty && amount == null) {
      error = 'Please enter a valid number';
    } else if (amount != null && amount < 0) {
      error = 'Amount cannot be negative';
    }

    setState(() {
      _hasError = error != null;
      _errorText = error;
    });
  }

  void _onChanged(String value) {
    double? amount;
    if (value.isNotEmpty) {
      amount = double.tryParse(value.replaceAll(',', ''));
    }

    String? error;
    if (widget.validator != null) {
      error = widget.validator!(amount);
    } else if (value.isNotEmpty && amount == null) {
      error = 'Please enter a valid number';
    } else if (amount != null && amount <= 0) {
      error = 'Amount must be greater than 0';
    }

    setState(() {
      _hasError = error != null;
      _errorText = error;
    });

    widget.onChanged?.call(amount);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Semantics(
      label: widget.semanticLabel ?? widget.labelText ?? 'Amount',
      hint: widget.hintText ?? 'Enter amount',
      textField: true,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: TextFormField(
              controller: _controller,
              focusNode: _focusNode,
              enabled: widget.enabled,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textInputAction: TextInputAction.next,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              onChanged: _onChanged,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Amount is required';
                }
                final amount = double.tryParse(value.replaceAll(',', ''));
                if (amount == null) {
                  return 'Please enter a valid number';
                }
                if (amount <= 0) {
                  return 'Amount must be greater than 0';
                }
                return widget.validator?.call(amount);
              },
              decoration: InputDecoration(
                labelText: widget.labelText ?? 'Amount',
                hintText: widget.hintText ?? '0.00',
                prefixText: '${widget.currencyCode} ',
                errorText: _errorText,
                errorMaxLines: 2,
                suffixIcon: _controller.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _controller.clear();
                          _onChanged('');
                          HapticFeedback.lightImpact();
                        },
                        tooltip: 'Clear',
                      )
                    : _hasError && _errorText != null
                        ? Icon(
                            Icons.error_outline,
                            color: colorScheme.error,
                          )
                        : _isFocused
                            ? Icon(
                                Icons.check_circle_outline,
                                color: colorScheme.primary,
                                size: 20,
                              )
                            : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: _hasError
                        ? colorScheme.error
                        : colorScheme.outline.withValues(alpha: 0.5),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: _hasError ? colorScheme.error : colorScheme.primary,
                    width: 2,
                  ),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: colorScheme.error,
                    width: 2,
                  ),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: colorScheme.error,
                    width: 2,
                  ),
                ),
                filled: true,
                fillColor: _isFocused
                    ? colorScheme.primaryContainer.withValues(alpha: 0.1)
                    : colorScheme.surface,
              ),
            ),
          );
        },
      ),
    );
  }
}
