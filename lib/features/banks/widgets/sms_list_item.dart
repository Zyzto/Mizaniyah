import 'package:flutter/material.dart';
import 'package:another_telephony/telephony.dart';
import 'package:intl/intl.dart';

class SmsListItem extends StatelessWidget {
  final SmsMessage sms;
  final VoidCallback? onTap;

  const SmsListItem({super.key, required this.sms, this.onTap});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy HH:mm');
    final date = sms.date != null
        ? DateTime.fromMillisecondsSinceEpoch(sms.date!)
        : DateTime.now();
    final bodyPreview = sms.body != null && sms.body!.length > 100
        ? '${sms.body!.substring(0, 100)}...'
        : sms.body ?? '';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.sms, size: 20)),
        title: Text(
          sms.address ?? 'Unknown',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(bodyPreview),
            const SizedBox(height: 4),
            Text(
              dateFormat.format(date),
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
