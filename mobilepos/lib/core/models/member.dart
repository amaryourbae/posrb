class Member {
  final String id;
  final String name;
  final String phone;
  final String? email;
  final int pointsBalance;
  final bool isBanned;
  final String? createdAt;

  Member({
    required this.id,
    required this.name,
    required this.phone,
    this.email,
    this.pointsBalance = 0,
    this.isBanned = false,
    this.createdAt,
  });

  factory Member.fromJson(Map<String, dynamic> json) {
    return Member(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      email: json['email'],
      pointsBalance: json['points_balance'] is String
          ? int.tryParse(json['points_balance']) ?? 0
          : json['points_balance'] ?? 0,
      isBanned: json['is_banned'] is int
          ? json['is_banned'] == 1
          : json['is_banned'] ?? false,
      createdAt: json['created_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {'name': name, 'phone': phone, 'email': email};
  }
}

class PaginatedMembers {
  final List<Member> data;
  final int currentPage;
  final int lastPage;
  final int total;

  PaginatedMembers({
    required this.data,
    required this.currentPage,
    required this.lastPage,
    required this.total,
  });

  factory PaginatedMembers.fromJson(Map<String, dynamic> json) {
    final dataList = json['data'] as List? ?? [];
    return PaginatedMembers(
      data: dataList.map((e) => Member.fromJson(e)).toList(),
      currentPage: json['current_page'] ?? 1,
      lastPage: json['last_page'] ?? 1,
      total: json['total'] ?? 0,
    );
  }
}
