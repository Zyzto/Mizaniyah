import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  'intention',
  'date',
  'purchase_source',
];

// Helper function to get label display names with translations
Map<String, String> _getLabelDisplayNames() {
  return {
    'store_name': 'label_store_name'.tr(),
    'amount': 'label_amount'.tr(),
    'currency': 'label_currency'.tr(),
    'card_last4': 'label_card_last4'.tr(),
    'intention': 'label_intention'.tr(),
    'date': 'label_date'.tr(),
    'purchase_source': 'label_purchase_source'.tr(),
  };
}

// Helper function to get label descriptions
Map<String, String> _getLabelDescriptions() {
  return {
    'store_name': 'label_store_name_description'.tr(),
    'amount': 'label_amount_description'.tr(),
    'currency': 'label_currency_description'.tr(),
    'card_last4': 'label_card_last4_description'.tr(),
    'intention': 'label_intention_description'.tr(),
    'date': 'label_date_description'.tr(),
    'purchase_source': 'label_purchase_source_description'.tr(),
  };
}

const Map<String, Color> _labelColors = {
  'store_name': Color(0xFFFF9800), // Orange
  'amount': Color(0xFF9C27B0), // Purple
  'currency': Color(0xFF2196F3), // Blue
  'card_last4': Color(0xFFF44336), // Red
  'intention': Color(0xFF4CAF50), // Green
  'date': Color(0xFFFFC107), // Amber
  'purchase_source': Color(0xFF00BCD4), // Cyan
};

// Helper function to get icons for labels
IconData _getLabelIcon(String label) {
  switch (label) {
    case 'store_name':
      return Icons.store;
    case 'amount':
      return Icons.attach_money;
    case 'currency':
      return Icons.currency_exchange;
    case 'card_last4':
      return Icons.credit_card;
    case 'intention':
      return Icons.category;
    case 'date':
      return Icons.calendar_today;
    case 'purchase_source':
      return Icons.point_of_sale;
    default:
      return Icons.label;
  }
}

class _SmsTextSelectorState extends State<SmsTextSelector> {
  int? _selectionStart;
  int? _selectionEnd;
  SmsTextSelection? _editingSelection;
  final ScrollController _scrollController = ScrollController();


  @override
  void initState() {
    super.initState();
    _updateCaptureGroups();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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
    final selectedText = widget.text.substring(
      selection.start,
      selection.end > widget.text.length ? widget.text.length : selection.end,
    );
    
    showDialog(
      context: context,
      builder: (context) => _LabelPickerDialog(
        selection: selection,
        selectedText: selectedText,
        onLabelSelected: (label) {
          // Validate label selection
          final warning = _validateLabelSelection(label, selectedText);
          if (warning != null) {
            // Show warning but still allow selection
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(warning),
                  duration: const Duration(seconds: 3),
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: Theme.of(context).colorScheme.errorContainer,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              );
            });
          }
          
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

  // Validate label selection and provide warnings
  String? _validateLabelSelection(String label, String selectedText) {
    final trimmed = selectedText.trim();
    
    // For amount label, check if it's actually a valid number
    if (label == 'amount') {
      // Try to parse as a number
      final cleaned = trimmed.replaceAll(',', '').replaceAll(' ', '');
      final parsed = double.tryParse(cleaned);
      
      // If it's not a valid number at all, don't warn (might be text that will be extracted)
      if (parsed == null) {
        return null;
      }
      
      // Only warn if it's exactly 4 digits with no decimal (likely card number, not amount)
      // But allow amounts like 1000, 2000, etc. by checking if it's a round number >= 1000
      if (RegExp(r'^\d{4}$').hasMatch(cleaned)) {
        // If it's a round number >= 1000, it's likely a valid amount
        if (parsed >= 1000 && parsed == parsed.roundToDouble()) {
          return null; // Valid amount like 1000, 2000, etc.
        }
        // Otherwise, it might be a card number (like 2572)
        return 'label_validation_card_number_warning'.tr();
      }
      
      // Don't warn for small amounts - they might be valid (like 5.00, 100, etc.)
      // Only warn if it's clearly not an amount (like a single digit or two digits that look like card parts)
    }
    
    // Check if card_last4 label is used for a number that looks like an amount
    if (label == 'card_last4') {
      final cleaned = trimmed.replaceAll(',', '').replaceAll(' ', '');
      // If it has a decimal point, it's likely an amount, not a card number
      if (cleaned.contains('.') && double.tryParse(cleaned) != null) {
        return 'label_validation_amount_warning'.tr();
      }
      // If it's more than 4 digits, it's likely an amount
      if (RegExp(r'^\d+$').hasMatch(cleaned) && cleaned.length > 4) {
        return 'label_validation_amount_warning'.tr();
      }
    }
    
    return null;
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


  Widget _buildCompactHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
      child: Row(
        children: [
          Icon(
            Icons.touch_app_outlined,
            size: 18,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'step_2_selection_instructions'.tr(),
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          Tooltip(
            message: 'step_2_selection_instructions'.tr(),
            child: Icon(
              Icons.help_outline,
              size: 20,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequiredStatusBadge(BuildContext context) {
    final hasStoreName = widget.selections.any((s) => s.label == 'store_name');
    final hasAmount = widget.selections.any((s) => s.label == 'amount');
    final allRequired = hasStoreName && hasAmount;
    final count = (hasStoreName ? 1 : 0) + (hasAmount ? 1 : 0);

    return Container(
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: allRequired
            ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3)
            : Theme.of(context).colorScheme.errorContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: allRequired
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.error,
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            allRequired ? Icons.check_circle : Icons.warning,
            size: 16,
            color: allRequired
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.error,
          ),
          const SizedBox(width: 6),
          Text(
            '$count/2 Required',
            style: TextStyle(
              color: allRequired
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.error,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectionChip(SmsTextSelection selection) {
    final displayNames = _getLabelDisplayNames();
    final color = _labelColors[selection.label] ??
        Theme.of(context).colorScheme.primary;
    final selectedText = widget.text.substring(
      selection.start,
      selection.end > widget.text.length ? widget.text.length : selection.end,
    );
    // Truncate long text for preview
    final previewText =
        selectedText.length > 15 ? '${selectedText.substring(0, 15)}...' : selectedText;

    return GestureDetector(
      onTap: () => _editSelection(selection),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        constraints: const BoxConstraints(minHeight: 48),
        child: Chip(
          label: Text(
            '${displayNames[selection.label] ?? selection.label}: "$previewText" (${selection.captureGroup})',
            style: const TextStyle(fontSize: 12),
          ),
          backgroundColor: color.withValues(alpha: 0.2),
          side: BorderSide(color: color, width: 2),
          deleteIcon: const Icon(Icons.close, size: 18),
          onDeleted: () => _removeSelection(selection),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        ),
      ),
    );
  }

  Widget _buildChipBar(BuildContext context) {
    return SizedBox(
      height: 50,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        children: [
          _buildRequiredStatusBadge(context),
          ...widget.selections.map((s) => _buildSelectionChip(s)).toList(),
        ],
      ),
    );
  }

  Widget _buildTextArea() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Scrollbar(
        controller: _scrollController,
        thumbVisibility: true,
        child: SingleChildScrollView(
          controller: _scrollController,
          primary: false,
          child: SelectableText.rich(
            _buildTextSpan(),
            style: TextStyle(
              fontSize: 16,
              height: 1.5,
              color: Theme.of(context).colorScheme.onSurface,
            ),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
          children: [
            // Compact header
            _buildCompactHeader(context),
            // Horizontal scrollable chip bar
            _buildChipBar(context),
            const Divider(height: 16),
            // Text area - fills remaining space
            Expanded(
              child: _buildTextArea(),
            ),
          ],
        ),
        // Floating Create Selection button (FAB) - only show when text is actively selected
        if (_selectionStart != null &&
            _selectionEnd != null &&
            _selectionStart != _selectionEnd)
          Positioned(
            right: 16,
            bottom: 16,
            child: FloatingActionButton.extended(
              onPressed: () {
                HapticFeedback.mediumImpact();
                _createSelection();
              },
              icon: const Icon(Icons.add),
              label: Text('create_selection'.tr()),
              tooltip: 'create_selection'.tr(),
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
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 16, // Increased for better readability
              height: 1.5,
            ),
          ),
        );
      }

      // Add selected text with highlight - use background color instead of underline
      final selectedText = widget.text.substring(
        selection.start,
        selection.end,
      );
      final color = _labelColors[selection.label] ?? Theme.of(context).colorScheme.primary;
      spans.add(
        TextSpan(
          text: selectedText,
          style: TextStyle(
            backgroundColor: color.withValues(alpha: 0.4), // More visible background
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w600,
            // Remove underline, use background highlight only
            fontSize: 16, // Increased for better readability
            height: 1.5,
            // Better Arabic text rendering
            fontFeatures: const [
              FontFeature.enable('liga'),
              FontFeature.enable('kern'),
            ],
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
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 15,
            height: 1.5,
          ),
        ),
      );
    }

    return TextSpan(children: spans);
  }
}

/// Dialog for selecting a label
class _LabelPickerDialog extends StatelessWidget {
  final SmsTextSelection selection;
  final String selectedText;
  final ValueChanged<String> onLabelSelected;

  const _LabelPickerDialog({
    required this.selection,
    required this.selectedText,
    required this.onLabelSelected,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final maxWidth = screenWidth > 600 ? 600.0 : screenWidth * 0.9;
    // Ensure minWidth doesn't exceed maxWidth
    final minWidth = maxWidth < 400 ? maxWidth : 400.0;
    
    return Dialog(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: minWidth,
          maxWidth: maxWidth,
          maxHeight: 600,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Text(
                    'select_label'.tr(),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: 'close'.tr(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Show selected text preview
            if (selectedText.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.text_fields,
                        size: 20,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '"$selectedText"',
                          style: TextStyle(
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (selectedText.isNotEmpty) const Divider(height: 1),
            // Content with better Arabic support
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: _availableLabels.map((label) {
                    final displayNames = _getLabelDisplayNames();
                    final descriptions = _getLabelDescriptions();
                    final displayName = displayNames[label] ?? label;
                    final description = descriptions[label] ?? '';
                    final color = _labelColors[label] ?? Colors.blue;
                    final isSelected = selection.label == label;
                    return InkWell(
                      onTap: () {
                        onLabelSelected(label);
                        Navigator.of(context).pop();
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        color: isSelected
                            ? color.withValues(alpha: 0.1)
                            : Colors.transparent,
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                                border: Border.all(color: color, width: 2.5),
                              ),
                              child: Icon(
                                _getLabelIcon(label),
                                color: color,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    displayName,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.w600,
                                      color: Theme.of(context).colorScheme.onSurface,
                                    ),
                                  ),
                                  if (description.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      description,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant,
                                        height: 1.3,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            if (isSelected) ...[
                              const SizedBox(width: 8),
                              Icon(
                                Icons.check_circle,
                                color: color,
                                size: 24,
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
