import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';

class ColorPickerDialog extends StatelessWidget {
  final int selectedColor;
  final ValueChanged<int> onColorSelected;

  const ColorPickerDialog({
    super.key,
    required this.selectedColor,
    required this.onColorSelected,
  });

  static final List<Color> predefinedColors = [
    Colors.red,
    Colors.pink,
    Colors.purple,
    Colors.deepPurple,
    Colors.indigo,
    Colors.blue,
    Colors.lightBlue,
    Colors.cyan,
    Colors.teal,
    Colors.green,
    Colors.lightGreen,
    Colors.lime,
    Colors.yellow,
    Colors.amber,
    Colors.orange,
    Colors.deepOrange,
    Colors.brown,
    Colors.grey,
    Colors.blueGrey,
    Colors.black,
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxHeight: 400),
        child: Column(
          children: [
            AppBar(
              title: Text('select_color'.tr()),
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  icon: const Icon(Icons.close),
                  tooltip: 'close'.tr(),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: predefinedColors.length,
                itemBuilder: (context, index) {
                  final color = predefinedColors[index];
                  // Convert Color to int (ARGB32 format)
                  final r = (color.r * 255.0).round().clamp(0, 255);
                  final g = (color.g * 255.0).round().clamp(0, 255);
                  final b = (color.b * 255.0).round().clamp(0, 255);
                  final a = (color.a * 255.0).round().clamp(0, 255);
                  final colorValue = (a << 24) | (r << 16) | (g << 8) | b;
                  final isSelected = selectedColor == colorValue;

                  return InkWell(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      // Convert Color to int (ARGB32 format)
                      final r = (color.r * 255.0).round().clamp(0, 255);
                      final g = (color.g * 255.0).round().clamp(0, 255);
                      final b = (color.b * 255.0).round().clamp(0, 255);
                      final a = (color.a * 255.0).round().clamp(0, 255);
                      final colorValue = (a << 24) | (r << 16) | (g << 8) | b;
                      onColorSelected(colorValue);
                      Navigator.of(context).pop();
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      decoration: BoxDecoration(
                        color: color,
                        border: Border.all(
                          color: isSelected
                              ? colorScheme.primary
                              : colorScheme.outline,
                          width: isSelected ? 3 : 1,
                        ),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: color.withValues(alpha: 0.5),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                              ]
                            : null,
                      ),
                      child: isSelected
                          ? Icon(
                              Icons.check,
                              color: color.computeLuminance() > 0.5
                                  ? Colors.black
                                  : Colors.white,
                            )
                          : null,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
