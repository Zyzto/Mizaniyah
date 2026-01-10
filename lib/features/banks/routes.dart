import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/navigation/route_paths.dart';
import 'pages/sms_pattern_page.dart';
import 'pages/sms_pattern_builder_wizard.dart';
import 'pages/sms_reader_page.dart';
import 'pages/sms_template_form_page.dart';
import '../../../core/database/providers/database_provider.dart';
import '../../../core/database/app_database.dart' as db;
import '../../../core/database/daos/sms_template_dao.dart';

/// Bank routes for the application
List<RouteBase> getBankRoutes() {
  return [
    GoRoute(
      path: RoutePaths.smsPatternPage,
      builder: (context, state) => const SmsPatternPage(),
    ),
    GoRoute(
      path: RoutePaths.smsPatternBuilder,
      builder: (context, state) => const SmsPatternBuilderWizard(),
    ),
    GoRoute(
      path: RoutePaths.smsReader,
      builder: (context, state) => const SmsReaderPage(),
    ),
    GoRoute(
      path: RoutePaths.smsTemplateForm,
      builder: (context, state) => const SmsTemplateFormPage(),
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

  const SmsTemplateFormPageLoader({
    super.key,
    required this.templateId,
  });

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
            context.go(RoutePaths.smsPatternPage);
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
