class Order {
  final String id;
  final String orderNumber;
  final String status;
  final double totalPrice;
  final String? customerName;
  final String? customerPhone;
  final String? orderType;
  final double? subtotal;
  final double? discountAmount;
  final double? taxAmount;
  final double? serviceCharge;
  final String paymentMethod;
  final DateTime createdAt;
  final List<dynamic> items;

  Order({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.totalPrice,
    this.customerName,
    this.customerPhone,
    this.orderType,
    this.subtotal,
    this.discountAmount,
    this.taxAmount,
    this.serviceCharge,
    required this.paymentMethod,
    required this.createdAt,
    this.items = const [],
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id']?.toString() ?? '',
      orderNumber: json['order_number'] ?? '',
      status:
          json['status'] ??
          (json['payment_status'] == 'paid' ? 'completed' : 'pending'),
      totalPrice:
          double.tryParse(
            json['total_price']?.toString() ??
                json['grand_total']?.toString() ??
                '',
          ) ??
          0,
      customerName: json['customer_name'] ?? json['customer']?['name'],
      customerPhone: json['customer_phone'] ?? json['customer']?['phone'],
      orderType: json['order_type'],
      subtotal: double.tryParse(json['subtotal']?.toString() ?? '0'),
      discountAmount: double.tryParse(
        json['discount_amount']?.toString() ?? '0',
      ),
      taxAmount: double.tryParse(json['tax_amount']?.toString() ?? '0'),
      serviceCharge: double.tryParse(json['service_charge']?.toString() ?? '0'),
      paymentMethod: json['payment_method'] ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      items: json['items'] as List<dynamic>? ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_number': orderNumber,
      'status': status,
      'total_price': totalPrice,
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'order_type': orderType,
      'subtotal': subtotal,
      'discount_amount': discountAmount,
      'tax_amount': taxAmount,
      'service_charge': serviceCharge,
      'payment_method': paymentMethod,
      'created_at': createdAt.toIso8601String(),
      'items': items,
    };
  }
}
