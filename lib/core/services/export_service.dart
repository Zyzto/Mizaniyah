import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_logging_service/flutter_logging_service.dart';
import 'package:mizaniyah/core/database/app_database.dart' as db;
import 'package:mizaniyah/core/database/daos/transaction_dao.dart';
import 'package:mizaniyah/core/database/daos/budget_dao.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';

/// Export Service
/// Handles exporting data to CSV format
class ExportService with Loggable {
  final TransactionDao _transactionDao;
  final BudgetDao _budgetDao;

  ExportService(this._transactionDao, this._budgetDao);

  /// Export transactions to CSV
  Future<String?> exportTransactionsToCsv({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    logInfo('Exporting transactions to CSV');
    try {
      final transactions = await _transactionDao.getAllTransactions();

      // Filter by date range if provided
      List<db.Transaction> filteredTransactions = transactions;
      if (startDate != null || endDate != null) {
        filteredTransactions = transactions.where((t) {
          if (startDate != null && t.date.isBefore(startDate)) return false;
          if (endDate != null && t.date.isAfter(endDate)) return false;
          return true;
        }).toList();
      }

      // Sort by date (newest first)
      filteredTransactions.sort((a, b) => b.date.compareTo(a.date));

      // Build CSV content
      final csvBuffer = StringBuffer();

      // Header
      csvBuffer.writeln(
        'Date,Store Name,Amount,Currency,Category,Account,Source,Notes',
      );

      // Data rows
      final dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss');
      for (final transaction in filteredTransactions) {
        csvBuffer.writeln(
          [
            dateFormat.format(transaction.date),
            _escapeCsvField(transaction.storeName),
            transaction.amount.toStringAsFixed(2),
            transaction.currencyCode,
            transaction.categoryId?.toString() ?? '',
            transaction.cardId?.toString() ?? '',
            transaction.source,
            _escapeCsvField(transaction.notes ?? ''),
          ].join(','),
        );
      }

      // Save to file
      final file = await _getExportFile('transactions_${_getTimestamp()}.csv');
      await file.writeAsString(csvBuffer.toString());

      logInfo(
        'Exported ${filteredTransactions.length} transactions to ${file.path}',
      );
      return file.path;
    } catch (e, stackTrace) {
      logError(
        'Failed to export transactions to CSV',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  /// Export budgets to CSV
  Future<String?> exportBudgetsToCsv() async {
    logInfo('Exporting budgets to CSV');
    try {
      final budgets = await _budgetDao.getAllBudgets();

      // Build CSV content
      final csvBuffer = StringBuffer();

      // Header
      csvBuffer.writeln(
        'Category ID,Amount,Period,Rollover Enabled,Rollover Percentage,Start Date,Active',
      );

      // Data rows
      final dateFormat = DateFormat('yyyy-MM-dd');
      for (final budget in budgets) {
        csvBuffer.writeln(
          [
            budget.categoryId,
            budget.amount.toStringAsFixed(2),
            budget.period,
            budget.rolloverEnabled ? 'Yes' : 'No',
            budget.rolloverPercentage.toStringAsFixed(2),
            dateFormat.format(budget.startDate),
            budget.isActive ? 'Yes' : 'No',
          ].join(','),
        );
      }

      // Save to file
      final file = await _getExportFile('budgets_${_getTimestamp()}.csv');
      await file.writeAsString(csvBuffer.toString());

      logInfo('Exported ${budgets.length} budgets to ${file.path}');
      return file.path;
    } catch (e, stackTrace) {
      logError(
        'Failed to export budgets to CSV',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  /// Export both transactions and budgets to CSV
  Future<Map<String, String?>> exportAll() async {
    logInfo('Exporting all data to CSV');
    final transactionsPath = await exportTransactionsToCsv();
    final budgetsPath = await exportBudgetsToCsv();

    return {'transactions': transactionsPath, 'budgets': budgetsPath};
  }

  String _escapeCsvField(String field) {
    // Escape quotes and wrap in quotes if contains comma, quote, or newline
    if (field.contains(',') || field.contains('"') || field.contains('\n')) {
      return '"${field.replaceAll('"', '""')}"';
    }
    return field;
  }

  String _getTimestamp() {
    final now = DateTime.now();
    return DateFormat('yyyyMMdd_HHmmss').format(now);
  }

  Future<File> _getExportFile(String filename) async {
    if (kIsWeb) {
      throw UnsupportedError('File export not supported on web');
    }

    final directory = await getApplicationDocumentsDirectory();
    final exportDir = Directory('${directory.path}/exports');
    if (!await exportDir.exists()) {
      await exportDir.create(recursive: true);
    }

    return File('${exportDir.path}/$filename');
  }
}
