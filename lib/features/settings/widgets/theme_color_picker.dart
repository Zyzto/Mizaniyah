import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';

/// Curated Material 3 theme colors for the app
class ThemeColorPalette {
  static const List<ThemeColorOption> colors = [
    ThemeColorOption(
      color: Color(0xFF6750A4),
      name: 'Purple',
      value: 0xFF6750A4,
    ),
    ThemeColorOption(color: Color(0xFF1976D2), name: 'Blue', value: 0xFF1976D2),
    ThemeColorOption(
      color: Color(0xFF2E7D32),
      name: 'Green',
      value: 0xFF2E7D32,
    ),
    ThemeColorOption(
      color: Color(0xFFF57C00),
      name: 'Orange',
      value: 0xFFF57C00,
    ),
    ThemeColorOption(color: Color(0xFFD32F2F), name: 'Red', value: 0xFFD32F2F),
    ThemeColorOption(color: Color(0xFFC2185B), name: 'Pink', value: 0xFFC2185B),
    ThemeColorOption(color: Color(0xFF00796B), name: 'Teal', value: 0xFF00796B),
    ThemeColorOption(color: Color(0xFF0097A7), name: 'Cyan', value: 0xFF0097A7),
    ThemeColorOption(
      color: Color(0xFF303F9F),
      name: 'Indigo',
      value: 0xFF303F9F,
    ),
    ThemeColorOption(
      color: Color(0xFFFBC02D),
      name: 'Amber',
      value: 0xFFFBC02D,
    ),
    ThemeColorOption(
      color: Color(0xFF5D4037),
      name: 'Brown',
      value: 0xFF5D4037,
    ),
    ThemeColorOption(color: Color(0xFF616161), name: 'Grey', value: 0xFF616161),
  ];

  /// Get color by value
  static ThemeColorOption? getColorByValue(int value) {
    try {
      return colors.firstWhere((c) => c.value == value);
    } catch (e) {
      return null;
    }
  }

  /// Check if a color value is a predefined color
  static bool isPredefinedColor(int value) {
    return getColorByValue(value) != null;
  }
}

/// Theme color option model
class ThemeColorOption {
  final Color color;
  final String name;
  final int value;

  const ThemeColorOption({
    required this.color,
    required this.name,
    required this.value,
  });
}

/// Theme color picker dialog
class ThemeColorPickerDialog extends StatelessWidget {
  final int currentValue;
  final ValueChanged<int> onColorSelected;

  const ThemeColorPickerDialog({
    super.key,
    required this.currentValue,
    required this.onColorSelected,
  });

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColorPalette.colors;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: 500,
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(24, 20, 16, 16),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: colorScheme.outline.withValues(alpha: 0.2),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.palette_rounded,
                      color: colorScheme.onPrimaryContainer,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'select_theme_color'.tr(),
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'theme_color_helper'.tr(),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: 'close'.tr(),
                  ),
                ],
              ),
            ),
            // Color grid
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final crossAxisCount = constraints.maxWidth > 400 ? 4 : 3;
                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 1.0,
                      ),
                      itemCount: colors.length,
                      itemBuilder: (context, index) {
                        final colorOption = colors[index];
                        final isSelected = colorOption.value == currentValue;
                        return _ColorSwatch(
                          color: colorOption.color,
                          isSelected: isSelected,
                          onTap: () {
                            HapticFeedback.mediumImpact();
                            onColorSelected(colorOption.value);
                            Navigator.of(context).pop();
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ),
            // Custom color section
            Container(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: _CustomColorSection(
                currentValue: currentValue,
                onColorSelected: (value) {
                  HapticFeedback.mediumImpact();
                  onColorSelected(value);
                  Navigator.of(context).pop();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Color swatch widget
class _ColorSwatch extends StatelessWidget {
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _ColorSwatch({
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(50),
        child: Container(
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
              color: isSelected
                  ? colorScheme.primary
                  : colorScheme.outline.withValues(alpha: 0.3),
              width: isSelected ? 4 : 2,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.6),
                      blurRadius: 16,
                      spreadRadius: 4,
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ],
          ),
          child: isSelected
              ? Center(
                  child: Icon(
                    Icons.check_circle_rounded,
                    color: _getContrastColor(color),
                    size: 32,
                  ),
                )
              : null,
        ),
      ),
    );
  }

  Color _getContrastColor(Color color) {
    return color.computeLuminance() > 0.5 ? Colors.black : Colors.white;
  }
}

/// Custom color section with HSV picker
class _CustomColorSection extends StatefulWidget {
  final int currentValue;
  final ValueChanged<int> onColorSelected;

  const _CustomColorSection({
    required this.currentValue,
    required this.onColorSelected,
  });

  @override
  State<_CustomColorSection> createState() => _CustomColorSectionState();
}

class _CustomColorSectionState extends State<_CustomColorSection> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isCustom = !ThemeColorPalette.isPredefinedColor(widget.currentValue);
    final currentColor = Color(widget.currentValue);

    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
              HapticFeedback.lightImpact();
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(
                  color: colorScheme.outline.withValues(alpha: 0.2),
                ),
                borderRadius: BorderRadius.circular(16),
                color: _isExpanded
                    ? colorScheme.primaryContainer.withValues(alpha: 0.1)
                    : null,
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: currentColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: colorScheme.outline, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: currentColor.withValues(alpha: 0.3),
                          blurRadius: 6,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'custom_color'.tr(),
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (isCustom) ...[
                          const SizedBox(height: 4),
                          Text(
                            '#${widget.currentValue.toRadixString(16).substring(2).toUpperCase()}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Icon(
                    _isExpanded
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (_isExpanded) ...[
          const SizedBox(height: 16),
          _HSVColorPicker(
            initialColor: currentColor,
            onColorChanged: (color) {
              widget.onColorSelected(color.toARGB32());
            },
          ),
        ],
      ],
    );
  }
}

/// HSV color picker
class _HSVColorPicker extends StatefulWidget {
  final Color initialColor;
  final ValueChanged<Color> onColorChanged;

  const _HSVColorPicker({
    required this.initialColor,
    required this.onColorChanged,
  });

  @override
  State<_HSVColorPicker> createState() => _HSVColorPickerState();
}

class _HSVColorPickerState extends State<_HSVColorPicker> {
  late HSVColor _hsvColor;

  @override
  void initState() {
    super.initState();
    _hsvColor = HSVColor.fromColor(widget.initialColor);
  }

  @override
  void didUpdateWidget(_HSVColorPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialColor != oldWidget.initialColor) {
      _hsvColor = HSVColor.fromColor(widget.initialColor);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final currentColor = _hsvColor.toColor();
    final hexCode =
        '#${currentColor.toARGB32().toRadixString(16).substring(2).toUpperCase()}';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
        borderRadius: BorderRadius.circular(16),
        color: colorScheme.surfaceContainerHighest,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Color preview
          Container(
            width: double.infinity,
            height: 100,
            decoration: BoxDecoration(
              color: currentColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colorScheme.outline, width: 2),
              boxShadow: [
                BoxShadow(
                  color: currentColor.withValues(alpha: 0.4),
                  blurRadius: 12,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: Center(
              child: Text(
                hexCode,
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: _getContrastColor(currentColor),
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Hue slider
          _SliderRow(
            icon: Icons.palette_rounded,
            label: 'hue'.tr(),
            value: _hsvColor.hue,
            min: 0,
            max: 360,
            divisions: 360,
            onChanged: (value) {
              setState(() {
                _hsvColor = _hsvColor.withHue(value);
                widget.onColorChanged(_hsvColor.toColor());
              });
            },
          ),
          const SizedBox(height: 20),
          // Saturation slider
          _SliderRow(
            icon: Icons.contrast_rounded,
            label: 'saturation'.tr(),
            value: _hsvColor.saturation,
            min: 0,
            max: 1,
            divisions: 100,
            onChanged: (value) {
              setState(() {
                _hsvColor = _hsvColor.withSaturation(value);
                widget.onColorChanged(_hsvColor.toColor());
              });
            },
          ),
          const SizedBox(height: 20),
          // Brightness slider
          _SliderRow(
            icon: Icons.brightness_6_rounded,
            label: 'brightness'.tr(),
            value: _hsvColor.value,
            min: 0,
            max: 1,
            divisions: 100,
            onChanged: (value) {
              setState(() {
                _hsvColor = _hsvColor.withValue(value);
                widget.onColorChanged(_hsvColor.toColor());
              });
            },
          ),
        ],
      ),
    );
  }

  Color _getContrastColor(Color color) {
    return color.computeLuminance() > 0.5 ? Colors.black : Colors.white;
  }
}

/// Slider row with icon and label
class _SliderRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final ValueChanged<double> onChanged;

  const _SliderRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: colorScheme.onSurfaceVariant),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          activeColor: colorScheme.primary,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
