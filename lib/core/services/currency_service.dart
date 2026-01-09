import 'package:flutter_logging_service/flutter_logging_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// Currency Service
/// Manages currency exchange rates and conversions
class CurrencyService with Loggable {
  static CurrencyService? _instance;
  static CurrencyService get instance {
    _instance ??= CurrencyService._();
    return _instance!;
  }

  CurrencyService._();

  static const String _exchangeRatesKey = 'currency_exchange_rates';
  static const String _defaultCurrencyKey = 'default_currency';

  /// Get exchange rate from base currency to target currency
  Future<double?> getExchangeRate(
    String fromCurrency,
    String toCurrency,
  ) async {
    if (fromCurrency == toCurrency) {
      return 1.0;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final ratesJson = prefs.getString(_exchangeRatesKey);
      if (ratesJson == null) {
        logWarning('No exchange rates stored');
        return null;
      }

      final rates = jsonDecode(ratesJson) as Map<String, dynamic>;
      final rateKey = '${fromCurrency}_$toCurrency';
      final rate = rates[rateKey] as double?;

      if (rate == null) {
        logWarning('Exchange rate not found for $rateKey');
        return null;
      }

      return rate;
    } catch (e, stackTrace) {
      logError(
        'Failed to get exchange rate from $fromCurrency to $toCurrency',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  /// Set exchange rate
  Future<void> setExchangeRate(
    String fromCurrency,
    String toCurrency,
    double rate,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ratesJson = prefs.getString(_exchangeRatesKey);
      final rates = ratesJson != null
          ? jsonDecode(ratesJson) as Map<String, dynamic>
          : <String, dynamic>{};

      rates['${fromCurrency}_$toCurrency'] = rate;
      // Also store reverse rate
      rates['${toCurrency}_$fromCurrency'] = 1.0 / rate;

      await prefs.setString(_exchangeRatesKey, jsonEncode(rates));
      logInfo('Set exchange rate: $fromCurrency -> $toCurrency = $rate');
    } catch (e, stackTrace) {
      logError('Failed to set exchange rate', error: e, stackTrace: stackTrace);
    }
  }

  /// Convert amount from one currency to another
  Future<double?> convert(
    double amount,
    String fromCurrency,
    String toCurrency,
  ) async {
    final rate = await getExchangeRate(fromCurrency, toCurrency);
    if (rate == null) {
      return null;
    }
    return amount * rate;
  }

  /// Get default currency
  Future<String> getDefaultCurrency() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_defaultCurrencyKey) ?? 'USD';
    } catch (e) {
      logError('Failed to get default currency', error: e);
      return 'USD';
    }
  }

  /// Set default currency
  Future<void> setDefaultCurrency(String currency) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_defaultCurrencyKey, currency);
      logInfo('Set default currency to $currency');
    } catch (e, stackTrace) {
      logError(
        'Failed to set default currency',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Get list of supported currencies
  static List<Currency> getSupportedCurrencies() {
    return [
      Currency(code: 'USD', name: 'US Dollar'),
      Currency(code: 'EUR', name: 'Euro'),
      Currency(code: 'GBP', name: 'British Pound'),
      Currency(code: 'JPY', name: 'Japanese Yen'),
      Currency(code: 'AUD', name: 'Australian Dollar'),
      Currency(code: 'CAD', name: 'Canadian Dollar'),
      Currency(code: 'CHF', name: 'Swiss Franc'),
      Currency(code: 'CNY', name: 'Chinese Yuan'),
      Currency(code: 'INR', name: 'Indian Rupee'),
      Currency(code: 'SGD', name: 'Singapore Dollar'),
      Currency(code: 'AED', name: 'UAE Dirham'),
      Currency(code: 'SAR', name: 'Saudi Riyal'),
      Currency(code: 'EGP', name: 'Egyptian Pound'),
    ];
  }
}

/// Currency model
class Currency {
  final String code;
  final String name;

  Currency({required this.code, required this.name});
}
