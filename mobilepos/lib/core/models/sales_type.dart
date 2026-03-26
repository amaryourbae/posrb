class SalesType {
  final String id;
  final String name;
  final String slug;
  final bool isActive;
  final int sortOrder;

  SalesType({
    required this.id,
    required this.name,
    required this.slug,
    this.isActive = true,
    this.sortOrder = 0,
  });

  factory SalesType.fromJson(Map<String, dynamic> json) {
    return SalesType(
      id: json['id'].toString(),
      name: json['name'],
      slug: json['slug'],
      isActive: json['is_active'] == 1 || json['is_active'] == true,
      sortOrder: int.tryParse(json['sort_order'].toString()) ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'slug': slug,
    'is_active': isActive,
    'sort_order': sortOrder,
  };
}
