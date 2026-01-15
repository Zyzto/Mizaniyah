/// Represents a notification that was queued during quiet hours
class QueuedNotification {
  final int confirmationId;
  final String storeName;
  final double amount;
  final String currency;
  final DateTime queuedAt;

  QueuedNotification({
    required this.confirmationId,
    required this.storeName,
    required this.amount,
    required this.currency,
    required this.queuedAt,
  });

  Map<String, dynamic> toJson() => {
    'confirmation_id': confirmationId,
    'store_name': storeName,
    'amount': amount,
    'currency': currency,
    'queued_at': queuedAt.toIso8601String(),
  };

  factory QueuedNotification.fromJson(Map<String, dynamic> json) =>
      QueuedNotification(
        confirmationId: json['confirmation_id'] as int,
        storeName: json['store_name'] as String,
        amount: (json['amount'] as num).toDouble(),
        currency: json['currency'] as String,
        queuedAt: DateTime.parse(json['queued_at'] as String),
      );
}
