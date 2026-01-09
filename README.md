# Mizaniyah

A spending tracker app with SMS transaction detection (Android only, iOS on hold).

## Features

### Core Functionality
- **Transaction Tracking**: Track all your spending with detailed transaction records
- **Category-Based Budgets**: Set monthly budgets per category with rollover options
- **SMS Auto-Detection**: Automatically detect transactions from bank SMS messages
- **Smart Auto-Create**: High-confidence SMS transactions are automatically created
- **Multi-Currency Support**: Auto-detect currency from SMS or manually set

### Navigation
- **Home Tab**: View all transactions with budget status, filter by category, search
- **Accounts/Budget Tab**: Manage accounts and budgets in one place
- **SMS/Notifications Tab**: Review pending confirmations, all SMS, and notifications

### Budget Management
- Category-based monthly budgets
- Color-coded status indicators (green/yellow/red)
- Rollover settings (enabled/disabled, percentage)
- Budget vs actual spending comparisons
- Progress indicators and remaining amount display

### SMS Processing
- Pattern-based SMS parsing
- Confidence scoring for transaction detection
- Smart auto-create for high-confidence matches (>= 0.7)
- Manual confirmation for lower confidence matches
- SMS pattern builder and tester

### Additional Features
- **Statistics & Analytics**: Monthly summaries, spending by category, budget comparisons
- **CSV Export**: Export transactions and budgets to CSV files
- **Multi-Language**: English and Arabic support
- **Theme Selection**: Light, dark, or system theme
- **Predefined Categories**: 12 common spending categories pre-seeded

## Architecture

### Database
- **Drift** (SQLite) for local data storage
- Schema version 2 with fresh start migration
- Models: Transactions, Budgets, Categories, Banks, Cards, SMS Templates, Pending SMS

### State Management
- **Riverpod** for state management
- Stream providers for reactive data updates

### Services
- Budget Service: Calculations, remaining amounts, rollover logic
- SMS Detection Service: Real-time SMS monitoring and parsing
- SMS Parsing Service: Pattern matching with confidence scoring
- Export Service: CSV export functionality
- Category Seeder: Predefined categories initialization

## Getting Started

1. Clone the repository
2. Run `flutter pub get`
3. Run `dart run build_runner build` to generate database code
4. Run the app on an Android device/emulator

## Project Structure

```
lib/
├── core/
│   ├── database/          # Database models, DAOs, connection
│   ├── services/          # Core business logic services
│   ├── theme/             # App theming
│   └── widgets/            # Reusable widgets
├── features/
│   ├── accounts/          # Accounts and budgets management
│   ├── banks/             # Bank and SMS template management
│   ├── budgets/           # Budget-specific logic
│   ├── categories/        # Category management
│   ├── sms_notifications/ # SMS and notification handling
│   ├── statistics/        # Analytics and statistics
│   └── transactions/     # Transaction management
└── main.dart              # App entry point
```

## Requirements

- Flutter SDK ^3.10.0
- Android device/emulator (iOS support on hold)
- SMS permissions (for SMS detection feature)

## License

This project is licensed under the Creative Commons Attribution-NonCommercial 4.0 International License.

To view a copy of this license, visit https://creativecommons.org/licenses/by-nc/4.0/ or see the [LICENSE](LICENSE) file in the root directory.
