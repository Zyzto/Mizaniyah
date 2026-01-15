import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import 'package:easy_localization/easy_localization.dart';
import 'dart:convert';
import '../../../core/database/app_database.dart' as db;
import '../../../core/database/providers/dao_providers.dart';
import '../../../core/widgets/enhanced_text_form_field.dart';
import '../../../core/widgets/enhanced_currency_field.dart';
import '../../../core/widgets/enhanced_date_picker_field.dart';
import '../../../core/widgets/card_selector.dart';
import '../../../core/widgets/category_selector.dart';
import '../../../core/widgets/error_snackbar.dart';
import '../../../core/widgets/loading_button.dart';
import '../../../core/services/sms_parsing_service.dart';

/// Dialog for editing SMS confirmation before approval
class EditConfirmationDialog extends ConsumerStatefulWidget {
  final db.PendingSmsConfirmation confirmation;

  const EditConfirmationDialog({super.key, required this.confirmation});

  @override
  ConsumerState<EditConfirmationDialog> createState() =>
      _EditConfirmationDialogState();
}

class _EditConfirmationDialogState
    extends ConsumerState<EditConfirmationDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _storeNameController;
  double? _amount;
  String _currencyCode = 'USD';
  DateTime? _date;
  int? _cardId;
  int? _categoryId;
  bool _isSaving = false;
  ParsedSmsData? _originalParsedData;

  @override
  void initState() {
    super.initState();
    _loadConfirmationData();
  }

  void _loadConfirmationData() {
    try {
      final parsedDataJson =
          jsonDecode(widget.confirmation.parsedData) as Map<String, dynamic>;

      // Load original parsed data
      _originalParsedData = ParsedSmsData.fromJson(parsedDataJson);

      // Initialize form fields from parsed data
      _storeNameController = TextEditingController(
        text: parsedDataJson['store_name'] as String? ?? '',
      );
      _amount = (parsedDataJson['amount'] as num?)?.toDouble();
      _currencyCode = parsedDataJson['currency'] as String? ?? 'USD';

      // Use extracted transaction date or SMS received date
      final transactionDateStr = parsedDataJson['transaction_date'] as String?;
      if (transactionDateStr != null) {
        _date = DateTime.tryParse(transactionDateStr);
      }
      _date ??= widget.confirmation.createdAt;

      // Try to find card by last 4 digits
      final cardLast4 = parsedDataJson['card_last4'] as String?;
      if (cardLast4 != null && cardLast4.length == 4) {
        // Will be resolved in build method
      }
    } catch (e) {
      // Fallback to basic data
      _storeNameController = TextEditingController();
      _amount = 0.0;
      _date = widget.confirmation.createdAt;
    }
  }

  @override
  void dispose() {
    _storeNameController.dispose();
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
      final pendingSmsDao = ref.read(pendingSmsConfirmationDaoProvider);

      // Create updated parsed data with edited values
      final updatedParsedData = ParsedSmsData(
        storeName: _storeNameController.text.trim(),
        amount: amount,
        currency: _currencyCode,
        cardLast4Digits: _originalParsedData?.cardLast4Digits,
        transactionDate: date,
        smsSender:
            _originalParsedData?.smsSender ?? widget.confirmation.smsSender,
        smsBody: _originalParsedData?.smsBody ?? widget.confirmation.smsBody,
      );

      // Update confirmation with edited data
      final updatedConfirmation = widget.confirmation.copyWith(
        parsedData: jsonEncode(updatedParsedData.toJson()),
      );

      await pendingSmsDao.updateConfirmation(
        db.PendingSmsConfirmationsCompanion(
          id: drift.Value(widget.confirmation.id),
          parsedData: drift.Value(updatedConfirmation.parsedData),
        ),
      );

      if (!mounted || !context.mounted) return;
      HapticFeedback.heavyImpact();
      ErrorSnackbar.showSuccess(context, 'confirmation_updated'.tr());
      Navigator.of(context).pop(updatedParsedData);
    } catch (e) {
      if (!mounted || !context.mounted) return;
      HapticFeedback.heavyImpact();
      ErrorSnackbar.show(
        context,
        'update_confirmation_failed'.tr(args: [e.toString()]),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _findCardByLast4() async {
    final cardLast4 = _originalParsedData?.cardLast4Digits;
    if (cardLast4 == null || cardLast4.length != 4) return;

    try {
      final cardDao = ref.read(cardDaoProvider);
      final card = await cardDao.getCardByLast4Digits(cardLast4);
      if (card != null && mounted) {
        setState(() {
          _cardId = card.id;
        });
      }
    } catch (e) {
      // Silently fail - card not found
    }
  }

  @override
  Widget build(BuildContext context) {
    // Try to find card by last 4 digits on first build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_cardId == null) {
        _findCardByLast4();
      }
    });

    final currencies = [
      'USD',
      'EUR',
      'GBP',
      'JPY',
      'AUD',
      'CAD',
      'CHF',
      'CNY',
      'INR',
      'SGD',
      'AED',
      'SAR',
      'EGP',
    ];

    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: Theme.of(
                      context,
                    ).colorScheme.outline.withValues(alpha: 0.2),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Text(
                    'edit_confirmation'.tr(),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            // Form
            Flexible(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  shrinkWrap: true,
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
                    EnhancedCurrencyField(
                      labelText: 'amount'.tr(),
                      hintText: 'enter_amount'.tr(),
                      initialValue: _amount,
                      currencyCode: _currencyCode,
                      semanticLabel: 'amount'.tr(),
                      onChanged: (amount) {
                        if (mounted) {
                          setState(() {
                            _amount = amount;
                          });
                        }
                      },
                      validator: (amount) {
                        if (amount == null || amount <= 0) {
                          return 'amount_required'.tr();
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    // Currency selector (simple dropdown for now)
                    DropdownButtonFormField<String>(
                      // ignore: deprecated_member_use
                      initialValue: _currencyCode,
                      decoration: InputDecoration(labelText: 'currency'.tr()),
                      items: currencies.map((currency) {
                        return DropdownMenuItem<String>(
                          value: currency,
                          child: Text(currency),
                        );
                      }).toList(),
                      onChanged: (currency) {
                        if (mounted && currency != null) {
                          setState(() {
                            _currencyCode = currency;
                          });
                        }
                      },
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
                  ],
                ),
              ),
            ),
            // Footer with buttons
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: Theme.of(
                      context,
                    ).colorScheme.outline.withValues(alpha: 0.2),
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isSaving
                        ? null
                        : () => Navigator.of(context).pop(),
                    child: Text('cancel'.tr()),
                  ),
                  const SizedBox(width: 8),
                  LoadingButton(
                    onPressed: _isSaving ? null : _save,
                    text: 'save'.tr(),
                    isLoading: _isSaving,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
