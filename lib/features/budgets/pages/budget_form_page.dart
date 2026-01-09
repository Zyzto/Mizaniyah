import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import '../../../core/database/app_database.dart' as db;
import '../providers/budget_providers.dart';
import '../../categories/providers/category_providers.dart';
import '../../../core/widgets/error_snackbar.dart';

class BudgetFormPage extends ConsumerStatefulWidget {
  final db.Budget? budget;

  const BudgetFormPage({super.key, this.budget});

  @override
  ConsumerState<BudgetFormPage> createState() => _BudgetFormPageState();
}

class _BudgetFormPageState extends ConsumerState<BudgetFormPage> {
  final _formKey = GlobalKey<FormState>();
  int? _selectedCategoryId;
  final _amountController = TextEditingController();
  bool _rolloverEnabled = false;
  final _rolloverPercentageController = TextEditingController(text: '100.0');
  DateTime _startDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    if (widget.budget != null) {
      _selectedCategoryId = widget.budget!.categoryId;
      _amountController.text = widget.budget!.amount.toString();
      _rolloverEnabled = widget.budget!.rolloverEnabled;
      _rolloverPercentageController.text = widget.budget!.rolloverPercentage
          .toString();
      _startDate = widget.budget!.startDate;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _rolloverPercentageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(activeCategoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.budget == null ? 'Create Budget' : 'Edit Budget'),
        actions: widget.budget != null
            ? [
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: _deleteBudget,
                  tooltip: 'Delete Budget',
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
                  return const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'No categories available. Please create a category first.',
                      ),
                    ),
                  );
                }

                return DropdownButtonFormField<int>(
                  value: _selectedCategoryId,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                  ),
                  items: categories.map((category) {
                    return DropdownMenuItem<int>(
                      value: category.id,
                      child: Text(category.name),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedCategoryId = value;
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Please select a category';
                    }
                    return null;
                  },
                );
              },
              loading: () => const CircularProgressIndicator(),
              error: (_, __) => const Text('Error loading categories'),
            ),
            const SizedBox(height: 16),
            // Amount
            TextFormField(
              controller: _amountController,
              decoration: const InputDecoration(
                labelText: 'Budget Amount',
                border: OutlineInputBorder(),
                prefixText: '\$ ',
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter an amount';
                }
                final amount = double.tryParse(value);
                if (amount == null || amount <= 0) {
                  return 'Please enter a valid amount';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            // Period (fixed to monthly for now)
            const Text('Period: Monthly'),
            const SizedBox(height: 16),
            // Start date
            ListTile(
              title: const Text('Start Date'),
              subtitle: Text(
                '${_startDate.year}/${_startDate.month.toString().padLeft(2, '0')}/${_startDate.day.toString().padLeft(2, '0')}',
              ),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _startDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2100),
                );
                if (date != null) {
                  setState(() {
                    _startDate = date;
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            // Rollover enabled
            SwitchListTile(
              title: const Text('Enable Rollover'),
              subtitle: const Text('Carry over unused budget to next period'),
              value: _rolloverEnabled,
              onChanged: (value) {
                setState(() {
                  _rolloverEnabled = value;
                });
              },
            ),
            // Rollover percentage
            if (_rolloverEnabled) ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: _rolloverPercentageController,
                decoration: const InputDecoration(
                  labelText: 'Rollover Percentage',
                  border: OutlineInputBorder(),
                  suffixText: '%',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (value) {
                  if (_rolloverEnabled) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a percentage';
                    }
                    final percentage = double.tryParse(value);
                    if (percentage == null ||
                        percentage < 0 ||
                        percentage > 100) {
                      return 'Please enter a valid percentage (0-100)';
                    }
                  }
                  return null;
                },
              ),
            ],
            const SizedBox(height: 32),
            // Save button
            FilledButton(
              onPressed: _saveBudget,
              child: const Text('Save Budget'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveBudget() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedCategoryId == null) {
      ErrorSnackbar.show(context, 'Please select a category');
      return;
    }

    try {
      final repository = ref.read(budgetRepositoryProvider);
      final amount = double.parse(_amountController.text);
      final rolloverPercentage = _rolloverEnabled
          ? double.parse(_rolloverPercentageController.text)
          : 100.0;

      if (widget.budget == null) {
        // Create new budget
        final budget = db.BudgetsCompanion(
          categoryId: drift.Value(_selectedCategoryId!),
          amount: drift.Value(amount),
          period: const drift.Value('monthly'),
          rolloverEnabled: drift.Value(_rolloverEnabled),
          rolloverPercentage: drift.Value(rolloverPercentage),
          startDate: drift.Value(_startDate),
          isActive: const drift.Value(true),
        );

        await repository.createBudget(budget);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Budget created successfully')),
          );
          Navigator.of(context).pop();
        }
      } else {
        // Update existing budget
        final budget = db.BudgetsCompanion(
          id: drift.Value(widget.budget!.id),
          categoryId: drift.Value(_selectedCategoryId!),
          amount: drift.Value(amount),
          period: const drift.Value('monthly'),
          rolloverEnabled: drift.Value(_rolloverEnabled),
          rolloverPercentage: drift.Value(rolloverPercentage),
          startDate: drift.Value(_startDate),
        );

        await repository.updateBudget(budget);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Budget updated successfully')),
          );
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      if (mounted) {
        ErrorSnackbar.show(context, 'Error: $e');
      }
    }
  }

  Future<void> _deleteBudget() async {
    if (widget.budget == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Budget'),
        content: const Text(
          'Are you sure you want to delete this budget? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final repository = ref.read(budgetRepositoryProvider);
      await repository.deleteBudget(widget.budget!.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Budget deleted successfully')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ErrorSnackbar.show(context, 'Error deleting budget: $e');
      }
    }
  }
}
