import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:another_telephony/telephony.dart';
import 'package:easy_localization/easy_localization.dart';

class SmsListItem extends StatelessWidget {
  final SmsMessage sms;
  final VoidCallback? onTap;

  const SmsListItem({super.key, required this.sms, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final dateFormat = DateFormat('MMM dd, yyyy HH:mm');
    final date = sms.date != null
        ? DateTime.fromMillisecondsSinceEpoch(sms.date!)
        : DateTime.now();
    final bodyPreview = sms.body != null && sms.body!.length > 100
        ? '${sms.body!.substring(0, 100)}...'
        : sms.body ?? '';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: colorScheme.primaryContainer,
          child: Icon(
            Icons.sms,
            size: 20,
            color: colorScheme.onPrimaryContainer,
          ),
        ),
        title: Text(
          sms.address ?? 'unknown'.tr(),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text(bodyPreview),
            const SizedBox(height: 8),
            Text(
              dateFormat.format(date),
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: colorScheme.onSurfaceVariant,
        ),
        onTap: () {
          HapticFeedback.lightImpact();
          onTap?.call();
        },
      ),
    );
  }
}
