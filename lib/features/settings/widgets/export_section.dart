import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_settings_framework/flutter_settings_framework.dart'
    show SettingsSectionWidget;
import '../../../core/services/providers/export_providers.dart';
import '../../../core/widgets/error_snackbar.dart';

/// Export section widget for settings page
class ExportSection {
  const ExportSection._();

  static SettingsSectionWidget buildSection(BuildContext context, WidgetRef ref) {
    return SettingsSectionWidget(
      title: 'export'.tr(),
      icon: Icons.file_download,
      children: [
        ListTile(
          leading: const Icon(Icons.file_download),
          title: Text('export_transactions'.tr()),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            HapticFeedback.lightImpact();
            _exportTransactions(context, ref);
          },
        ),
        ListTile(
          leading: const Icon(Icons.download),
          title: Text('export_all'.tr()),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            HapticFeedback.lightImpact();
            _exportAll(context, ref);
          },
        ),
      ],
    );
  }

  static Future<void> _exportTransactions(BuildContext context, WidgetRef ref) async {
    try {
      final exportService = ref.read(exportServiceProvider);
      final filePath = await exportService.exportTransactionsToCsv();

      if (!context.mounted) return;
      if (filePath != null) {
        ErrorSnackbar.showSuccess(context, 'exported_successfully'.tr());
      } else {
        ErrorSnackbar.show(context, 'export_failed'.tr());
      }
    } catch (e) {
      if (!context.mounted) return;
      ErrorSnackbar.show(context, 'export_failed'.tr());
    }
  }

  static Future<void> _exportAll(BuildContext context, WidgetRef ref) async {
    try {
      final exportService = ref.read(exportServiceProvider);
      final results = await exportService.exportAll();

      if (!context.mounted) return;
      final transactionsPath = results['transactions'];
      final budgetsPath = results['budgets'];

      if (transactionsPath != null || budgetsPath != null) {
        ErrorSnackbar.showSuccess(context, 'exported_successfully'.tr());
      } else {
        ErrorSnackbar.show(context, 'export_failed'.tr());
      }
    } catch (e) {
      if (!context.mounted) return;
      ErrorSnackbar.show(context, 'export_failed'.tr());
    }
  }
}
