import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:drift/drift.dart' as drift;
import 'package:easy_localization/easy_localization.dart';
import '../../../core/database/app_database.dart' as db;
import '../../../core/database/providers/dao_providers.dart';
import '../../../core/widgets/error_snackbar.dart';
import '../../../core/widgets/enhanced_text_form_field.dart';
import '../../../core/widgets/loading_button.dart';

class AccountFormPage extends ConsumerStatefulWidget {
  final db.Account? account;

  const AccountFormPage({super.key, this.account});

  @override
  ConsumerState<AccountFormPage> createState() => _AccountFormPageState();
}

class _AccountFormPageState extends ConsumerState<AccountFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _accountNameController = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.account != null) {
      _accountNameController.text = widget.account!.name;
    }
  }

  @override
  void dispose() {
    _accountNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.account == null ? 'add_account'.tr() : 'edit_account'.tr(),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Account name
            EnhancedTextFormField(
              controller: _accountNameController,
              labelText: 'account_name'.tr(),
              hintText: 'account_name_hint'.tr(),
              textInputAction: TextInputAction.done,
              semanticLabel: 'account_name'.tr(),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'account_name_required'.tr();
                }
                return null;
              },
            ),
            const SizedBox(height: 32),
            // Save button
            LoadingButton(
              onPressed: _isSaving ? null : _save,
              text: 'save_account'.tr(),
              icon: Icons.save,
              isLoading: _isSaving,
              semanticLabel: 'save_account'.tr(),
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
      final dao = ref.read(accountDaoProvider);

      if (widget.account == null) {
        // Create new account
        await dao.insertAccount(
          db.AccountsCompanion(
            name: drift.Value(_accountNameController.text.trim()),
            isActive: const drift.Value(true),
          ),
        );
        if (!mounted || !context.mounted) return;
        HapticFeedback.heavyImpact();
        ErrorSnackbar.showSuccess(context, 'account_created'.tr());
        context.pop();
      } else {
        // Update existing account
        await dao.updateAccount(
          db.AccountsCompanion(
            id: drift.Value(widget.account!.id),
            name: drift.Value(_accountNameController.text.trim()),
          ),
        );
        if (!mounted || !context.mounted) return;
        HapticFeedback.heavyImpact();
        ErrorSnackbar.showSuccess(context, 'account_updated'.tr());
        context.pop();
      }
    } catch (e) {
      if (!mounted || !context.mounted) return;
      HapticFeedback.heavyImpact();
      ErrorSnackbar.show(
        context,
        'account_save_failed'.tr(args: [e.toString()]),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }
}
