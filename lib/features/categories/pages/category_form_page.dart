import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import '../providers/category_providers.dart';
import '../widgets/icon_picker_dialog.dart';
import '../widgets/color_picker_dialog.dart';
import '../../../core/database/app_database.dart' as db;
import '../../../core/utils/icon_utils.dart';
import '../../../core/widgets/error_snackbar.dart';

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

  int _getDefaultColorValue() {
    final defaultColor = Colors.blue;
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
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      final repository = ref.read(categoryRepositoryProvider);

      if (widget.category == null) {
        // Create new category
        await repository.createCategory(
          db.CategoriesCompanion(
            name: drift.Value(_nameController.text.trim()),
            icon: drift.Value(_selectedIconName),
            color: drift.Value(_selectedColor),
            isActive: drift.Value(_isActive),
            isPredefined: const drift.Value(false),
          ),
        );
        if (mounted) {
          ErrorSnackbar.showSuccess(context, 'Category created');
          Navigator.of(context).pop();
        }
      } else {
        // Update existing category
        await repository.updateCategory(
          db.CategoriesCompanion(
            id: drift.Value(widget.category!.id),
            name: drift.Value(_nameController.text.trim()),
            icon: drift.Value(_selectedIconName),
            color: drift.Value(_selectedColor),
            isActive: drift.Value(_isActive),
          ),
        );
        if (mounted) {
          ErrorSnackbar.showSuccess(context, 'Category updated');
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      if (mounted) {
        ErrorSnackbar.show(context, 'Failed to save category: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final iconData = _selectedIconName != null
        ? IconUtils.getIconData(_selectedIconName!)
        : Icons.category;
    final color = Color(_selectedColor);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.category == null ? 'New Category' : 'Edit Category'),
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
                labelText: 'Name',
                hintText: 'Enter category name',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Name is required';
                }
                if (value.trim().length > 100) {
                  return 'Name must be 100 characters or less';
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
              title: const Text('Icon'),
              subtitle: Text(_selectedIconName ?? 'None'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                final iconName = await showDialog<String?>(
                  context: context,
                  builder: (context) => IconPickerDialog(
                    selectedIconName: _selectedIconName,
                    onIconSelected: (iconName) {
                      setState(() {
                        _selectedIconName = iconName;
                      });
                    },
                  ),
                );
                if (iconName != null) {
                  setState(() {
                    _selectedIconName = iconName;
                  });
                }
              },
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: CircleAvatar(backgroundColor: color),
              title: const Text('Color'),
              subtitle: Text(
                '#${_selectedColor.toRadixString(16).toUpperCase()}',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                final colorValue = await showDialog<int>(
                  context: context,
                  builder: (context) => ColorPickerDialog(
                    selectedColor: _selectedColor,
                    onColorSelected: (colorValue) {
                      setState(() {
                        _selectedColor = colorValue;
                      });
                    },
                  ),
                );
                if (colorValue != null) {
                  setState(() {
                    _selectedColor = colorValue;
                  });
                }
              },
            ),
            const SizedBox(height: 24),
            SwitchListTile(
              title: const Text('Active'),
              subtitle: const Text(
                'Inactive categories won\'t appear in selectors',
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
