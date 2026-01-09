import 'package:flutter/material.dart';
import '../../../core/utils/icon_utils.dart';

class IconPickerDialog extends StatelessWidget {
  final String? selectedIconName;
  final ValueChanged<String?> onIconSelected;

  const IconPickerDialog({
    super.key,
    this.selectedIconName,
    required this.onIconSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxHeight: 500),
        child: Column(
          children: [
            AppBar(
              title: const Text('Select Icon'),
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: IconUtils.commonIcons.length + 1, // +1 for "None"
                itemBuilder: (context, index) {
                  if (index == 0) {
                    // "None" option
                    final isSelected = selectedIconName == null;
                    return InkWell(
                      onTap: () {
                        onIconSelected(null);
                        Navigator.of(context).pop();
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: isSelected ? Colors.blue : Colors.grey,
                            width: isSelected ? 2 : 1,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.block, size: 32),
                            const SizedBox(height: 4),
                            const Text('None', style: TextStyle(fontSize: 12)),
                          ],
                        ),
                      ),
                    );
                  }

                  final icon = IconUtils.commonIcons[index - 1];
                  final iconName = IconUtils.getIconName(icon);
                  final isSelected = selectedIconName == iconName;

                  return InkWell(
                    onTap: () {
                      onIconSelected(iconName);
                      Navigator.of(context).pop();
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isSelected ? Colors.blue : Colors.grey,
                          width: isSelected ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(icon, size: 32),
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
