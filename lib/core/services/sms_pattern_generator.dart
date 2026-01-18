import 'dart:convert';
import '../../features/sms_management/widgets/sms_text_selector.dart';

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

    // Build extraction rules (includes pattern and field-specific patterns)
    final extractionRules = _buildExtractionRules(
      sortedSelections,
      pattern,
      smsText,
    );

    return PatternGenerationResult(
      pattern: pattern,
      extractionRules: extractionRules,
    );
  }

  /// Build regex pattern from text and selections
  /// Creates a flexible pattern based on field positions
  /// Field-specific patterns in extraction rules handle actual extraction
  static String _buildRegexPattern(
    String text,
    List<SmsTextSelection> selections,
  ) {
    final buffer = StringBuffer();
    int currentIndex = 0;
    final totalFields = selections.length;

    for (int i = 0; i < selections.length; i++) {
      final selection = selections[i];

      // Add text before selection - use very flexible pattern
      if (selection.start > currentIndex) {
        final beforeText = text.substring(currentIndex, selection.start);
        // Get next field label for context (if available)
        final nextFieldLabel = i < selections.length - 1
            ? selections[i + 1].label
            : '';
        buffer.write(
          _buildPositionBasedPattern(
            beforeText,
            nextFieldLabel,
            i,
            totalFields,
          ),
        );
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

    // Add remaining text after last selection (make it optional/flexible)
    if (currentIndex < text.length) {
      // Trailing text is optional - allows extra information
      buffer.write(r'(?:\s*.*)?');
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
    // Also support Arabic-Indic numerals (٠١٢٣٤٥٦٧٨٩)
    if (label == 'amount') {
      // Check if the selected text looks like a number (Western or Arabic-Indic)
      if (RegExp(r'^[\d٠-٩,،]+[\.٫]?[\d٠-٩]*$').hasMatch(selectedText)) {
        return r'[\d٠-٩,،]+[\.٫]?[\d٠-٩]*';
      }
      // Fallback to more general pattern
      return r'[\d٠-٩,،\.٫]+';
    }

    // For card_last4, use pattern for 4 digits (may include asterisks)
    // Also support Arabic-Indic numerals
    // Handles both formats: "2572*" and "**7630"
    if (label == 'card_last4') {
      // Clean the selected text to extract just digits
      final digitsOnly = selectedText.replaceAll(RegExp(r'[^\d٠-٩]'), '');
      if (digitsOnly.length == 4) {
        // Check if asterisks are before or after
        final hasAsterisksBefore = selectedText.trim().startsWith('*');
        final hasAsterisksAfter = selectedText.trim().endsWith('*');

        if (hasAsterisksBefore) {
          // Pattern: **1234 or *1234
          return r'\*{1,2}[\d٠-٩]{4}';
        } else if (hasAsterisksAfter) {
          // Pattern: 1234*
          return r'[\d٠-٩]{4}\*+';
        } else {
          // Just digits
          return r'[\d٠-٩]{4}';
        }
      }
      // Fallback: match 4 digits with optional asterisks on either side
      return r'\*{0,2}[\d٠-٩]{4}\*{0,2}';
    }

    // For currency, learn from the selected text
    if (label == 'currency') {
      // If it's a 3-letter code (like SAR, USD, EUR)
      if (RegExp(r'^[A-Z]{3}$').hasMatch(selectedText)) {
        return r'[A-Z]{3}';
      }
      // If it's a word/phrase, use flexible pattern that matches similar structure
      // Learn from actual text - no hardcoded currency names
      if (RegExp(r'^[\u0600-\u06FF\s]+$').hasMatch(selectedText)) {
        // Arabic text - match similar word patterns
        return r'[\u0600-\u06FF\s]+';
      }
      // General pattern for currency symbols or codes
      return r'[A-Za-z$€£¥\u0600-\u06FF]+';
    }

    // For date, use pattern for dates (various formats)
    if (label == 'date') {
      // Try to match common date formats
      if (RegExp(
        r'^[\d٠-٩]{1,2}[/-][\d٠-٩]{1,2}[/-][\d٠-٩]{2,4}$',
      ).hasMatch(selectedText)) {
        return r'[\d٠-٩]{1,2}[/-][\d٠-٩]{1,2}[/-][\d٠-٩]{2,4}';
      }
      if (RegExp(
        r'^[\d٠-٩]{4}[/-][\d٠-٩]{1,2}[/-][\d٠-٩]{1,2}$',
      ).hasMatch(selectedText)) {
        return r'[\d٠-٩]{4}[/-][\d٠-٩]{1,2}[/-][\d٠-٩]{1,2}';
      }
      // Fallback to general date pattern
      return r'[\d٠-٩/\-\.\s]+';
    }

    // For time, use pattern for time formats (HH:MM or HH:MM:SS)
    if (label == 'time') {
      if (RegExp(
        r'^[\d٠-٩]{1,2}:[\d٠-٩]{2}(:\d{2})?$',
      ).hasMatch(selectedText)) {
        return r'[\d٠-٩]{1,2}:[\d٠-٩]{2}(:[\d٠-٩]{2})?';
      }
      return r'[\d٠-٩:]+';
    }

    // For account_number, use pattern for account numbers (various lengths)
    if (label == 'account_number') {
      final digitsOnly = selectedText.replaceAll(RegExp(r'[^\d٠-٩]'), '');
      if (digitsOnly.isNotEmpty) {
        // Match similar length account numbers
        final length = digitsOnly.length;
        if (length >= 4 && length <= 24) {
          // Use string interpolation (not raw string) to include the length values
          return r'[\d٠-٩*]{'
              '${length - 2},${length + 2}'
              r'}';
        }
      }
      return r'[\d٠-٩*]+';
    }

    // For reference_number, use pattern for reference/transaction IDs
    if (label == 'reference_number') {
      // Reference numbers are usually alphanumeric
      if (RegExp(r'^[A-Za-z0-9٠-٩]+$').hasMatch(selectedText)) {
        return r'[A-Za-z0-9٠-٩]+';
      }
      return r'[A-Za-z0-9٠-٩\-]+';
    }

    // For intention (purchase, buy, transfer, refund, etc.)
    if (label == 'intention') {
      // Match common transaction intention words (English or Arabic)
      if (RegExp(r'^[\u0600-\u06FF\s]+$').hasMatch(selectedText)) {
        // Arabic text
        return r'[\u0600-\u06FF\s]+';
      }
      return r'[A-Za-z]+';
    }

    // For purchase_source (internet, pos, atm, etc.)
    if (label == 'purchase_source') {
      // Match common source identifiers (English or Arabic)
      if (RegExp(r'^[\u0600-\u06FF\s]+$').hasMatch(selectedText)) {
        return r'[\u0600-\u06FF\s]+';
      }
      return r'[A-Za-z]+';
    }

    // For store_name, match until newline (greedy to capture full name)
    // This captures full store names including spaces and special characters
    // Excludes digits to avoid false matches like "من Card: **1234"
    if (label == 'store_name') {
      // Match any characters except newlines and digits at the start
      // This captures complete store names like "semu chai", "barq", "QUTUB BRAND ESTABLISHM"
      // Stops at newline which is typically where next field starts
      // Pattern: [^\n\r]+ but exclude lines that start with digits (to avoid false matches)
      return r'[^\n\r0-9٠-٩]+';
    }

    // For other fields, use non-greedy pattern
    return r'.+?';
  }

  /// Escape special regex characters in text
  static String _escapeRegex(String text) {
    // Escape special regex characters
    var result = text
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
        .replaceAll(r'}', r'\}');

    // Replace whitespace (spaces, tabs, newlines) with flexible \s+ pattern
    // This handles multi-line SMS messages correctly
    result = result.replaceAll(RegExp(r'[\s\n\r\t]+'), r'\s+');

    return result;
  }

  /// Build position-based pattern - focuses on field locations, not literal text
  /// No hardcoded language or message-type assumptions - learns from actual text
  static String _buildPositionBasedPattern(
    String text,
    String nextFieldLabel,
    int fieldIndex,
    int totalFields,
  ) {
    if (text.trim().isEmpty) {
      // Just whitespace - make it flexible
      return r'\s*';
    }

    // Extract meaningful words from the text (potential structural indicators)
    // Keep them as optional anchors but allow flexible text around them
    final trimmed = text.trim();

    // Find the last significant word/phrase in the text (likely the indicator)
    // This is learned from the actual SMS, not hardcoded
    final words = trimmed.split(RegExp(r'[\s\n\r]+'));
    if (words.isNotEmpty) {
      // Take the last 1-2 words as potential structural indicator
      final lastWords = words.length <= 2
          ? words
          : words.sublist(words.length - 2);
      final potentialIndicator = lastWords.join(' ').trim();

      if (potentialIndicator.isNotEmpty) {
        // Escape and use as optional anchor
        final escaped = _escapeRegex(potentialIndicator);
        // Allow flexible text before, keep indicator, flexible after
        return r'\s*(?:.*?\s*)?' + escaped + r'\s*';
      }
    }

    // For text between fields, use flexible pattern
    // Allows any text variations while maintaining position awareness
    return r'\s*.*?\s*';
  }

  /// Build extraction rules JSON from selections
  /// Uses hybrid approach: main pattern for matching + field-specific patterns for extraction
  static String _buildExtractionRules(
    List<SmsTextSelection> selections,
    String pattern,
    String smsText,
  ) {
    final rules = <String, dynamic>{};

    // Sort selections by capture group to ensure correct order
    final sortedSelections = List<SmsTextSelection>.from(selections)
      ..sort((a, b) => a.captureGroup.compareTo(b.captureGroup));

    // Add all selected fields with their capture groups AND field-specific patterns
    for (final selection in sortedSelections) {
      // Only include if capture group is valid (greater than 0)
      if (selection.captureGroup > 0) {
        // Generate field-specific pattern for independent extraction
        final fieldPattern = _generateFieldSpecificPattern(
          selection.label,
          smsText,
          selection,
        );

        // Use both capture group (for main pattern) and field pattern (for flexibility)
        rules[selection.label] = {
          'group': selection.captureGroup,
          'pattern':
              fieldPattern, // Field-specific pattern for independent extraction
        };
      }
    }

    // Currency is optional - no default value
    // User should select it if needed, or it can be extracted from amount field

    // Auto-enable SMS date fallback if no date field was selected
    // This ensures transactions get a date even if not extracted from SMS
    if (!selections.any((s) => s.label == 'date')) {
      rules['use_sms_date_fallback'] = true;
    }

    // Add the pattern at the end for reference
    rules['pattern'] = pattern;

    // Format JSON with proper indentation for readability
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(rules);
  }

  /// Generate field-specific pattern for independent extraction
  /// Learns indicators dynamically from the text before the selection
  /// No hardcoded language or message-type assumptions
  static String _generateFieldSpecificPattern(
    String label,
    String smsText,
    SmsTextSelection selection,
  ) {
    // Extract text immediately before the selection (context window)
    // Look back a reasonable amount to find potential indicators
    final contextStart = (selection.start - 50).clamp(0, selection.start);
    final contextText = smsText.substring(contextStart, selection.start);

    // Extract the word/phrase immediately before the selection
    // This is what the user sees as the "label" for this field
    final immediateBefore = _extractImmediateContext(
      contextText,
      selection.start - contextStart,
    );

    // Get the capture pattern for this field type
    final capturePattern = _getCapturePattern(label, smsText, selection);

    // Build pattern using learned indicator from actual SMS text
    if (immediateBefore != null && immediateBefore.isNotEmpty) {
      final escapedIndicator = _escapeRegex(immediateBefore);

      // Special handling for store_name: capture until newline, exclude digits
      // This avoids false matches while capturing full store names
      if (label == 'store_name') {
        // Pattern: indicator, capture text until newline (excluding digits)
        // This captures full store names like "semu chai", "barq", etc.
        // Exclude digits to avoid matching card/account numbers
        return escapedIndicator + r'\s*:?\s*([^\n\r0-9٠-٩]+)';
      }

      // For amount: check if there's non-numeric text after the number
      // Learn dynamically from the SMS structure (currency might be before or after)
      if (label == 'amount') {
        final textAfter = smsText.substring(
          selection.end,
          (selection.end + 30).clamp(selection.end, smsText.length),
        );
        // Check if there's text after that looks like currency (letters/words, not just numbers)
        final hasTextAfter = RegExp(
          r'\s+[A-Za-z\u0600-\u06FF]{2,}',
        ).hasMatch(textAfter);

        if (hasTextAfter) {
          // Text (currency) after number: capture number first, then text
          // This handles "50 SAR", "13 ريال", etc.
          return r'(?:.*?)?(' +
              capturePattern +
              r')\s+[A-Za-z\u0600-\u06FF\s]+';
        } else {
          // Text (currency) before number or no currency: standard pattern
          // This handles "مبلغ: 13", "SAR 80", etc.
          return r'(?:.*?)?' +
              escapedIndicator +
              r'[:\s]*(' +
              capturePattern +
              r')';
        }
      }

      // Default pattern: learned indicator (optional colon/space/punctuation) + value
      return r'(?:.*?)?' +
          escapedIndicator +
          r'[:\s]*(' +
          capturePattern +
          r')';
    }

    // If no clear indicator found, use flexible pattern
    // Special handling for store_name to stop at newline
    if (label == 'store_name') {
      return r'([^\n\r0-9٠-٩]+)';
    }

    return r'(?:.*?)?(' + capturePattern + r')';
  }

  /// Extract the immediate context (word/phrase) before a selection
  /// Returns the text that appears to be the "label" for this field
  static String? _extractImmediateContext(
    String contextText,
    int relativePosition,
  ) {
    if (contextText.isEmpty) return null;

    // Find the last word or phrase before the selection
    // Look for patterns like: "word:", "word ", "phrase:", etc.
    final trimmed = contextText.trim();
    if (trimmed.isEmpty) return null;

    // Extract the last "token" (word or phrase) before the selection
    // This handles cases like "مبلغ:", "from:", "بطاقة مدى:", etc.
    final words = trimmed.split(RegExp(r'[\s\n\r]+'));
    if (words.isEmpty) return null;

    // Take the last 1-3 words as potential indicator
    // This handles both single words ("مبلغ") and phrases ("بطاقة مدى")
    final lastWords = words.length <= 3
        ? words
        : words.sublist(words.length - 3);

    final indicator = lastWords.join(' ').trim();

    // Clean up: remove trailing punctuation but keep colons (they're part of the pattern)
    return indicator.replaceAll(RegExp(r'[^\w\u0600-\u06FF\s:]+$'), '');
  }
}
