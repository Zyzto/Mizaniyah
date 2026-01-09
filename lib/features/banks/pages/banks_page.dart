import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import '../providers/bank_providers.dart';
import 'package:mizaniyah/core/database/app_database.dart' as db;
import 'sms_reader_page.dart';
import 'bank_form_page.dart';
import 'sms_template_form_page.dart';

class BanksPage extends ConsumerStatefulWidget {
  const BanksPage({super.key});

  @override
  ConsumerState<BanksPage> createState() => _BanksPageState();
}

class _BanksPageState extends ConsumerState<BanksPage> {
  @override
  Widget build(BuildContext context) {
    final banksAsync = ref.watch(banksProvider);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Banks & SMS Templates'),
          automaticallyImplyLeading: false,
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Banks', icon: Icon(Icons.account_balance)),
              Tab(text: 'SMS Templates', icon: Icon(Icons.message)),
              Tab(text: 'SMS Reader', icon: Icon(Icons.sms)),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Banks Tab
            banksAsync.when(
              data: (banks) {
                if (banks.isEmpty) {
                  return const Center(child: Text('No banks configured yet'));
                }

                return ListView.builder(
                  itemCount: banks.length,
                  itemBuilder: (context, index) {
                    final bank = banks[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: ListTile(
                        leading: const Icon(Icons.account_balance),
                        title: Text(bank.name),
                        subtitle: Text(
                          bank.smsSenderPattern ?? 'No sender pattern',
                        ),
                        trailing: Switch(
                          value: bank.isActive,
                          onChanged: (value) => _toggleBankActive(bank, value),
                        ),
                        onTap: () => _navigateToEditBank(bank),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(child: Text('Error: $error')),
            ),
            // SMS Templates Tab
            banksAsync.when(
              data: (banks) {
                if (banks.isEmpty) {
                  return const Center(
                    child: Text('Add a bank first to create SMS templates'),
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
                              trailing: Switch(
                                value: template.isActive,
                                onChanged: (value) =>
                                    _toggleTemplateActive(template, value),
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
            // SMS Reader Tab
            const SmsReaderPage(),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _navigateToAddBank,
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  void _navigateToAddBank() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const BankFormPage()));
  }

  void _navigateToEditBank(db.Bank bank) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => BankFormPage(bank: bank)));
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

  Future<void> _toggleBankActive(db.Bank bank, bool value) async {
    try {
      final repository = ref.read(bankRepositoryProvider);
      await repository.updateBank(
        db.BanksCompanion(
          id: drift.Value(bank.id),
          isActive: drift.Value(value),
        ),
      );
    } catch (e) {
      // Error handling is done by the repository
    }
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
