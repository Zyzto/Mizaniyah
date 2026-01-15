import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:drift/drift.dart' as drift;
import 'package:easy_localization/easy_localization.dart';
import '../../../core/database/app_database.dart' as db;
import '../../categories/providers/category_providers.dart';
import '../../../core/database/providers/dao_providers.dart';
import '../../../core/utils/category_translations.dart';
import '../../../core/widgets/error_snackbar.dart';
import '../../../core/widgets/enhanced_text_form_field.dart';
import '../../../core/widgets/enhanced_currency_field.dart';
import '../../../core/widgets/enhanced_date_picker_field.dart';
import '../../../core/widgets/loading_button.dart';

class BudgetFormPage extends ConsumerStatefulWidget {
  final db.Budget? budget;

  const BudgetFormPage({super.key, this.budget});

  @override
  ConsumerState<BudgetFormPage> createState() => _BudgetFormPageState();
}

class _BudgetFormPageState extends ConsumerState<BudgetFormPage> {
  final _formKey = GlobalKey<FormState>();
  int? _selectedCategoryId;
  double? _amount;
  bool _rolloverEnabled = false;
  double _rolloverPercentage = 100.0;
  DateTime? _startDate;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.budget != null) {
      _selectedCategoryId = widget.budget!.categoryId;
      _amount = widget.budget!.amount;
      _rolloverEnabled = widget.budget!.rolloverEnabled;
      _rolloverPercentage = widget.budget!.rolloverPercentage;
      _startDate = widget.budget!.startDate;
    } else {
      _startDate = DateTime.now();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categoriesAsync = ref.watch(activeCategoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.budget == null
              ? 'create_budget_title'.tr()
              : 'edit_budget_title'.tr(),
        ),
        actions: widget.budget != null
            ? [
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    _deleteBudget();
                  },
                  tooltip: 'delete'.tr(),
                  color: theme.colorScheme.error,
                ),
              ]
            : null,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Category selector
            categoriesAsync.when(
              data: (categories) {
                if (categories.isEmpty) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Text(
                            'no_categories_available'.tr(),
                            style: theme.textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 16),
                          FilledButton.icon(
                            onPressed: () {
                              HapticFeedback.lightImpact();
                              // Navigate to add category - would need category form page
                            },
                            icon: const Icon(Icons.add),
                            label: Text('add_category'.tr()),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return DropdownButtonFormField<int>(
                  initialValue: _selectedCategoryId,
                  decoration: InputDecoration(
                    labelText: 'select_category'.tr(),
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.category_outlined),
                  ),
                  items: categories.map((category) {
                    return DropdownMenuItem<int>(
                      value: category.id,
                      child: Text(
                        CategoryTranslations.getTranslatedName(category),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    HapticFeedback.selectionClick();
                    setState(() {
                      _selectedCategoryId = value;
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'category_required'.tr();
                    }
                    return null;
                  },
                );
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (_, _) => Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'error_loading_categories'.tr(),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Amount
            EnhancedCurrencyField(
              initialValue: _amount,
              currencyCode: 'USD', // TODO: Get from user settings
              labelText: 'budget_amount'.tr(),
              hintText: '0.00',
              semanticLabel: 'budget_amount'.tr(),
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
            const SizedBox(height: 24),
            // Period (fixed to monthly for now)
            Text(
              '${'period'.tr()}: ${'monthly'.tr()}',
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            // Start date
            EnhancedDatePickerField(
              labelText: 'start_date'.tr(),
              hintText: 'select_date'.tr(),
              initialDate: _startDate,
              semanticLabel: 'start_date'.tr(),
              onDateSelected: (date) {
                setState(() {
                  _startDate = date;
                });
              },
              validator: (date) {
                if (date == null) {
                  return 'date_required'.tr();
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            // Rollover enabled
            SwitchListTile(
              title: Text('enable_rollover'.tr()),
              subtitle: Text('rollover_description'.tr()),
              value: _rolloverEnabled,
              onChanged: (value) {
                HapticFeedback.lightImpact();
                setState(() {
                  _rolloverEnabled = value;
                });
              },
            ),
            // Rollover percentage
            if (_rolloverEnabled) ...[
              const SizedBox(height: 24),
              EnhancedTextFormField(
                labelText: 'rollover_percentage'.tr(),
                hintText: '100.0',
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                textInputAction: TextInputAction.next,
                semanticLabel: 'rollover_percentage'.tr(),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                ],
                validator: (value) {
                  if (_rolloverEnabled) {
                    if (value == null || value.isEmpty) {
                      return 'percentage_required'.tr();
                    }
                    final percentage = double.tryParse(value);
                    if (percentage == null ||
                        percentage < 0 ||
                        percentage > 100) {
                      return 'percentage_range'.tr();
                    }
                    _rolloverPercentage = percentage;
                  }
                  return null;
                },
                onChanged: (value) {
                  final percentage = double.tryParse(value);
                  if (percentage != null) {
                    setState(() {
                      _rolloverPercentage = percentage;
                    });
                  }
                },
              ),
            ],
            const SizedBox(height: 32),
            // Save button
            LoadingButton(
              onPressed: _isSaving ? null : _saveBudget,
              text: 'save_budget'.tr(),
              icon: Icons.save,
              isLoading: _isSaving,
              semanticLabel: 'save_budget'.tr(),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveBudget() async {
    final formState = _formKey.currentState;
    if (formState == null || !formState.validate()) {
      HapticFeedback.mediumImpact();
      return;
    }

    if (_selectedCategoryId == null) {
      ErrorSnackbar.show(context, 'category_required'.tr());
      HapticFeedback.mediumImpact();
      return;
    }

    if (_amount == null || _amount! <= 0) {
      ErrorSnackbar.show(context, 'amount_required'.tr());
      HapticFeedback.mediumImpact();
      return;
    }

    if (_startDate == null) {
      ErrorSnackbar.show(context, 'date_required'.tr());
      HapticFeedback.mediumImpact();
      return;
    }

    if (!mounted) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final dao = ref.read(budgetDaoProvider);
      final rolloverPercentage = _rolloverEnabled ? _rolloverPercentage : 100.0;

      if (widget.budget == null) {
        // Create new budget
        final budget = db.BudgetsCompanion(
          categoryId: drift.Value(_selectedCategoryId!),
          amount: drift.Value(_amount!),
          period: const drift.Value('monthly'),
          rolloverEnabled: drift.Value(_rolloverEnabled),
          rolloverPercentage: drift.Value(rolloverPercentage),
          startDate: drift.Value(_startDate!),
          isActive: const drift.Value(true),
        );

        await dao.insertBudget(budget);
        if (!mounted || !context.mounted) return;
        HapticFeedback.heavyImpact();
        ErrorSnackbar.showSuccess(context, 'budget_created'.tr());
        context.pop();
      } else {
        // Update existing budget
        final budget = db.BudgetsCompanion(
          id: drift.Value(widget.budget!.id),
          categoryId: drift.Value(_selectedCategoryId!),
          amount: drift.Value(_amount!),
          period: const drift.Value('monthly'),
          rolloverEnabled: drift.Value(_rolloverEnabled),
          rolloverPercentage: drift.Value(rolloverPercentage),
          startDate: drift.Value(_startDate!),
        );

        await dao.updateBudget(budget);
        if (!mounted || !context.mounted) return;
        HapticFeedback.heavyImpact();
        ErrorSnackbar.showSuccess(context, 'budget_updated'.tr());
        context.pop();
      }
    } catch (e) {
      if (!mounted || !context.mounted) return;
      HapticFeedback.heavyImpact();
      ErrorSnackbar.show(
        context,
        'budget_save_failed'.tr(args: [e.toString()]),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _deleteBudget() async {
    if (widget.budget == null) return;
    if (!mounted || !context.mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('delete_budget'.tr()),
        content: Text('delete_budget_confirmation'.tr()),
        actions: [
          TextButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.of(context).pop(false);
            },
            child: Text('cancel'.tr()),
          ),
          FilledButton(
            onPressed: () {
              HapticFeedback.mediumImpact();
              Navigator.of(context).pop(true);
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text('delete'.tr()),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final dao = ref.read(budgetDaoProvider);
      await dao.deleteBudget(widget.budget!.id);
      if (!mounted || !context.mounted) return;
      HapticFeedback.heavyImpact();
      ErrorSnackbar.showSuccess(context, 'budget_deleted'.tr());
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted || !context.mounted) return;
      HapticFeedback.heavyImpact();
      ErrorSnackbar.show(
        context,
        'budget_delete_failed'.tr(args: [e.toString()]),
      );
    }
  }
}
