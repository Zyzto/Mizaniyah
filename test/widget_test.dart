// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:mizaniyah/app.dart';
import 'package:mizaniyah/features/settings/providers/settings_framework_providers.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Initialize EasyLocalization for testing
    await EasyLocalization.ensureInitialized();

    // Create mock settings providers using in-memory storage
    final mockSettingsProviders = await initializeMizaniyahSettings();

    // Build our app with proper providers
    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: const [Locale('en'), Locale('ar')],
        path: 'assets/translations',
        fallbackLocale: const Locale('en'),
        child: ProviderScope(
          overrides: [
            mizaniyahSettingsControllerProvider.overrideWithValue(
              mockSettingsProviders.controller,
            ),
            mizaniyahSettingsSearchIndexProvider.overrideWithValue(
              mockSettingsProviders.searchIndex,
            ),
            mizaniyahSettingsProvider.overrideWithValue(mockSettingsProviders),
          ],
          child: const App(),
        ),
      ),
    );

    // Wait for async initialization
    await tester.pumpAndSettle();

    // Verify that the app builds without errors
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
