import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Enhanced text form field with real-time validation, animations, and accessibility
class EnhancedTextFormField extends StatefulWidget {
  final TextEditingController? controller;
  final String? labelText;
  final String? hintText;
  final String? helperText;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final int? maxLength;
  final int? maxLines;
  final bool enabled;
  final bool readOnly;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool autofocus;
  final FocusNode? focusNode;
  final String? semanticLabel;
  final bool showCharacterCount;

  const EnhancedTextFormField({
    super.key,
    this.controller,
    this.labelText,
    this.hintText,
    this.helperText,
    this.validator,
    this.onChanged,
    this.keyboardType,
    this.textInputAction,
    this.inputFormatters,
    this.maxLength,
    this.maxLines = 1,
    this.enabled = true,
    this.readOnly = false,
    this.prefixIcon,
    this.suffixIcon,
    this.autofocus = false,
    this.focusNode,
    this.semanticLabel,
    this.showCharacterCount = false,
  });

  @override
  State<EnhancedTextFormField> createState() => _EnhancedTextFormFieldState();
}

class _EnhancedTextFormFieldState extends State<EnhancedTextFormField>
    with SingleTickerProviderStateMixin {
  late FocusNode _focusNode;
  bool _isFocused = false;
  bool _hasError = false;
  String? _errorText;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_onFocusChange);
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    _animationController.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
    if (_isFocused) {
      _animationController.forward();
      // Haptic feedback on focus
      HapticFeedback.selectionClick();
    } else {
      _animationController.reverse();
      // Validate on blur
      _validate();
    }
  }

  void _validate() {
    if (widget.validator != null && widget.controller != null) {
      final error = widget.validator!(widget.controller!.text);
      setState(() {
        _hasError = error != null;
        _errorText = error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Semantics(
      label: widget.semanticLabel ?? widget.labelText,
      hint: widget.hintText,
      textField: true,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: TextFormField(
              controller: widget.controller,
              focusNode: _focusNode,
              keyboardType: widget.keyboardType,
              textInputAction: widget.textInputAction,
              inputFormatters: widget.inputFormatters,
              maxLength: widget.maxLength,
              maxLines: widget.maxLines,
              enabled: widget.enabled,
              readOnly: widget.readOnly,
              autofocus: widget.autofocus,
              onChanged: (value) {
                // Real-time validation
                if (widget.validator != null) {
                  final error = widget.validator!(value);
                  setState(() {
                    _hasError = error != null;
                    _errorText = error;
                  });
                }
                widget.onChanged?.call(value);
              },
              validator: (value) {
                final error = widget.validator?.call(value);
                setState(() {
                  _hasError = error != null;
                  _errorText = error;
                });
                return error;
              },
              decoration: InputDecoration(
                labelText: widget.labelText,
                hintText: widget.hintText,
                helperText: widget.helperText,
                prefixIcon: widget.prefixIcon,
                suffixIcon:
                    widget.suffixIcon ??
                    (_hasError && _errorText != null
                        ? Icon(Icons.error_outline, color: colorScheme.error)
                        : _isFocused
                        ? Icon(
                            Icons.check_circle_outline,
                            color: colorScheme.primary,
                            size: 20,
                          )
                        : null),
                errorText: _errorText,
                errorMaxLines: 2,
                counterText:
                    widget.showCharacterCount &&
                        widget.maxLength != null &&
                        widget.controller != null
                    ? '${widget.controller!.text.length}/${widget.maxLength}'
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
                  borderSide: BorderSide(color: colorScheme.error, width: 2),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colorScheme.error, width: 2),
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
