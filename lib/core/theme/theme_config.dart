import 'package:flutter/material.dart';

/// Central theme configuration for the Mizaniyah app.
///
/// This class contains all theme-related constants and configurations
/// to ensure consistency across the entire application.
class ThemeConfig {
  ThemeConfig._(); // Private constructor to prevent instantiation

  // ============================================================================
  // SPACING CONSTANTS
  // ============================================================================

  /// Base spacing unit (8dp)
  static const double spacingUnit = 8.0;

  /// Spacing values following 8dp grid system
  static const double spacingXS = spacingUnit * 0.5; // 4dp
  static const double spacingS = spacingUnit; // 8dp
  static const double spacingM = spacingUnit * 2; // 16dp
  static const double spacingL = spacingUnit * 3; // 24dp
  static const double spacingXL = spacingUnit * 4; // 32dp
  static const double spacingXXL = spacingUnit * 6; // 48dp

  // ============================================================================
  // BORDER RADIUS CONSTANTS
  // ============================================================================

  /// Small border radius (4dp)
  static const double radiusS = 4.0;

  /// Medium border radius (8dp)
  static const double radiusM = 8.0;

  /// Large border radius (12dp) - used for cards and inputs
  static const double radiusL = 12.0;

  /// Extra large border radius (16dp)
  static const double radiusXL = 16.0;

  /// Extra extra large border radius (24dp)
  static const double radiusXXL = 24.0;

  // ============================================================================
  // ELEVATION CONSTANTS
  // ============================================================================

  /// No elevation
  static const double elevationNone = 0.0;

  /// Low elevation (1dp) - for subtle surfaces
  static const double elevationLow = 1.0;

  /// Medium elevation (2dp) - for cards
  static const double elevationMedium = 2.0;

  /// High elevation (4dp) - for dialogs and modals
  static const double elevationHigh = 4.0;

  /// Very high elevation (8dp) - for app bars and floating elements
  static const double elevationVeryHigh = 8.0;

  // ============================================================================
  // CARD THEME CONSTANTS
  // ============================================================================

  /// Default card elevation
  static const double cardElevation = elevationMedium;

  /// Default card border radius
  static const double cardBorderRadius = radiusL;

  // ============================================================================
  // INPUT DECORATION CONSTANTS
  // ============================================================================

  /// Input border radius
  static const double inputBorderRadius = radiusL;

  /// Focused input border width
  static const double inputFocusedBorderWidth = 2.0;

  /// Default input border width
  static const double inputDefaultBorderWidth = 1.0;

  // ============================================================================
  // DIVIDER CONSTANTS
  // ============================================================================

  /// Default divider thickness
  static const double dividerThickness = 1.0;

  /// Default divider spacing
  static const double dividerSpacing = 1.0;

  // ============================================================================
  // TEXT SCALE FACTORS
  // ============================================================================

  /// Text scale factor for small font size
  static const double textScaleSmall = 0.85;

  /// Text scale factor for normal font size
  static const double textScaleNormal = 1.0;

  /// Text scale factor for large font size
  static const double textScaleLarge = 1.15;

  /// Text scale factor for extra large font size
  static const double textScaleExtraLarge = 1.3;

  // ============================================================================
  // COLOR CONSTANTS
  // ============================================================================

  /// Default seed color (Material Green)
  static const Color defaultSeedColor = Color(0xFF2E7D32);

  /// Default fallback seed color (Deep Purple)
  static const Color fallbackSeedColor = Colors.deepPurple;

  // ============================================================================
  // LIGHT THEME COLORS
  // ============================================================================

  /// Light theme surface color
  static const Color lightSurface = Colors.white;

  /// Light theme surface container highest
  static const Color lightSurfaceContainerHighest = Color(
    0xFFF5F5F5,
  ); // grey[100]

  /// Light theme on surface color
  static const Color lightOnSurface = Color(0xFF212121); // grey[900]

  /// Light theme on surface variant
  static const Color lightOnSurfaceVariant = Color(0xFF616161); // grey[700]

  /// Light theme outline color
  static const Color lightOutline = Color(0xFFBDBDBD); // grey[400]

  /// Light theme outline variant
  static const Color lightOutlineVariant = Color(0xFFE0E0E0); // grey[300]

  /// Light theme error color
  static const Color lightError = Color(0xFFC62828); // red[700]

  /// Light theme divider color
  static const Color lightDivider = Color(0xFFE0E0E0); // grey[300]

  /// Light theme icon color
  static const Color lightIcon = Color(0xFF424242); // grey[800]

  // ============================================================================
  // DARK THEME COLORS (Reduced contrast for comfortable viewing)
  // ============================================================================

  /// Dark theme surface color (lighter for reduced contrast)
  static const Color darkSurface = Color(0xFF1E1E1E); // softer than #121212

  /// Dark theme surface container highest
  static const Color darkSurfaceContainerHighest = Color(
    0xFF2D2D2D,
  ); // softer than #424242

  /// Dark theme on surface color (darker for reduced contrast)
  static const Color darkOnSurface = Color(0xFFE0E0E0); // softer than #F5F5F5

  /// Dark theme on surface variant
  static const Color darkOnSurfaceVariant = Color(
    0xFFBDBDBD,
  ); // softer than #E0E0E0

  /// Dark theme outline color
  static const Color darkOutline = Color(0xFF5A5A5A); // softer than #757575

  /// Dark theme outline variant
  static const Color darkOutlineVariant = Color(
    0xFF4A4A4A,
  ); // softer than #616161

  /// Dark theme error color (slightly muted)
  static const Color darkError = Color(0xFFE57373); // softer than #EF5350

  /// Dark theme divider color
  static const Color darkDivider = Color(0xFF4A4A4A); // softer than #616161

  /// Dark theme icon color
  static const Color darkIcon = Color(0xFFBDBDBD); // softer than #E0E0E0

  // ============================================================================
  // AMOLED THEME COLORS (Pure black for battery savings on AMOLED screens)
  // ============================================================================

  /// AMOLED theme surface color (pure black)
  static const Color amoledSurface = Color(0xFF000000);

  /// AMOLED theme surface container highest
  static const Color amoledSurfaceContainerHighest = Color(0xFF1A1A1A);

  /// AMOLED theme on surface color
  static const Color amoledOnSurface = Color(0xFFFFFFFF);

  /// AMOLED theme on surface variant
  static const Color amoledOnSurfaceVariant = Color(0xFFE0E0E0);

  /// AMOLED theme outline color
  static const Color amoledOutline = Color(0xFF404040);

  /// AMOLED theme outline variant
  static const Color amoledOutlineVariant = Color(0xFF2A2A2A);

  /// AMOLED theme error color
  static const Color amoledError = Color(0xFFEF5350);

  /// AMOLED theme divider color
  static const Color amoledDivider = Color(0xFF2A2A2A);

  /// AMOLED theme icon color
  static const Color amoledIcon = Color(0xFFFFFFFF);

  // ============================================================================
  // ANIMATION DURATIONS
  // ============================================================================

  /// Short animation duration
  static const Duration animationShort = Duration(milliseconds: 150);

  /// Medium animation duration
  static const Duration animationMedium = Duration(milliseconds: 250);

  /// Long animation duration
  static const Duration animationLong = Duration(milliseconds: 350);

  // ============================================================================
  // APP BAR CONSTANTS
  // ============================================================================

  /// App bar elevation
  static const double appBarElevation = elevationNone;

  /// App bar center title
  static const bool appBarCenterTitle = true;

  // ============================================================================
  // HELPER METHODS
  // ============================================================================

  /// Get text scale factor from font size scale string
  static double getTextScaleFactor(String? fontSizeScale) {
    switch (fontSizeScale) {
      case 'small':
        return textScaleSmall;
      case 'normal':
        return textScaleNormal;
      case 'large':
        return textScaleLarge;
      case 'extra_large':
        return textScaleExtraLarge;
      default:
        return textScaleNormal;
    }
  }

  /// Get spacing value by multiplier
  static double spacing(double multiplier) => spacingUnit * multiplier;
}
