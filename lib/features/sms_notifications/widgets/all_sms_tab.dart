import 'package:flutter/material.dart';
import '../../banks/pages/sms_reader_page.dart';

/// All SMS tab - reuses the existing SMS reader page
class AllSmsTab extends StatelessWidget {
  const AllSmsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const SmsReaderPage();
  }
}
