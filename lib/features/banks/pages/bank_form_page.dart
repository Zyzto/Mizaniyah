import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import '../providers/bank_providers.dart';
import '../../../core/database/app_database.dart' as db;
import '../../../core/widgets/error_snackbar.dart';

class BankFormPage extends ConsumerStatefulWidget {
  final db.Bank? bank;

  const BankFormPage({super.key, this.bank});

  @override
  ConsumerState<BankFormPage> createState() => _BankFormPageState();
}

class _BankFormPageState extends ConsumerState<BankFormPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _senderPatternController;
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.bank?.name ?? '');
    _senderPatternController = TextEditingController(
      text: widget.bank?.smsSenderPattern ?? '',
    );
    _isActive = widget.bank?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _senderPatternController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      final repository = ref.read(bankRepositoryProvider);
      final senderPattern = _senderPatternController.text.trim();

      if (widget.bank == null) {
        // Create new bank
        await repository.createBank(
          db.BanksCompanion(
            name: drift.Value(_nameController.text.trim()),
            smsSenderPattern: senderPattern.isEmpty
                ? const drift.Value.absent()
                : drift.Value(senderPattern),
            isActive: drift.Value(_isActive),
          ),
        );
        if (mounted) {
          ErrorSnackbar.showSuccess(context, 'Bank created');
          Navigator.of(context).pop();
        }
      } else {
        // Update existing bank
        await repository.updateBank(
          db.BanksCompanion(
            id: drift.Value(widget.bank!.id),
            name: drift.Value(_nameController.text.trim()),
            smsSenderPattern: senderPattern.isEmpty
                ? const drift.Value.absent()
                : drift.Value(senderPattern),
            isActive: drift.Value(_isActive),
          ),
        );
        if (mounted) {
          ErrorSnackbar.showSuccess(context, 'Bank updated');
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      if (mounted) {
        ErrorSnackbar.show(context, 'Failed to save bank: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.bank == null ? 'New Bank' : 'Edit Bank'),
        actions: [IconButton(icon: const Icon(Icons.save), onPressed: _save)],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Bank Name',
                hintText: 'Enter bank name',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Bank name is required';
                }
                if (value.trim().length > 100) {
                  return 'Bank name must be 100 characters or less';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _senderPatternController,
              decoration: const InputDecoration(
                labelText: 'SMS Sender Pattern (Regex)',
                hintText: 'e.g., ^BANK.* or ^\\+1234567890',
                helperText:
                    'Regular expression to match SMS sender. Leave empty to match all.',
              ),
              validator: (value) {
                if (value != null && value.trim().isNotEmpty) {
                  try {
                    RegExp(value.trim());
                  } catch (e) {
                    return 'Invalid regular expression: $e';
                  }
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            SwitchListTile(
              title: const Text('Active'),
              subtitle: const Text(
                'Inactive banks won\'t be used for SMS detection',
              ),
              value: _isActive,
              onChanged: (value) {
                setState(() {
                  _isActive = value;
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}
