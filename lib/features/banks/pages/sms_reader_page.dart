import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:another_telephony/telephony.dart';
import '../../../core/services/sms_reader_service.dart';
import '../providers/bank_providers.dart';
import '../widgets/sms_list_item.dart';
import 'sms_pattern_page.dart';
import '../../../core/widgets/error_snackbar.dart';

class SmsReaderPage extends ConsumerStatefulWidget {
  const SmsReaderPage({super.key});

  @override
  ConsumerState<SmsReaderPage> createState() => _SmsReaderPageState();
}

class _SmsReaderPageState extends ConsumerState<SmsReaderPage> {
  final SmsReaderService _smsReaderService = SmsReaderService.instance;
  List<SmsMessage> _smsList = [];
  bool _isLoading = false;
  String _searchQuery = '';
  bool _showBankSmsOnly = false;
  final ScrollController _scrollController = ScrollController();
  int _loadedCount = 0;
  static const _pageSize = 50;

  @override
  void initState() {
    super.initState();
    _loadSms();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      _loadMoreSms();
    }
  }

  Future<void> _loadSms({bool refresh = false}) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      if (refresh) {
        _loadedCount = 0;
        _smsList = [];
        _smsReaderService.clearCache();
      }
    });

    try {
      await _smsReaderService.init();
      List<SmsMessage> sms;

      if (_showBankSmsOnly) {
        final bankRepository = ref.read(bankRepositoryProvider);
        sms = await _smsReaderService.filterBankSms(
          bankRepository,
          limit: _pageSize,
          offset: _loadedCount,
        );
      } else {
        sms = await _smsReaderService.getInboxSms(
          limit: _pageSize,
          offset: _loadedCount,
          forceRefresh: refresh,
        );
      }

      setState(() {
        _smsList.addAll(sms);
        _loadedCount += sms.length;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ErrorSnackbar.show(context, 'Failed to load SMS: $e');
      }
    }
  }

  Future<void> _loadMoreSms() async {
    if (_isLoading || _smsList.isEmpty) return;
    await _loadSms();
  }

  List<SmsMessage> _getFilteredSms() {
    if (_searchQuery.isEmpty) {
      return _smsList;
    }

    final query = _searchQuery.toLowerCase();
    return _smsList.where((sms) {
      final address = sms.address?.toLowerCase() ?? '';
      final body = sms.body?.toLowerCase() ?? '';
      return address.contains(query) || body.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filteredSms = _getFilteredSms();

    return Column(
      children: [
        // Search and filter bar
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              TextField(
                decoration: InputDecoration(
                  hintText: 'Search SMS by sender or content...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            setState(() {
                              _searchQuery = '';
                            });
                          },
                        )
                      : null,
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Checkbox(
                    value: _showBankSmsOnly,
                    onChanged: (value) {
                      setState(() {
                        _showBankSmsOnly = value ?? false;
                        _loadedCount = 0;
                        _smsList = [];
                      });
                      _loadSms(refresh: true);
                    },
                  ),
                  const Text('Show bank SMS only'),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: () => _loadSms(refresh: true),
                    tooltip: 'Refresh',
                  ),
                ],
              ),
            ],
          ),
        ),
        // SMS List
        Expanded(
          child: _isLoading && _smsList.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : filteredSms.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.sms_outlined,
                        size: 64,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _searchQuery.isNotEmpty
                            ? 'No SMS found matching "$_searchQuery"'
                            : 'No SMS messages found',
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () => _loadSms(refresh: true),
                  child: ListView.builder(
                    controller: _scrollController,
                    itemCount: filteredSms.length + (_isLoading ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index >= filteredSms.length) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }

                      final sms = filteredSms[index];
                      return SmsListItem(
                        sms: sms,
                        onTap: () {
                          // Navigate to SMS Pattern page
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const SmsPatternPage(),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }
}
