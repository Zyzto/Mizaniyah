import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:drift/drift.dart' as drift;
import 'package:easy_localization/easy_localization.dart';
import '../widgets/icon_picker_dialog.dart';
import '../widgets/color_picker_dialog.dart';
import '../../../core/database/app_database.dart' as db;
import '../../../core/database/providers/dao_providers.dart';
import '../../../core/utils/icon_utils.dart';
import '../../../core/widgets/error_snackbar.dart';
import '../../../core/widgets/enhanced_text_form_field.dart';
import '../../../core/widgets/loading_button.dart';

class CategoryFormPage extends ConsumerStatefulWidget {
  final db.Category? category;

  const CategoryFormPage({super.key, this.category});

  @override
  ConsumerState<CategoryFormPage> createState() => _CategoryFormPageState();
}

class _CategoryFormPageState extends ConsumerState<CategoryFormPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  String? _selectedIconName;
  late int _selectedColor;
  bool _isActive = true;
  bool _isSaving = false;

  int _getDefaultColorValue() {
    final theme = Theme.of(context);
    final defaultColor = theme.colorScheme.primary;
    final r = (defaultColor.r * 255.0).round().clamp(0, 255);
    final g = (defaultColor.g * 255.0).round().clamp(0, 255);
    final b = (defaultColor.b * 255.0).round().clamp(0, 255);
    final a = (defaultColor.a * 255.0).round().clamp(0, 255);
    return (a << 24) | (r << 16) | (g << 8) | b;
  }

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.category?.name ?? '');
    _selectedIconName = widget.category?.icon;
    _selectedColor = widget.category?.color ?? _getDefaultColorValue();
    _isActive = widget.category?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
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
      final dao = ref.read(categoryDaoProvider);

      if (widget.category == null) {
        // Create new category
        await dao.insertCategory(
          db.CategoriesCompanion(
            name: drift.Value(_nameController.text.trim()),
            icon: drift.Value(_selectedIconName),
            color: drift.Value(_selectedColor),
            isActive: drift.Value(_isActive),
            isPredefined: const drift.Value(false),
          ),
        );
        if (!mounted || !context.mounted) return;
        HapticFeedback.heavyImpact();
        ErrorSnackbar.showSuccess(context, 'category_created'.tr());
        context.pop();
      } else {
        // Update existing category
        await dao.updateCategory(
          db.CategoriesCompanion(
            id: drift.Value(widget.category!.id),
            name: drift.Value(_nameController.text.trim()),
            icon: drift.Value(_selectedIconName),
            color: drift.Value(_selectedColor),
            isActive: drift.Value(_isActive),
          ),
        );
        if (!mounted || !context.mounted) return;
        HapticFeedback.heavyImpact();
        ErrorSnackbar.showSuccess(context, 'category_updated'.tr());
        context.pop();
      }
    } catch (e) {
      if (!mounted || !context.mounted) return;
      HapticFeedback.heavyImpact();
      ErrorSnackbar.show(
        context,
        'category_save_failed'.tr(args: [e.toString()]),
      );
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final iconData = _selectedIconName != null
        ? IconUtils.getIconData(_selectedIconName!)
        : Icons.category;
    final color = Color(_selectedColor);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.category == null ? 'new_category'.tr() : 'edit_category'.tr(),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            EnhancedTextFormField(
              controller: _nameController,
              labelText: 'name'.tr(),
              hintText: 'enter_category_name'.tr(),
              textInputAction: TextInputAction.next,
              maxLength: 100,
              semanticLabel: 'category_name'.tr(),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'name_required'.tr();
                }
                if (value.trim().length > 100) {
                  return 'name_too_long'.tr();
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: CircleAvatar(
                backgroundColor: color.withValues(alpha: 0.2),
                child: Icon(iconData, color: color),
              ),
              title: Text('icon'.tr()),
              subtitle: Text(_selectedIconName ?? 'none'.tr()),
              trailing: Icon(
                Icons.chevron_right,
                color: colorScheme.onSurfaceVariant,
              ),
              onTap: () async {
                HapticFeedback.lightImpact();
                final iconName = await showDialog<String?>(
                  context: context,
                  builder: (context) => IconPickerDialog(
                    selectedIconName: _selectedIconName,
                    onIconSelected: (iconName) {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _selectedIconName = iconName;
                      });
                    },
                  ),
                );
                if (iconName != null && mounted && context.mounted) {
                  setState(() {
                    _selectedIconName = iconName;
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: CircleAvatar(backgroundColor: color),
              title: Text('color'.tr()),
              subtitle: Text(
                '#${_selectedColor.toRadixString(16).padLeft(8, '0').toUpperCase()}',
              ),
              trailing: Icon(
                Icons.chevron_right,
                color: colorScheme.onSurfaceVariant,
              ),
              onTap: () async {
                HapticFeedback.lightImpact();
                final colorValue = await showDialog<int>(
                  context: context,
                  builder: (context) => ColorPickerDialog(
                    selectedColor: _selectedColor,
                    onColorSelected: (colorValue) {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _selectedColor = colorValue;
                      });
                    },
                  ),
                );
                if (colorValue != null && mounted && context.mounted) {
                  setState(() {
                    _selectedColor = colorValue;
                  });
                }
              },
            ),
            const SizedBox(height: 24),
            SwitchListTile(
              title: Text('active'.tr()),
              subtitle: Text('active_category_description'.tr()),
              value: _isActive,
              onChanged: (value) {
                HapticFeedback.lightImpact();
                setState(() {
                  _isActive = value;
                });
              },
            ),
            const SizedBox(height: 32),
            LoadingButton(
              onPressed: _isSaving ? null : _save,
              text: 'save_category'.tr(),
              icon: Icons.save,
              isLoading: _isSaving,
              semanticLabel: 'save_category'.tr(),
            ),
          ],
        ),
      ),
    );
  }
}
