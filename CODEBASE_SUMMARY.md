# Mizaniyah Codebase Summary

> **Use this as a starter prompt when working with AI assistants on this project.**

## Project Overview

**Mizaniyah** is a local spending tracker Flutter app with SMS transaction detection (Android only, iOS on hold).

- **Version:** 0.2.0+1
- **SDK:** Flutter/Dart 3.10.0+
- **Platforms:** Android (primary), iOS (on hold)
- **Languages:** English, Arabic (RTL support)

## Tech Stack

| Category | Technology |
|----------|------------|
| State Management | **Riverpod 3.x** with `riverpod_annotation` + `riverpod_generator` |
| Navigation | **go_router** |
| Database | **Drift** (SQLite) with type-safe DAOs |
| Localization | **easy_localization** |
| Settings | **flutter_settings_framework** (custom Git package) |
| Logging | **flutter_logging_service** (custom Git package) |
| SMS Reading | **another_telephony** (Android only) |
| Background Tasks | **workmanager** |
| Notifications | **flutter_local_notifications** |

## Architecture

```
lib/
├── main.dart              # App entry, initialization
├── app.dart               # Root widget with theme/locale/router
├── core/
│   ├── database/          # Drift database, DAOs, models, validators
│   ├── navigation/        # GoRouter setup, app bars, routes
│   ├── services/          # Business logic services
│   ├── theme/             # AppTheme (Material 3)
│   ├── utils/             # Formatters, helpers
│   └── widgets/           # Reusable widgets
└── features/              # Feature modules (see below)
```

## Feature Modules

Each feature follows this structure: `pages/`, `providers/`, `widgets/`, `routes.dart`

| Feature | Description |
|---------|-------------|
| **home** | Dashboard with summary |
| **transactions** | Transaction list, form, detail, filters |
| **accounts** | Bank accounts management |
| **categories** | Spending categories with icons/colors |
| **budgets** | Budget tracking with periods |
| **settings** | App settings (theme, language, SMS options) |
| **sms_management** | SMS template builder/tester |
| **sms_notifications** | SMS inbox viewer, pending confirmations |
| **sms_templates** | Template providers |
| **statistics** | Spending analytics |

## Database Schema (Drift)

**Tables:** `Transactions`, `Accounts`, `Cards`, `Categories`, `Budgets`, `SmsTemplates`, `PendingSmsConfirmations`, `CategoryMappings`, `NotificationHistory`

**Key Transaction Fields:**
```dart
id, amount, currencyCode, storeName, cardId, categoryId, 
budgetId, date, notes, source ('manual'|'sms'), smsHash, createdAt, updatedAt
```

**DAOs:** Each table has a DAO in `core/database/daos/` with CRUD + watch methods.

## Riverpod Patterns

### Provider Types Used
- `@riverpod` functions for simple providers (auto-dispose)
- `@riverpod class` for stateful notifiers
- Direct `StreamProvider` / `FutureProvider.family` for complex `db.*` types (riverpod_generator has issues with Drift types)

### Key Providers
```dart
// Database
databaseProvider, transactionDaoProvider, categoryDaoProvider, etc.

// Settings (convenience providers with error handling)
themeModeProvider, themeColorProvider, fontSizeScaleProvider,
languageSettingProvider, smsDetectionEnabledProvider,
autoConfirmTransactionsProvider, confidenceThresholdProvider

// Feature providers
transactionsProvider, categoriesProvider, accountsProvider,
budgetsProvider, smsListProvider, smsTemplatesProvider
```

### Watching Patterns
```dart
// In widgets
final transactions = ref.watch(transactionsProvider);
transactions.when(data: ..., loading: ..., error: ...);

// Or use helper widget
AsyncValueBuilder(value: transactions, data: (ctx, data) => ...)
```

## Settings System

Uses `flutter_settings_framework` with definitions in `settings_definitions.dart`:

**Sections:** General, Appearance, SMS, Currency

**Key Settings:**
- `themeModeSettingDef` (system/light/dark)
- `themeColorSettingDef` (Color picker)
- `languageSettingDef` (en/ar)
- `fontSizeScaleSettingDef` (small/normal/large/extra_large)
- `smsDetectionEnabledSettingDef` (bool)
- `autoConfirmTransactionsSettingDef` (bool)
- `confidenceThresholdSettingDef` (0.5-1.0)
- `defaultCurrencySettingDef` (USD, EUR, etc.)

## SMS Detection Flow

1. `SmsDetectionService` listens for incoming SMS (Android)
2. `SmsMatcher` matches SMS against `SmsTemplates`
3. If matched, extracts amount/store via regex patterns
4. Creates `PendingSmsConfirmation` or auto-creates transaction
5. User confirms/edits in `sms_notifications` feature

## Navigation

**Bottom Nav:** Home/Transactions, Accounts, Budgets  
**Form pages:** Full-screen (outside ShellRoute)  
**Main pages:** Inside ShellRoute with `MainScaffold`

## Important Conventions

1. **Imports:** Use `import 'package:mizaniyah/...'` (absolute)
2. **Providers:** Use `@riverpod` annotation when possible, fall back to direct for `db.*` types
3. **Async UI:** Use `AsyncValueBuilder` or `.when()` pattern
4. **Logging:** Use `Log.debug()`, `Log.info()`, `Log.error()` from `flutter_logging_service`
5. **Translations:** All user-facing strings via `'key'.tr()` from easy_localization
6. **Theme:** Material 3 with dynamic color from seed

## Code Generation

Run after changing annotated code:
```bash
dart run build_runner build --delete-conflicting-outputs
```

Generated files: `*.g.dart` (Riverpod, Drift)

## Quick Reference

```dart
// Read database
final db = ref.watch(databaseProvider);
final dao = ref.watch(transactionDaoProvider);

// Watch stream data
final transactions = ref.watch(transactionsProvider);

// Update settings
ref.read(settings.provider(themeModeSettingDef).notifier).set('dark');

// Navigate
context.go(RoutePaths.transactions);
context.push(RoutePaths.transactionForm);

// Show translated text
Text('title'.tr())

// Format currency
CurrencyFormatter.format(amount, currencyCode)
```

---

*Last updated: January 2026*
