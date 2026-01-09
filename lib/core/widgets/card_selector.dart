import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/banks/providers/bank_providers.dart';

/// A dropdown selector for choosing a card
class CardSelector extends ConsumerWidget {
  final int? selectedCardId;
  final ValueChanged<int?>? onCardSelected;
  final String? label;
  final String? hint;
  final String? Function(int?)? validator;
  final bool enabled;
  final int? bankId; // Optional: filter cards by bank

  const CardSelector({
    super.key,
    this.selectedCardId,
    this.onCardSelected,
    this.label,
    this.hint,
    this.validator,
    this.enabled = true,
    this.bankId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cardsAsync = ref.watch(allCardsProvider);

    return cardsAsync.when(
      data: (cards) {
        // Filter by bank if specified
        final filteredCards = bankId != null
            ? cards.where((c) => c.bankId == bankId).toList()
            : cards;

        if (filteredCards.isEmpty) {
          return DropdownButtonFormField<int?>(
            initialValue: selectedCardId,
            decoration: InputDecoration(
              labelText: label ?? 'Card',
              hintText: hint ?? 'No cards available',
              errorText: validator?.call(selectedCardId),
            ),
            items: const [],
            onChanged: null,
          );
        }

        return DropdownButtonFormField<int?>(
          initialValue: selectedCardId,
          decoration: InputDecoration(
            labelText: label ?? 'Card',
            hintText: hint ?? 'Select a card',
            errorText: validator?.call(selectedCardId),
          ),
          items: [
            const DropdownMenuItem<int?>(value: null, child: Text('None')),
            ...filteredCards.map((card) {
              return DropdownMenuItem<int?>(
                value: card.id,
                child: Text(
                  card.cardName.isNotEmpty
                      ? '${card.cardName} (****${card.last4Digits})'
                      : 'Card ****${card.last4Digits}',
                ),
              );
            }),
          ],
          onChanged: enabled ? onCardSelected : null,
        );
      },
      loading: () => DropdownButtonFormField<int?>(
        initialValue: selectedCardId,
        decoration: InputDecoration(
          labelText: label ?? 'Card',
          hintText: 'Loading cards...',
        ),
        items: const [],
        onChanged: null,
      ),
      error: (error, stack) => DropdownButtonFormField<int?>(
        initialValue: selectedCardId,
        decoration: InputDecoration(
          labelText: label ?? 'Card',
          hintText: 'Error loading cards',
          errorText: 'Failed to load cards',
        ),
        items: const [],
        onChanged: null,
      ),
    );
  }
}
