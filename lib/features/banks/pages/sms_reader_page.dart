import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:another_telephony/telephony.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/services/sms_reader_service.dart';
import '../../../core/database/providers/dao_providers.dart';
import '../widgets/sms_list_item.dart';
import '../../../core/widgets/error_snackbar.dart';
import '../../../core/widgets/empty_state.dart';

class SmsReaderPage extends ConsumerStatefulWidget {
  final String? initialSender;
  final String? initialBody;

  const SmsReaderPage({
    super.key,
    this.initialSender,
    this.initialBody,
  });

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
  final TextEditingController _searchController = TextEditingController();
  int _loadedCount = 0;
  static const _pageSize = 50;

  @override
  void initState() {
    super.initState();
    // Set initial search query if provided
    if (widget.initialSender != null) {
      _searchQuery = widget.initialSender!;
      _searchController.text = widget.initialSender!;
    } else if (widget.initialBody != null) {
      _searchQuery = widget.initialBody!;
      _searchController.text = widget.initialBody!;
    }
    _loadSms();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
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
        final smsTemplateDao = ref.read(smsTemplateDaoProvider);
        sms = await _smsReaderService.filterSmsByTemplates(
          smsTemplateDao,
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
      if (!mounted || !context.mounted) return;
      HapticFeedback.heavyImpact();
      ErrorSnackbar.show(context, 'sms_load_failed'.tr(args: [e.toString()]));
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
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'search_sms_hint'.tr(),
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          tooltip: 'clear_search'.tr(),
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            setState(() {
                              _searchQuery = '';
                              _searchController.clear();
                            });
                          },
                        )
                      : null,
                ),
                textInputAction: TextInputAction.search,
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Checkbox(
                    value: _showBankSmsOnly,
                    onChanged: (value) {
                      HapticFeedback.lightImpact();
                      setState(() {
                        _showBankSmsOnly = value ?? false;
                        _loadedCount = 0;
                        _smsList = [];
                      });
                      _loadSms(refresh: true);
                    },
                  ),
                  Text('show_bank_sms_only'.tr()),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    tooltip: 'refresh'.tr(),
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      _loadSms(refresh: true);
                    },
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
              ? EmptyState(
                  icon: Icons.sms_outlined,
                  title: _searchQuery.isNotEmpty
                      ? 'no_sms_matching'.tr(args: [_searchQuery])
                      : 'no_sms_messages'.tr(),
                  subtitle: _searchQuery.isNotEmpty
                      ? null
                      : 'no_sms_messages_description'.tr(),
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
                          HapticFeedback.lightImpact();
                          // Navigate to SMS Template page
                          context.push('/banks/sms-template');
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
