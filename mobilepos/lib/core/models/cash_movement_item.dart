class CashMovementItem {
  final String id;
  final String type; // pay_in, pay_out, drop
  final double amount;
  final String? reason;
  final DateTime createdAt;

  CashMovementItem({
    required this.id,
    required this.type,
    required this.amount,
    this.reason,
    required this.createdAt,
  });

  factory CashMovementItem.fromJson(Map<String, dynamic> json) {
    return CashMovementItem(
      id: json['id']?.toString() ?? '',
      type: json['type'] ?? '',
      amount: double.tryParse(json['amount']?.toString() ?? '0') ?? 0,
      reason: json['reason'],
      createdAt: DateTime.parse(
        json['created_at'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  String get typeLabel {
    switch (type) {
      case 'pay_in':
        return 'Pay In';
      case 'pay_out':
        return 'Pay Out';
      case 'drop':
        return 'Drop';
      default:
        return type;
    }
  }
}
