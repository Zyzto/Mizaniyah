import 'dart:convert';
import '../../features/banks/widgets/sms_text_selector.dart';

/// Result of pattern generation
class PatternGenerationResult {
  final String pattern;
  final String extractionRules;

  PatternGenerationResult({
    required this.pattern,
    required this.extractionRules,
  });
}

/// Service for generating regex patterns and extraction rules from text selections
class SmsPatternGenerator {
  /// Generate regex pattern and extraction rules from text selections
  static PatternGenerationResult generatePattern(
    String smsText,
    List<SmsTextSelection> selections,
  ) {
    if (selections.isEmpty) {
      throw ArgumentError('At least one selection is required');
    }

    // Sort selections by start position
    final sortedSelections = List<SmsTextSelection>.from(selections)
      ..sort((a, b) => a.start.compareTo(b.start));

    // Validate selections don't overlap
    for (int i = 0; i < sortedSelections.length - 1; i++) {
      if (sortedSelections[i].overlapsWith(sortedSelections[i + 1])) {
        throw ArgumentError('Selections cannot overlap');
      }
    }

    // Build regex pattern
    final pattern = _buildRegexPattern(smsText, sortedSelections);

    // Build extraction rules
    final extractionRules = _buildExtractionRules(sortedSelections);

    return PatternGenerationResult(
      pattern: pattern,
      extractionRules: extractionRules,
    );
  }

  /// Build regex pattern from text and selections
  static String _buildRegexPattern(
    String text,
    List<SmsTextSelection> selections,
  ) {
    final buffer = StringBuffer();
    int currentIndex = 0;

    for (final selection in selections) {
      // Add text before selection (escaped)
      if (selection.start > currentIndex) {
        final beforeText = text.substring(currentIndex, selection.start);
        buffer.write(_escapeRegex(beforeText));
      }

      // Add capture group for selection
      // Use a more specific pattern based on label type
      final capturePattern = _getCapturePattern(
        selection.label,
        text,
        selection,
      );
      buffer.write('($capturePattern)');

      currentIndex = selection.end;
    }

    // Add remaining text after last selection (escaped)
    if (currentIndex < text.length) {
      final afterText = text.substring(currentIndex);
      buffer.write(_escapeRegex(afterText));
    }

    return buffer.toString();
  }

  /// Get appropriate capture pattern based on label type
  static String _getCapturePattern(
    String label,
    String fullText,
    SmsTextSelection selection,
  ) {
    final selectedText = fullText.substring(selection.start, selection.end);

    // For amount, use a pattern that matches numbers with optional decimals and commas
    if (label == 'amount') {
      // Check if the selected text looks like a number
      if (RegExp(r'^[\d,]+\.?\d*$').hasMatch(selectedText)) {
        return r'[\d,]+\.?\d*';
      }
      // Fallback to more general pattern
      return r'[\d,\.]+';
    }

    // For card_last4, use pattern for 4 digits
    if (label == 'card_last4') {
      if (RegExp(r'^\d{4}$').hasMatch(selectedText)) {
        return r'\d{4}';
      }
      // Fallback
      return r'\d+';
    }

    // For currency, try to match common currency codes or symbols
    if (label == 'currency') {
      if (RegExp(r'^[A-Z]{3}$').hasMatch(selectedText)) {
        return r'[A-Z]{3}';
      }
      // Could be a currency symbol
      return r'[A-Z$€£¥]+';
    }

    // For store_name and others, use a more general pattern
    // Match any characters except newlines (most SMS are single-line)
    return r'.+?';
  }

  /// Escape special regex characters in text
  static String _escapeRegex(String text) {
    // Escape special regex characters
    return text
        .replaceAll(r'\', r'\\')
        .replaceAll(r'^', r'\^')
        .replaceAll(r'$', r'\$')
        .replaceAll(r'.', r'\.')
        .replaceAll(r'|', r'\|')
        .replaceAll(r'?', r'\?')
        .replaceAll(r'*', r'\*')
        .replaceAll(r'+', r'\+')
        .replaceAll(r'(', r'\(')
        .replaceAll(r')', r'\)')
        .replaceAll(r'[', r'\[')
        .replaceAll(r']', r'\]')
        .replaceAll(r'{', r'\{')
        .replaceAll(r'}', r'\}')
        .replaceAll(r' ', r'\s+'); // Make spaces flexible with \s+
  }

  /// Build extraction rules JSON from selections
  static String _buildExtractionRules(List<SmsTextSelection> selections) {
    final rules = <String, dynamic>{};

    for (final selection in selections) {
      // Use capture group number for extraction
      rules[selection.label] = {'group': selection.captureGroup};
    }

    // If currency is not selected, add a default
    if (!selections.any((s) => s.label == 'currency')) {
      rules['currency'] = 'USD'; // Default currency
    }

    return jsonEncode(rules);
  }
}
