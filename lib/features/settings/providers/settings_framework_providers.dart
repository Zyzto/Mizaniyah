import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_settings_framework/flutter_settings_framework.dart';
import '../settings_definitions.dart';

/// Provider for Mizaniyah settings controller
final mizaniyahSettingsControllerProvider = Provider<SettingsController>((ref) {
  throw UnimplementedError('Settings controller must be overridden');
});

/// Provider for Mizaniyah settings search index
final mizaniyahSettingsSearchIndexProvider = Provider<SearchIndex>((ref) {
  throw UnimplementedError('Settings search index must be overridden');
});

/// Provider for Mizaniyah settings
final mizaniyahSettingsProvider = Provider<SettingsProviders>((ref) {
  throw UnimplementedError('Settings providers must be overridden');
});

/// Initialize the Mizaniyah settings framework.
Future<SettingsProviders> initializeMizaniyahSettings() async {
  try {
    final registry = createMizaniyahSettingsRegistry();
    final storage = SharedPreferencesStorage();

    return await initializeSettings(registry: registry, storage: storage);
  } catch (e) {
    // Re-throw with more context
    throw Exception(
      'Failed to initialize settings framework: $e',
    );
  }
}
