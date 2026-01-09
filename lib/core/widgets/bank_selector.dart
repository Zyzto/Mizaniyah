import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/banks/providers/bank_providers.dart';

/// A dropdown selector for choosing a bank
class BankSelector extends ConsumerWidget {
  final int? selectedBankId;
  final ValueChanged<int?>? onBankSelected;
  final String? label;
  final String? hint;
  final String? Function(int?)? validator;
  final bool enabled;
  final bool showActiveOnly;

  const BankSelector({
    super.key,
    this.selectedBankId,
    this.onBankSelected,
    this.label,
    this.hint,
    this.validator,
    this.enabled = true,
    this.showActiveOnly = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final banksAsync = showActiveOnly
        ? ref.watch(activeBanksProvider)
        : ref.watch(banksProvider);

    return banksAsync.when(
      data: (banks) {
        if (banks.isEmpty) {
          return DropdownButtonFormField<int?>(
            initialValue: selectedBankId,
            decoration: InputDecoration(
              labelText: label ?? 'Bank',
              hintText: hint ?? 'No banks available',
              errorText: validator?.call(selectedBankId),
            ),
            items: const [],
            onChanged: null,
          );
        }

        return DropdownButtonFormField<int?>(
          initialValue: selectedBankId,
          decoration: InputDecoration(
            labelText: label ?? 'Bank',
            hintText: hint ?? 'Select a bank',
            errorText: validator?.call(selectedBankId),
          ),
          items: [
            const DropdownMenuItem<int?>(value: null, child: Text('None')),
            ...banks.map((bank) {
              return DropdownMenuItem<int?>(
                value: bank.id,
                child: Row(
                  children: [
                    const Icon(Icons.account_balance, size: 20),
                    const SizedBox(width: 8),
                    Text(bank.name),
                    if (!bank.isActive) ...[
                      const SizedBox(width: 8),
                      Text(
                        '(Inactive)',
                        style: TextStyle(
                          fontStyle: FontStyle.italic,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }),
          ],
          onChanged: enabled ? onBankSelected : null,
        );
      },
      loading: () => DropdownButtonFormField<int?>(
        initialValue: selectedBankId,
        decoration: InputDecoration(
          labelText: label ?? 'Bank',
          hintText: 'Loading banks...',
        ),
        items: const [],
        onChanged: null,
      ),
      error: (error, stack) => DropdownButtonFormField<int?>(
        initialValue: selectedBankId,
        decoration: InputDecoration(
          labelText: label ?? 'Bank',
          hintText: 'Error loading banks',
          errorText: 'Failed to load banks',
        ),
        items: const [],
        onChanged: null,
      ),
    );
  }
}
