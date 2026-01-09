import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import '../../banks/providers/bank_providers.dart';
import '../../banks/pages/bank_form_page.dart';
import '../../../core/database/app_database.dart' as db;
import '../../../core/widgets/error_snackbar.dart';

class AccountFormPage extends ConsumerStatefulWidget {
  final db.Card? card;

  const AccountFormPage({super.key, this.card});

  @override
  ConsumerState<AccountFormPage> createState() => _AccountFormPageState();
}

class _AccountFormPageState extends ConsumerState<AccountFormPage> {
  final _formKey = GlobalKey<FormState>();
  int? _selectedBankId;
  final _cardNameController = TextEditingController();
  final _last4DigitsController = TextEditingController();
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    if (widget.card != null) {
      _selectedBankId = widget.card!.bankId;
      _cardNameController.text = widget.card!.cardName;
      _last4DigitsController.text = widget.card!.last4Digits;
      _isActive = widget.card!.isActive;
    }
  }

  @override
  void dispose() {
    _cardNameController.dispose();
    _last4DigitsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final banksAsync = ref.watch(banksProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.card == null ? 'Add Account' : 'Edit Account'),
        actions: [IconButton(icon: const Icon(Icons.save), onPressed: _save)],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Bank selector
            banksAsync.when(
              data: (banks) {
                if (banks.isEmpty) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          const Text(
                            'No banks available. Please add a bank first.',
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              // Navigate to add bank
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => const BankFormPage(),
                                ),
                              );
                            },
                            child: const Text('Add Bank'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return DropdownButtonFormField<int>(
                  value: _selectedBankId,
                  decoration: const InputDecoration(
                    labelText: 'Bank',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.account_balance),
                  ),
                  items: banks.map((bank) {
                    return DropdownMenuItem<int>(
                      value: bank.id,
                      child: Text(bank.name),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedBankId = value;
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Please select a bank';
                    }
                    return null;
                  },
                );
              },
              loading: () => const CircularProgressIndicator(),
              error: (_, __) => const Text('Error loading banks'),
            ),
            const SizedBox(height: 16),
            // Card name
            TextFormField(
              controller: _cardNameController,
              decoration: const InputDecoration(
                labelText: 'Account Name',
                hintText: 'e.g., My Credit Card',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.credit_card),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter an account name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            // Last 4 digits
            TextFormField(
              controller: _last4DigitsController,
              decoration: const InputDecoration(
                labelText: 'Last 4 Digits',
                hintText: '1234',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.numbers),
              ),
              keyboardType: TextInputType.number,
              maxLength: 4,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter last 4 digits';
                }
                if (value.trim().length != 4) {
                  return 'Must be exactly 4 digits';
                }
                if (!RegExp(r'^\d+$').hasMatch(value.trim())) {
                  return 'Must contain only numbers';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            // Active toggle
            SwitchListTile(
              title: const Text('Active'),
              subtitle: const Text('Enable this account for transactions'),
              value: _isActive,
              onChanged: (value) {
                setState(() {
                  _isActive = value;
                });
              },
            ),
            const SizedBox(height: 32),
            // Save button
            FilledButton(onPressed: _save, child: const Text('Save Account')),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedBankId == null) {
      ErrorSnackbar.show(context, 'Please select a bank');
      return;
    }

    try {
      final repository = ref.read(bankRepositoryProvider);
      final last4Digits = _last4DigitsController.text.trim();

      if (widget.card == null) {
        // Create new card
        await repository.createCard(
          db.CardsCompanion(
            bankId: drift.Value(_selectedBankId!),
            cardName: drift.Value(_cardNameController.text.trim()),
            last4Digits: drift.Value(last4Digits),
            isActive: drift.Value(_isActive),
          ),
        );
        if (mounted) {
          ErrorSnackbar.showSuccess(context, 'Account created successfully');
          Navigator.of(context).pop();
        }
      } else {
        // Update existing card
        await repository.updateCard(
          db.CardsCompanion(
            id: drift.Value(widget.card!.id),
            bankId: drift.Value(_selectedBankId!),
            cardName: drift.Value(_cardNameController.text.trim()),
            last4Digits: drift.Value(last4Digits),
            isActive: drift.Value(_isActive),
          ),
        );
        if (mounted) {
          ErrorSnackbar.showSuccess(context, 'Account updated successfully');
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      if (mounted) {
        ErrorSnackbar.show(context, 'Error: $e');
      }
    }
  }
}
