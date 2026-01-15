import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:drift/drift.dart' as drift;
import 'package:easy_localization/easy_localization.dart';
import '../../../core/database/app_database.dart' as db;
import '../../../core/database/providers/dao_providers.dart';
import '../../../core/widgets/enhanced_text_form_field.dart';
import '../../../core/widgets/enhanced_currency_field.dart';
import '../../../core/widgets/enhanced_date_picker_field.dart';
import '../../../core/widgets/card_selector.dart';
import '../../../core/widgets/category_selector.dart';
import '../../../core/widgets/error_snackbar.dart';
import '../../../core/widgets/loading_button.dart';
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
  bool _isSaving = false;

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
    final formState = _formKey.currentState;
    if (formState == null || !formState.validate()) {
      HapticFeedback.mediumImpact();
      return;
    }

    final amount = _amount;
    if (amount == null || amount <= 0) {
      ErrorSnackbar.show(context, 'amount_required'.tr());
      HapticFeedback.mediumImpact();
      return;
    }

    final date = _date;
    if (date == null) {
      ErrorSnackbar.show(context, 'date_required'.tr());
      HapticFeedback.mediumImpact();
      return;
    }

    if (!mounted) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final dao = ref.read(transactionDaoProvider);
      final existingTransaction = widget.transaction;

      final transactionCompanion = db.TransactionsCompanion(
        storeName: drift.Value(_storeNameController.text.trim()),
        amount: drift.Value(amount),
        currencyCode: drift.Value(_currencyCode),
        date: drift.Value(date),
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
      );

      if (existingTransaction == null) {
        // Create new transaction
        await dao.insertTransaction(transactionCompanion);
        if (!mounted || !context.mounted) return;
        HapticFeedback.heavyImpact();
        ErrorSnackbar.showSuccess(context, 'transaction_created'.tr());
        context.pop();
      } else {
        // Update existing transaction
        await dao.updateTransaction(
          db.TransactionsCompanion(
            id: drift.Value(existingTransaction.id),
            storeName: drift.Value(_storeNameController.text.trim()),
            amount: drift.Value(amount),
            currencyCode: drift.Value(_currencyCode),
            date: drift.Value(date),
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
        if (!mounted || !context.mounted) return;
        HapticFeedback.heavyImpact();
        ErrorSnackbar.showSuccess(context, 'transaction_updated'.tr());
        context.pop();
      }
    } catch (e) {
      if (!mounted || !context.mounted) return;
      HapticFeedback.heavyImpact();
      ErrorSnackbar.show(context, 'transaction_save_failed'.tr());
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
    final currencies = CurrencyService.getSupportedCurrencies();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.transaction == null
              ? 'new_transaction'.tr()
              : 'edit_transaction'.tr(),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            EnhancedTextFormField(
              controller: _storeNameController,
              labelText: 'store_name'.tr(),
              hintText: 'enter_store_name'.tr(),
              textInputAction: TextInputAction.next,
              maxLength: 200,
              showCharacterCount: true,
              semanticLabel: 'store_name'.tr(),
              inputFormatters: [
                FilteringTextInputFormatter.allow(
                  RegExp(r'[a-zA-Z0-9\s\-_.,()&@#]+'),
                ),
              ],
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'store_name_required'.tr();
                }
                if (value.trim().length > 200) {
                  return 'store_name_too_long'.tr();
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: EnhancedCurrencyField(
                    initialValue: _amount,
                    currencyCode: _currencyCode,
                    labelText: 'amount'.tr(),
                    hintText: '0.00',
                    semanticLabel: 'amount'.tr(),
                    onChanged: (amount) {
                      setState(() {
                        _amount = amount;
                      });
                    },
                    validator: (amount) {
                      if (amount == null) {
                        return 'amount_required'.tr();
                      }
                      if (amount <= 0) {
                        return 'amount_positive'.tr();
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _currencyCode,
                    decoration: InputDecoration(
                      labelText: 'currency'.tr(),
                      border: const OutlineInputBorder(),
                    ),
                    items: currencies.map((currency) {
                      return DropdownMenuItem<String>(
                        value: currency.code,
                        child: Text(currency.code),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null && mounted) {
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
            EnhancedDatePickerField(
              labelText: 'date'.tr(),
              hintText: 'select_date'.tr(),
              initialDate: _date,
              semanticLabel: 'date'.tr(),
              onDateSelected: (date) {
                if (mounted) {
                  setState(() {
                    _date = date;
                  });
                }
              },
              validator: (date) {
                if (date == null) {
                  return 'date_required'.tr();
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            CardSelector(
              selectedCardId: _cardId,
              onCardSelected: (cardId) {
                if (mounted) {
                  setState(() {
                    _cardId = cardId;
                  });
                }
              },
            ),
            const SizedBox(height: 24),
            CategorySelector(
              selectedCategoryId: _categoryId,
              onCategorySelected: (categoryId) {
                if (mounted) {
                  setState(() {
                    _categoryId = categoryId;
                  });
                }
              },
            ),
            const SizedBox(height: 24),
            EnhancedTextFormField(
              controller: _notesController,
              labelText: 'notes_optional'.tr(),
              hintText: 'add_notes'.tr(),
              textInputAction: TextInputAction.done,
              maxLength: 500,
              maxLines: 3,
              showCharacterCount: true,
              semanticLabel: 'notes_optional'.tr(),
              keyboardType: TextInputType.multiline,
            ),
            const SizedBox(height: 32),
            LoadingButton(
              onPressed: _isSaving ? null : _save,
              text: widget.transaction == null
                  ? 'create_transaction'.tr()
                  : 'update_transaction'.tr(),
              icon: Icons.save,
              isLoading: _isSaving,
              semanticLabel: widget.transaction == null
                  ? 'create_transaction'.tr()
                  : 'update_transaction'.tr(),
            ),
          ],
        ),
      ),
    );
  }
}
