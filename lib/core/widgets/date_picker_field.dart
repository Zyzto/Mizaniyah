import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// A field for selecting dates with a date picker
class DatePickerField extends StatelessWidget {
  final String? label;
  final String? hint;
  final DateTime? initialDate;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final ValueChanged<DateTime>? onDateSelected;
  final String? Function(DateTime?)? validator;
  final bool enabled;

  const DatePickerField({
    super.key,
    this.label,
    this.hint,
    this.initialDate,
    this.firstDate,
    this.lastDate,
    this.onDateSelected,
    this.validator,
    this.enabled = true,
  });

  Future<void> _selectDate(BuildContext context) async {
    if (!enabled) return;

    final DateTime now = DateTime.now();
    final DateTime first = firstDate ?? DateTime(now.year - 10);
    final DateTime last = lastDate ?? DateTime(now.year + 1);

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate ?? now,
      firstDate: first,
      lastDate: last,
      helpText: label ?? 'Select date',
    );

    if (picked != null) {
      onDateSelected?.call(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy-MM-dd');
    final displayText = initialDate != null
        ? dateFormat.format(initialDate!)
        : (hint ?? 'Select date');

    return InkWell(
      onTap: enabled ? () => _selectDate(context) : null,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label ?? 'Date',
          hintText: hint ?? 'Select date',
          suffixIcon: const Icon(Icons.calendar_today),
          errorText: validator?.call(initialDate),
        ),
        child: Text(
          displayText,
          style: TextStyle(
            color: initialDate != null
                ? Theme.of(context).textTheme.bodyLarge?.color
                : Theme.of(context).hintColor,
          ),
        ),
      ),
    );
  }
}
