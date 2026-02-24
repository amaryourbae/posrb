import 'dart:convert';

class Product {
  final String id;
  final String? categoryId;
  final String name;
  final double price;
  final String? imageUrl;
  final List<Modifier> modifiers;
  final bool? lowStock;
  final String? sku;
  final bool isAvailable;
  final double currentStock;
  final double minimumStockAlert;

  Product({
    required this.id,
    this.categoryId,
    required this.name,
    required this.price,
    this.imageUrl,
    this.modifiers = const [],
    this.lowStock,
    this.sku,
    this.isAvailable = true,
    this.currentStock = 0,
    this.minimumStockAlert = 0,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'].toString(),
      categoryId: json['category_id']?.toString(),
      name: json['name'],
      price: double.tryParse(json['price'].toString()) ?? 0.0,
      imageUrl: json['image_url'] ?? json['image'],
      lowStock: json['lowStock'],
      sku: json['sku'],
      isAvailable: json['is_available'] == 1 || json['is_available'] == true,
      currentStock: double.tryParse(json['current_stock'].toString()) ?? 0.0,
      minimumStockAlert:
          double.tryParse(json['minimum_stock_alert'].toString()) ?? 0.0,
      modifiers:
          (json['modifiers'] as List<dynamic>?)
              ?.map((e) => Modifier.fromJson(e))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'category_id': categoryId,
    'name': name,
    'price': price,
    'image_url': imageUrl,
    'lowStock': lowStock,
    'sku': sku,
    'is_available': isAvailable,
    'current_stock': currentStock,
    'minimum_stock_alert': minimumStockAlert,
    'modifiers': modifiers.map((m) => m.toJson()).toList(),
  };
}

class Modifier {
  final String id;
  final String name;
  final String type;
  final bool isRequired;
  final List<ModifierOption> options;
  final String? conditionModifierId;
  final String? conditionOptionId;
  final List<String>? allowedOptions;

  Modifier({
    required this.id,
    required this.name,
    required this.type,
    required this.isRequired,
    this.options = const [],
    this.conditionModifierId,
    this.conditionOptionId,
    this.allowedOptions,
  });

  factory Modifier.fromJson(Map<String, dynamic> json) {
    final pivot = json['pivot'];
    return Modifier(
      id: json['id'].toString(),
      name: json['name'],
      type: json['type'],
      isRequired: json['is_required'] == 1 || json['is_required'] == true,
      options:
          (json['options'] as List<dynamic>?)
              ?.map((e) => ModifierOption.fromJson(e))
              .toList() ??
          [],
      conditionModifierId: pivot?['condition_modifier_id']?.toString(),
      conditionOptionId: pivot?['condition_option_id']?.toString(),
      allowedOptions: _parseAllowedOptions(pivot?['allowed_options']),
    );
  }

  static List<String>? _parseAllowedOptions(dynamic value) {
    if (value == null) return null;
    if (value is List) return value.map((e) => e.toString()).toList();
    if (value is String) {
      if (value.isEmpty) return null;
      try {
        final decoded = jsonDecode(value);
        if (decoded is List) {
          return decoded.map((e) => e.toString()).toList();
        }
      } catch (_) {}
    }
    return null;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'type': type,
    'is_required': isRequired,
    'options': options.map((o) => o.toJson()).toList(),
    'pivot': {
      'condition_modifier_id': conditionModifierId,
      'condition_option_id': conditionOptionId,
      'allowed_options': allowedOptions,
    },
  };
}

class ModifierOption {
  final String id;
  final String name;
  final double price;

  ModifierOption({required this.id, required this.name, required this.price});

  factory ModifierOption.fromJson(Map<String, dynamic> json) {
    return ModifierOption(
      id: json['id'].toString(),
      name: json['name'],
      price: double.tryParse(json['price'].toString()) ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'price': price};
}
