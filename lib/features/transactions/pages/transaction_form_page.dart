import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import '../providers/transaction_providers.dart';
import '../../../core/database/app_database.dart' as db;
import '../../../core/widgets/currency_input_field.dart';
import '../../../core/widgets/date_picker_field.dart';
import '../../../core/widgets/card_selector.dart';
import '../../../core/widgets/category_selector.dart';
import '../../../core/widgets/error_snackbar.dart';
import '../../../core/services/currency_service.dart';

class TransactionFormPage extends ConsumerStatefulWidget {
  final db.Transaction? transaction;

  const TransactionFormPage({super.key, this.transaction});

  @override
  ConsumerState<TransactionFormPage> createState() =>
      _TransactionFormPageState();
}

class _TransactionFormPageState extends ConsumerState<TransactionFormPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _storeNameController;
  late TextEditingController _notesController;
  double? _amount;
  String _currencyCode = 'USD';
  DateTime? _date;
  int? _cardId;
  int? _categoryId;

  @override
  void initState() {
    super.initState();
    _storeNameController = TextEditingController(
      text: widget.transaction?.storeName ?? '',
    );
    _notesController = TextEditingController(
      text: widget.transaction?.notes ?? '',
    );
    _amount = widget.transaction?.amount;
    _currencyCode = widget.transaction?.currencyCode ?? 'USD';
    _date = widget.transaction?.date ?? DateTime.now();
    _cardId = widget.transaction?.cardId;
    _categoryId = widget.transaction?.categoryId;
  }

  @override
  void dispose() {
    _storeNameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_amount == null) {
      ErrorSnackbar.show(context, 'Please enter an amount');
      return;
    }

    if (_date == null) {
      ErrorSnackbar.show(context, 'Please select a date');
      return;
    }

    try {
      final repository = ref.read(transactionRepositoryProvider);

      if (widget.transaction == null) {
        // Create new transaction
        await repository.createTransaction(
          db.TransactionsCompanion(
            storeName: drift.Value(_storeNameController.text.trim()),
            amount: drift.Value(_amount!),
            currencyCode: drift.Value(_currencyCode),
            date: drift.Value(_date!),
            cardId: _cardId != null
                ? drift.Value(_cardId!)
                : const drift.Value.absent(),
            categoryId: _categoryId != null
                ? drift.Value(_categoryId!)
                : const drift.Value.absent(),
            notes: _notesController.text.trim().isNotEmpty
                ? drift.Value(_notesController.text.trim())
                : const drift.Value.absent(),
            source: const drift.Value('manual'),
          ),
        );
        if (mounted) {
          ErrorSnackbar.showSuccess(context, 'Transaction created');
          Navigator.of(context).pop();
        }
      } else {
        // Update existing transaction
        await repository.updateTransaction(
          db.TransactionsCompanion(
            id: drift.Value(widget.transaction!.id),
            storeName: drift.Value(_storeNameController.text.trim()),
            amount: drift.Value(_amount!),
            currencyCode: drift.Value(_currencyCode),
            date: drift.Value(_date!),
            cardId: _cardId != null
                ? drift.Value(_cardId!)
                : const drift.Value.absent(),
            categoryId: _categoryId != null
                ? drift.Value(_categoryId!)
                : const drift.Value.absent(),
            notes: _notesController.text.trim().isNotEmpty
                ? drift.Value(_notesController.text.trim())
                : const drift.Value.absent(),
          ),
        );
        if (mounted) {
          ErrorSnackbar.showSuccess(context, 'Transaction updated');
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      if (mounted) {
        ErrorSnackbar.show(context, 'Failed to save transaction: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencies = CurrencyService.getSupportedCurrencies();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.transaction == null ? 'New Transaction' : 'Edit Transaction',
        ),
        actions: [IconButton(icon: const Icon(Icons.save), onPressed: _save)],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _storeNameController,
              decoration: const InputDecoration(
                labelText: 'Store Name',
                hintText: 'Enter store or merchant name',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Store name is required';
                }
                if (value.trim().length > 200) {
                  return 'Store name must be 200 characters or less';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: CurrencyInputField(
                    initialValue: _amount,
                    currencyCode: _currencyCode,
                    onChanged: (amount) {
                      setState(() {
                        _amount = amount;
                      });
                    },
                    validator: (amount) {
                      if (amount == null) {
                        return 'Amount is required';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _currencyCode,
                    decoration: const InputDecoration(labelText: 'Currency'),
                    items: currencies.map((currency) {
                      return DropdownMenuItem<String>(
                        value: currency.code,
                        child: Text(currency.code),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _currencyCode = value;
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            DatePickerField(
              label: 'Date',
              initialDate: _date,
              onDateSelected: (date) {
                setState(() {
                  _date = date;
                });
              },
              validator: (date) {
                if (date == null) {
                  return 'Date is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            CardSelector(
              selectedCardId: _cardId,
              onCardSelected: (cardId) {
                setState(() {
                  _cardId = cardId;
                });
              },
            ),
            const SizedBox(height: 24),
            CategorySelector(
              selectedCategoryId: _categoryId,
              onCategorySelected: (categoryId) {
                setState(() {
                  _categoryId = categoryId;
                });
              },
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (Optional)',
                hintText: 'Add any additional notes',
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }
}
