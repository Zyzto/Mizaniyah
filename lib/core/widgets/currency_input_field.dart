import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A text field for entering currency amounts with validation
class CurrencyInputField extends StatefulWidget {
  final String? label;
  final String? hint;
  final double? initialValue;
  final String currencyCode;
  final ValueChanged<double?>? onChanged;
  final String? Function(double?)? validator;
  final bool enabled;
  final TextEditingController? controller;

  const CurrencyInputField({
    super.key,
    this.label,
    this.hint,
    this.initialValue,
    this.currencyCode = 'USD',
    this.onChanged,
    this.validator,
    this.enabled = true,
    this.controller,
  });

  @override
  State<CurrencyInputField> createState() => _CurrencyInputFieldState();
}

class _CurrencyInputFieldState extends State<CurrencyInputField> {
  late TextEditingController _controller;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _controller =
        widget.controller ??
        TextEditingController(
          text: widget.initialValue?.toStringAsFixed(2) ?? '',
        );
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _validateAndNotify(String value) {
    double? amount;
    if (value.isNotEmpty) {
      amount = double.tryParse(value.replaceAll(',', ''));
      if (amount == null) {
        _errorText = 'Please enter a valid number';
      } else if (amount < 0) {
        _errorText = 'Amount cannot be negative';
      } else {
        _errorText = null;
      }
    } else {
      _errorText = null;
    }

    if (widget.validator != null) {
      _errorText = widget.validator!(amount);
    }

    setState(() {});
    widget.onChanged?.call(amount);
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: _controller,
      enabled: widget.enabled,
      decoration: InputDecoration(
        labelText: widget.label ?? 'Amount',
        hintText: widget.hint ?? '0.00',
        prefixText: '${widget.currencyCode} ',
        errorText: _errorText,
        suffixIcon: _controller.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _controller.clear();
                  _validateAndNotify('');
                },
              )
            : null,
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
      ],
      onChanged: _validateAndNotify,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Amount is required';
        }
        final amount = double.tryParse(value.replaceAll(',', ''));
        if (amount == null) {
          return 'Please enter a valid number';
        }
        if (amount < 0) {
          return 'Amount cannot be negative';
        }
        return widget.validator?.call(amount);
      },
    );
  }
}
