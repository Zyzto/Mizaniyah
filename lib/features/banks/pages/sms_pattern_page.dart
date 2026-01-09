import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import '../providers/bank_providers.dart';
import 'package:mizaniyah/core/database/app_database.dart' as db;
import 'sms_template_form_page.dart';

class SmsPatternPage extends ConsumerStatefulWidget {
  const SmsPatternPage({super.key});

  @override
  ConsumerState<SmsPatternPage> createState() => _SmsPatternPageState();
}

class _SmsPatternPageState extends ConsumerState<SmsPatternPage> {
  @override
  Widget build(BuildContext context) {
    final banksAsync = ref.watch(banksProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('SMS Patterns'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Patterns', icon: Icon(Icons.pattern_outlined)),
              Tab(text: 'Test Pattern', icon: Icon(Icons.bug_report_outlined)),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Patterns List
            banksAsync.when(
              data: (banks) {
                if (banks.isEmpty) {
                  return const Center(
                    child: Text('Add a bank first to create SMS patterns'),
                  );
                }

                // Show templates grouped by bank
                return ListView.builder(
                  itemCount: banks.length,
                  itemBuilder: (context, index) {
                    final bank = banks[index];
                    return FutureBuilder<List<db.SmsTemplate>>(
                      future: ref.read(smsTemplatesProvider(bank.id).future),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const ListTile(
                            leading: CircularProgressIndicator(),
                            title: Text('Loading templates...'),
                          );
                        }

                        final templates = snapshot.data ?? [];
                        if (templates.isEmpty) {
                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: ListTile(
                              leading: const Icon(Icons.message),
                              title: Text(bank.name),
                              subtitle: const Text('No templates configured'),
                              trailing: IconButton(
                                icon: const Icon(Icons.add),
                                onPressed: () =>
                                    _navigateToAddTemplate(bank.id),
                              ),
                            ),
                          );
                        }

                        return ExpansionTile(
                          leading: const Icon(Icons.account_balance),
                          title: Text(bank.name),
                          subtitle: Text('${templates.length} template(s)'),
                          children: templates.map((template) {
                            return ListTile(
                              leading: const Icon(Icons.message),
                              title: Text(
                                template.pattern.length > 50
                                    ? '${template.pattern.substring(0, 50)}...'
                                    : template.pattern,
                              ),
                              subtitle: Text('Priority: ${template.priority}'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Switch(
                                    value: template.isActive,
                                    onChanged: (value) =>
                                        _toggleTemplateActive(template, value),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.edit),
                                    onPressed: () =>
                                        _navigateToEditTemplate(template),
                                  ),
                                ],
                              ),
                              onTap: () => _navigateToEditTemplate(template),
                            );
                          }).toList(),
                        );
                      },
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(child: Text('Error: $error')),
            ),
            // Pattern Tester
            const _PatternTesterPlaceholder(),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            final banksAsync = ref.read(banksProvider);
            banksAsync.whenData((banks) {
              if (banks.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Add a bank first')),
                );
                return;
              }
              // Navigate to first bank's template form, or show bank selector
              _navigateToAddTemplate(banks.first.id);
            });
          },
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  void _navigateToAddTemplate(int bankId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SmsTemplateFormPage(bankId: bankId),
      ),
    );
  }

  void _navigateToEditTemplate(db.SmsTemplate template) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SmsTemplateFormPage(template: template),
      ),
    );
  }

  Future<void> _toggleTemplateActive(
    db.SmsTemplate template,
    bool value,
  ) async {
    try {
      final repository = ref.read(bankRepositoryProvider);
      await repository.updateTemplate(
        db.SmsTemplatesCompanion(
          id: drift.Value(template.id),
          isActive: drift.Value(value),
        ),
      );
    } catch (e) {
      // Error handling is done by the repository
    }
  }
}

class _PatternTesterPlaceholder extends StatelessWidget {
  const _PatternTesterPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bug_report_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text('Pattern Tester', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            'Select a pattern from the Patterns tab to test it',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
