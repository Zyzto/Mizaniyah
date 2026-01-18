/// Central theming system for Mizaniyah app.
/// 
/// This barrel file exports all theme-related classes and utilities.
/// 
/// Usage:
/// ```dart
/// import 'package:mizaniyah/core/theme/theme.dart';
/// 
/// // Access theme config constants
/// final spacing = ThemeConfig.spacingM;
/// 
/// // Create themes
/// final lightTheme = AppTheme.lightTheme(seedColor: Colors.blue);
/// 
/// // Access theme extensions
/// final appTheme = context.appTheme;
/// final spacing = appTheme?.spacingM ?? ThemeConfig.spacingM;
/// ```
library;

export 'theme_config.dart';
export 'app_theme.dart';
export 'theme_extensions.dart';
export 'app_scroll_behavior.dart';
