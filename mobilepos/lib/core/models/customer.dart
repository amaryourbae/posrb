class Customer {
  final String id;
  final String name;
  final String? phone;
  final int pointsBalance;
  final bool isGuest;

  Customer({
    required this.id,
    required this.name,
    this.phone,
    this.pointsBalance = 0,
    this.isGuest = false,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'].toString(),
      name: json['name'],
      phone: json['phone'],
      pointsBalance: json['points_balance'] ?? 0,
    );
  }

  // Helper for Guest
  factory Customer.guest(String name) {
    return Customer(
      id: '', // Empty ID for guest
      name: name,
      isGuest: true,
    );
  }
}
