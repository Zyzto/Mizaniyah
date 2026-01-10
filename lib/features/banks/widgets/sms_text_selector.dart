import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

/// Represents a text selection with a label
class SmsTextSelection {
  final int start;
  final int end;
  final String label; // 'store_name', 'amount', 'currency', 'card_last4'
  final int captureGroup; // Auto-assigned based on order

  SmsTextSelection({
    required this.start,
    required this.end,
    required this.label,
    required this.captureGroup,
  });

  SmsTextSelection copyWith({
    int? start,
    int? end,
    String? label,
    int? captureGroup,
  }) {
    return SmsTextSelection(
      start: start ?? this.start,
      end: end ?? this.end,
      label: label ?? this.label,
      captureGroup: captureGroup ?? this.captureGroup,
    );
  }

  bool overlapsWith(SmsTextSelection other) {
    return !(end <= other.start || start >= other.end);
  }
}

/// Visual text selector widget for selecting and labeling parts of SMS text
class SmsTextSelector extends StatefulWidget {
  final String text;
  final List<SmsTextSelection> selections;
  final ValueChanged<List<SmsTextSelection>> onSelectionsChanged;

  const SmsTextSelector({
    super.key,
    required this.text,
    required this.selections,
    required this.onSelectionsChanged,
  });

  @override
  State<SmsTextSelector> createState() => _SmsTextSelectorState();
}

// Available labels - moved to top level for access
const List<String> _availableLabels = [
  'store_name',
  'amount',
  'currency',
  'card_last4',
];

const Map<String, String> _labelDisplayNames = {
  'store_name': 'Store Name',
  'amount': 'Amount',
  'currency': 'Currency',
  'card_last4': 'Card (Last 4)',
};

const Map<String, Color> _labelColors = {
  'store_name': Color(0xFFFF9800), // Orange
  'amount': Color(0xFF9C27B0), // Purple
  'currency': Color(0xFF2196F3), // Blue
  'card_last4': Color(0xFFF44336), // Red
};

class _SmsTextSelectorState extends State<SmsTextSelector> {
  int? _selectionStart;
  int? _selectionEnd;
  SmsTextSelection? _editingSelection;

  @override
  void initState() {
    super.initState();
    _updateCaptureGroups();
  }

  @override
  void didUpdateWidget(SmsTextSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selections != widget.selections) {
      _updateCaptureGroups();
    }
  }

  void _updateCaptureGroups() {
    // Sort selections by start position and assign capture groups
    final sorted = List<SmsTextSelection>.from(widget.selections)
      ..sort((a, b) => a.start.compareTo(b.start));

    bool needsUpdate = false;
    for (int i = 0; i < sorted.length; i++) {
      if (sorted[i].captureGroup != i + 1) {
        needsUpdate = true;
        break;
      }
    }

    if (needsUpdate) {
      final updated = <SmsTextSelection>[];
      for (int i = 0; i < sorted.length; i++) {
        updated.add(sorted[i].copyWith(captureGroup: i + 1));
      }
      widget.onSelectionsChanged(updated);
    }
  }

  void _createSelection() {
    if (_selectionStart == null || _selectionEnd == null) return;
    if (_selectionStart == _selectionEnd) return;

    // Ensure start < end
    final start = _selectionStart! < _selectionEnd!
        ? _selectionStart!
        : _selectionEnd!;
    final end = _selectionStart! < _selectionEnd!
        ? _selectionEnd!
        : _selectionStart!;

    // Check for overlaps
    final newSelection = SmsTextSelection(
      start: start,
      end: end,
      label: 'store_name', // Default label
      captureGroup: 0, // Will be updated
    );

    for (final existing in widget.selections) {
      if (existing.overlapsWith(newSelection) &&
          existing != _editingSelection) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('selection_overlaps'.tr()),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
        return;
      }
    }

    // Show label picker
    _showLabelPicker(newSelection);
  }

  void _showLabelPicker(SmsTextSelection selection) {
    showDialog(
      context: context,
      builder: (context) => _LabelPickerDialog(
        selection: selection,
        onLabelSelected: (label) {
          final updated = selection.copyWith(label: label);
          final newSelections = List<SmsTextSelection>.from(widget.selections);
          if (_editingSelection != null) {
            final index = newSelections.indexOf(_editingSelection!);
            if (index != -1) {
              newSelections[index] = updated;
            }
          } else {
            newSelections.add(updated);
          }
          _updateSelections(newSelections);
          _editingSelection = null;
        },
      ),
    );
  }

  void _updateSelections(List<SmsTextSelection> selections) {
    // Sort and reassign capture groups
    selections.sort((a, b) => a.start.compareTo(b.start));
    final updated = selections.asMap().entries.map((entry) {
      return entry.value.copyWith(captureGroup: entry.key + 1);
    }).toList();
    widget.onSelectionsChanged(updated);
  }

  void _removeSelection(SmsTextSelection selection) {
    final newSelections = widget.selections
        .where((s) => s != selection)
        .toList();
    _updateSelections(newSelections);
  }

  void _editSelection(SmsTextSelection selection) {
    setState(() {
      _editingSelection = selection;
    });
    _showLabelPicker(selection);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Instructions and selection info
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 20,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Tap and drag to select text, then assign a label. Required: Store Name, Amount',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
              if (widget.selections.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: widget.selections.map((selection) {
                    return GestureDetector(
                      onTap: () => _editSelection(selection),
                      child: Chip(
                        label: Text(
                          '${_labelDisplayNames[selection.label] ?? selection.label} (${selection.captureGroup})',
                          style: const TextStyle(fontSize: 11),
                        ),
                        backgroundColor: _labelColors[selection.label]
                            ?.withValues(alpha: 0.2),
                        deleteIcon: const Icon(Icons.close, size: 16),
                        onDeleted: () => _removeSelection(selection),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Selectable text area
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
              ),
            ),
            child: SelectableText.rich(
              _buildTextSpan(),
              onSelectionChanged: (selection, cause) {
                if (selection.start >= 0 &&
                    selection.end >= 0 &&
                    selection.start <= widget.text.length &&
                    selection.end <= widget.text.length &&
                    selection.start != selection.end) {
                  setState(() {
                    _selectionStart = selection.start;
                    _selectionEnd = selection.end;
                  });
                }
              },
              contextMenuBuilder: (context, editableTextState) {
                return AdaptiveTextSelectionToolbar.buttonItems(
                  anchors: editableTextState.contextMenuAnchors,
                  buttonItems: [
                    ContextMenuButtonItem(
                      label: 'create_selection'.tr(),
                      onPressed: () {
                        final selection =
                            editableTextState.currentTextEditingValue.selection;
                        if (selection.start >= 0 &&
                            selection.end >= 0 &&
                            selection.start != selection.end) {
                          _selectionStart = selection.start;
                          _selectionEnd = selection.end;
                          ContextMenuController.removeAny();
                          _createSelection();
                        }
                      },
                    ),
                  ],
                );
              },
            ),
          ),
        ),
        // Create selection button
        if (_selectionStart != null &&
            _selectionEnd != null &&
            _selectionStart != _selectionEnd)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: ElevatedButton.icon(
              onPressed: _createSelection,
              icon: const Icon(Icons.add),
              label: Text('create_selection'.tr()),
            ),
          ),
      ],
    );
  }

  TextSpan _buildTextSpan() {
    if (widget.text.isEmpty) {
      return const TextSpan(text: 'No text to select');
    }

    // Sort selections by start position
    final sortedSelections = List<SmsTextSelection>.from(widget.selections)
      ..sort((a, b) => a.start.compareTo(b.start));

    final spans = <TextSpan>[];
    int currentIndex = 0;

    for (final selection in sortedSelections) {
      // Add text before selection
      if (selection.start > currentIndex) {
        spans.add(
          TextSpan(
            text: widget.text.substring(currentIndex, selection.start),
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
          ),
        );
      }

      // Add selected text with highlight
      final selectedText = widget.text.substring(
        selection.start,
        selection.end,
      );
      final color = _labelColors[selection.label] ?? Theme.of(context).colorScheme.primary;
      spans.add(
        TextSpan(
          text: selectedText,
          style: TextStyle(
            backgroundColor: color.withValues(alpha: 0.3),
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            decoration: TextDecoration.underline,
            decorationColor: color,
          ),
        ),
      );

      currentIndex = selection.end;
    }

    // Add remaining text
    if (currentIndex < widget.text.length) {
      spans.add(
        TextSpan(
          text: widget.text.substring(currentIndex),
          style: const TextStyle(color: Colors.black87),
        ),
      );
    }

    return TextSpan(children: spans);
  }
}

/// Dialog for selecting a label
class _LabelPickerDialog extends StatelessWidget {
  final SmsTextSelection selection;
  final ValueChanged<String> onLabelSelected;

  const _LabelPickerDialog({
    required this.selection,
    required this.onLabelSelected,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select Label'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: _availableLabels.map((label) {
          final displayName = _labelDisplayNames[label] ?? label;
          final color = _labelColors[label] ?? Colors.blue;
          final isSelected = selection.label == label;
          return InkWell(
            onTap: () {
              onLabelSelected(label);
              Navigator.of(context).pop();
            },
            child: ListTile(
              leading: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                  border: Border.all(color: color, width: 2),
                ),
              ),
              title: Text(displayName),
              subtitle: Text(label),
              selected: isSelected,
            ),
          );
        }).toList(),
      ),
    );
  }
}
