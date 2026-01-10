import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/navigation/route_paths.dart';
import 'pages/sms_template_page.dart';
import 'pages/sms_template_builder_wizard.dart';
import 'pages/sms_reader_page.dart';
import 'pages/sms_template_form_page.dart';
import '../../../core/database/providers/database_provider.dart';
import '../../../core/database/app_database.dart' as db;
import '../../../core/database/daos/sms_template_dao.dart';

/// Bank routes for the application
List<RouteBase> getBankRoutes() {
  return [
    GoRoute(
      path: RoutePaths.smsTemplatePage,
      builder: (context, state) => const SmsTemplatePage(),
    ),
    GoRoute(
      path: RoutePaths.smsTemplateBuilder,
      builder: (context, state) {
        String? decodedSms;
        try {
          final initialSms = state.uri.queryParameters['initialSms'];
          if (initialSms != null) {
            // Try to decode, but handle errors gracefully
            try {
              decodedSms = Uri.decodeComponent(initialSms);
            } on ArgumentError {
              // If decoding fails due to invalid encoding, use the original value
              decodedSms = initialSms;
            } catch (e) {
              // For any other error, use the original value
              decodedSms = initialSms;
            }
          }
        } catch (e) {
          // If URI parsing itself fails, just use null
          decodedSms = null;
        }
        return SmsTemplateBuilderWizard(initialSms: decodedSms);
      },
    ),
    GoRoute(
      path: RoutePaths.smsReader,
      builder: (context, state) => SmsReaderPage(
        initialSender: state.uri.queryParameters['sender'],
        initialBody: state.uri.queryParameters['body'],
      ),
    ),
    GoRoute(
      path: RoutePaths.smsTemplateForm,
      builder: (context, state) {
        String? decodedSms;
        String? decodedSender;
        try {
          final initialSms = state.uri.queryParameters['initialSms'];
          if (initialSms != null) {
            try {
              decodedSms = Uri.decodeComponent(initialSms);
            } on ArgumentError {
              decodedSms = initialSms;
            } catch (e) {
              decodedSms = initialSms;
            }
          }
          final initialSender = state.uri.queryParameters['initialSender'];
          if (initialSender != null) {
            try {
              decodedSender = Uri.decodeComponent(initialSender);
            } on ArgumentError {
              decodedSender = initialSender;
            } catch (e) {
              decodedSender = initialSender;
            }
          }
        } catch (e) {
          decodedSms = null;
          decodedSender = null;
        }
        return SmsTemplateFormPage(
          initialSms: decodedSms,
          initialSender: decodedSender,
        );
      },
    ),
    GoRoute(
      path: '/banks/sms-template/:id/edit',
      builder: (context, state) {
        final id = int.tryParse(state.pathParameters['id'] ?? '');
        if (id == null) {
          return const SmsTemplateFormPage();
        }
        return SmsTemplateFormPageLoader(templateId: id);
      },
    ),
  ];
}

/// Loader widget for SMS template form page (edit mode)
class SmsTemplateFormPageLoader extends StatelessWidget {
  final int templateId;

  const SmsTemplateFormPageLoader({super.key, required this.templateId});

  @override
  Widget build(BuildContext context) {
    final database = getDatabase();
    final dao = SmsTemplateDao(database);

    return FutureBuilder<db.SmsTemplate?>(
      future: dao.getTemplateById(templateId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final template = snapshot.data;
        if (template == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            context.go(RoutePaths.smsTemplatePage);
          });
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return SmsTemplateFormPage(template: template);
      },
    );
  }
}
