import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

/// Enhanced date picker field with animations and accessibility
class EnhancedDatePickerField extends StatefulWidget {
  final String? labelText;
  final String? hintText;
  final DateTime? initialDate;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final ValueChanged<DateTime>? onDateSelected;
  final String? Function(DateTime?)? validator;
  final bool enabled;
  final String? semanticLabel;

  const EnhancedDatePickerField({
    super.key,
    this.labelText,
    this.hintText,
    this.initialDate,
    this.firstDate,
    this.lastDate,
    this.onDateSelected,
    this.validator,
    this.enabled = true,
    this.semanticLabel,
  });

  @override
  State<EnhancedDatePickerField> createState() =>
      _EnhancedDatePickerFieldState();
}

class _EnhancedDatePickerFieldState extends State<EnhancedDatePickerField>
    with SingleTickerProviderStateMixin {
  DateTime? _selectedDate;
  bool _hasError = false;
  String? _errorText;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _validate();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _validate() {
    if (widget.validator != null) {
      final error = widget.validator!(_selectedDate);
      setState(() {
        _hasError = error != null;
        _errorText = error;
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    if (!widget.enabled) return;

    HapticFeedback.mediumImpact();
    _animationController.forward().then((_) {
      _animationController.reverse();
    });

    final DateTime now = DateTime.now();
    final DateTime first = widget.firstDate ?? DateTime(now.year - 10);
    final DateTime last = widget.lastDate ?? DateTime(now.year + 1);

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: first,
      lastDate: last,
      helpText: widget.labelText ?? 'Select date',
      builder: (context, child) {
        return Theme(
          data: Theme.of(
            context,
          ).copyWith(colorScheme: Theme.of(context).colorScheme),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _validate();
      widget.onDateSelected?.call(picked);
      HapticFeedback.selectionClick();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final dateFormat = DateFormat('yyyy-MM-dd');
    final displayText = _selectedDate != null
        ? dateFormat.format(_selectedDate!)
        : (widget.hintText ?? 'Select date');

    return Semantics(
      label: widget.semanticLabel ?? widget.labelText ?? 'Date',
      hint: widget.hintText ?? 'Tap to select date',
      button: true,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: InkWell(
              onTap: widget.enabled ? () => _selectDate(context) : null,
              borderRadius: BorderRadius.circular(12),
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: widget.labelText ?? 'Date',
                  hintText: widget.hintText ?? 'Select date',
                  suffixIcon: Icon(
                    Icons.calendar_today,
                    color: _hasError
                        ? colorScheme.error
                        : _selectedDate != null
                        ? colorScheme.primary
                        : colorScheme.onSurfaceVariant,
                  ),
                  errorText: _errorText,
                  errorMaxLines: 2,
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
                      color: _hasError
                          ? colorScheme.error
                          : colorScheme.primary,
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
                  fillColor: colorScheme.surface,
                ),
                child: Text(
                  displayText,
                  style: TextStyle(
                    color: _selectedDate != null
                        ? theme.textTheme.bodyLarge?.color
                        : theme.hintColor,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
