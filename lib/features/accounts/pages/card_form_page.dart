import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:drift/drift.dart' as drift;
import 'package:easy_localization/easy_localization.dart';
import '../../../core/database/app_database.dart' as db;
import '../../../core/database/providers/dao_providers.dart';
import '../providers/account_providers.dart';
import '../../../core/widgets/error_snackbar.dart';
import '../../../core/widgets/enhanced_text_form_field.dart';
import '../../../core/widgets/loading_button.dart';

class CardFormPage extends ConsumerStatefulWidget {
  final int? accountId; // Account to add card to (null for standalone card)
  final db.Card? card; // Card to edit (if editing)

  const CardFormPage({super.key, this.accountId, this.card});

  @override
  ConsumerState<CardFormPage> createState() => _CardFormPageState();
}

class _CardFormPageState extends ConsumerState<CardFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _cardNameController = TextEditingController();
  final _last4DigitsController = TextEditingController();
  int? _selectedAccountId;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedAccountId = widget.accountId;
    if (widget.card != null) {
      _cardNameController.text = widget.card!.cardName;
      _last4DigitsController.text = widget.card!.last4Digits;
      _selectedAccountId = widget.card!.accountId;
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
    final accountsAsync = ref.watch(accountsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.card == null ? 'add_card'.tr() : 'edit_card'.tr()),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Account selection (only for new cards or if card has no account)
            if (widget.card == null || widget.card!.accountId == null)
              accountsAsync.when(
                data: (accounts) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'account'.tr(),
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<int?>(
                        initialValue: _selectedAccountId,
                        decoration: InputDecoration(
                          hintText: 'select_account_optional'.tr(),
                          border: const OutlineInputBorder(),
                        ),
                        items: [
                          DropdownMenuItem<int?>(
                            value: null,
                            child: Text('no_account'.tr()),
                          ),
                          ...accounts.map((account) {
                            return DropdownMenuItem<int?>(
                              value: account.id,
                              child: Text(account.name),
                            );
                          }),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedAccountId = value;
                          });
                        },
                      ),
                      const SizedBox(height: 24),
                    ],
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, _) => const SizedBox.shrink(),
              ),
            // Card name
            EnhancedTextFormField(
              controller: _cardNameController,
              labelText: 'card_name'.tr(),
              hintText: 'card_name_hint'.tr(),
              textInputAction: TextInputAction.next,
              semanticLabel: 'card_name'.tr(),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'card_name_required'.tr();
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            // Last 4 digits
            EnhancedTextFormField(
              controller: _last4DigitsController,
              labelText: 'last_4_digits'.tr(),
              hintText: '1234',
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              maxLength: 4,
              semanticLabel: 'last_4_digits'.tr(),
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'last_4_digits_required'.tr();
                }
                if (value.trim().length != 4) {
                  return 'last_4_digits_exact'.tr();
                }
                return null;
              },
            ),
            const SizedBox(height: 32),
            // Save button
            LoadingButton(
              onPressed: _isSaving ? null : _save,
              text: 'save_card'.tr(),
              icon: Icons.save,
              isLoading: _isSaving,
              semanticLabel: 'save_card'.tr(),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    final formState = _formKey.currentState;
    if (formState == null || !formState.validate()) {
      HapticFeedback.mediumImpact();
      return;
    }

    if (!mounted) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final dao = ref.read(cardDaoProvider);
      final last4Digits = _last4DigitsController.text.trim();

      if (widget.card == null) {
        // Create new card
        await dao.insertCard(
          db.CardsCompanion(
            accountId: drift.Value(_selectedAccountId),
            cardName: drift.Value(_cardNameController.text.trim()),
            last4Digits: drift.Value(last4Digits),
            isActive: const drift.Value(true),
          ),
        );
        if (!mounted || !context.mounted) return;
        HapticFeedback.heavyImpact();
        ErrorSnackbar.showSuccess(context, 'card_created'.tr());
        context.pop();
      } else {
        // Update existing card
        await dao.updateCard(
          db.CardsCompanion(
            id: drift.Value(widget.card!.id),
            accountId: drift.Value(_selectedAccountId),
            cardName: drift.Value(_cardNameController.text.trim()),
            last4Digits: drift.Value(last4Digits),
          ),
        );
        if (!mounted || !context.mounted) return;
        HapticFeedback.heavyImpact();
        ErrorSnackbar.showSuccess(context, 'card_updated'.tr());
        context.pop();
      }
    } catch (e) {
      if (!mounted || !context.mounted) return;
      HapticFeedback.heavyImpact();
      ErrorSnackbar.show(context, 'card_save_failed'.tr(args: [e.toString()]));
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }
}
