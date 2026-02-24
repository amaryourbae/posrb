class Discount {
  final String id;
  final String name;
  final String code;
  final String type; // 'fixed' or 'percentage'
  final double value;
  final double minPurchase;

  Discount({
    required this.id,
    required this.name,
    required this.code,
    required this.type,
    required this.value,
    this.minPurchase = 0,
  });

  factory Discount.fromJson(Map<String, dynamic> json) {
    return Discount(
      id: json['id'].toString(),
      name: json['name'] ?? '',
      code: json['code'] ?? '',
      type: json['type'] ?? 'fixed',
      value: double.tryParse(json['value'].toString()) ?? 0,
      minPurchase: double.tryParse(json['min_purchase'].toString()) ?? 0,
    );
  }
}
